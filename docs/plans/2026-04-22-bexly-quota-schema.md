# Bexly AI Quota Schema (DOS.AI Gateway)

> **Updated 2026-04-27**: aligned with DOS.AI gateway-jwt-auth spec v2 —
> anniversary-based reset (not calendar UTC), counter table keyed by
> `period_start_date DATE`, atomic `try_consume_quota` function instead of
> COUNT() race window. Migration: `supabase/migrations/20260427_add_bexly_quota_tables.sql`.

Spec for Bexly's per-product AI usage tracking + plan quota config in the
DOS.AI Gateway. Pairs with the Gateway's JWT-auth + product routing work
on the DOS.AI side.

## Scope

Bexly is one of several DOS products that share one billing plan but track
quota independently:

```
public.billing_accounts.plan        (shared: 'free' | 'go' | 'plus')
       │
       ├── bexly.usage_transactions  (THIS SPEC — per-request log)
       │   bexly.plan_quotas         (THIS SPEC — quota config)
       │
       ├── dosai.usage_transactions  (existing)
       │   dosai.plan_quotas         (DOS.AI team)
       │
       └── dosafe.usage_transactions (DOSafe team)
           dosafe.plan_quotas        (DOSafe team)
```

## Plan name mapping

| `billing_accounts.plan` | Bexly UI label | Notes |
|-------------------------|----------------|-------|
| `free`                  | Free           |       |
| `go`                    | Go             | $1.99/mo |
| `plus`                  | Premium        | $5/mo · maps to DOS.Me Plus |

The Bexly UI never shows "plus" to the user — it always renders as
"Premium". The string `plus` is the canonical value in
`billing_accounts.plan` and `bexly.plan_quotas.plan`.

## Schema

### `bexly.plan_quotas`

Configuration table. One row per `(plan, model_tier)` combo.

```sql
CREATE TABLE bexly.plan_quotas (
  plan          TEXT NOT NULL,         -- 'free' | 'go' | 'plus'
  model_tier    TEXT NOT NULL,         -- 'standard' (Bexly currently has 1 tier)
  monthly_limit INT  NOT NULL,         -- -1 = unlimited
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (plan, model_tier)
);

-- Bexly initial quotas (matches docs/PREMIUM_PLAN.md)
INSERT INTO bexly.plan_quotas (plan, model_tier, monthly_limit) VALUES
  ('free', 'standard',  60),
  ('go',   'standard', 240),
  ('plus', 'standard', 600);
```

Bexly currently exposes one model tier to the user (no model choice in UI).
Internally the gateway may route requests to different upstream models
based on cost/latency, but quota is counted against `'standard'` for now.
If Bexly later introduces premium-OCR or flagship features with separate
quotas, add new rows: `('plus', 'flagship', 100)` etc.

### `bexly.usage_transactions`

Per-request log. One row per AI call routed through the gateway with
`X-Product: bexly`.

```sql
CREATE TABLE bexly.usage_transactions (
  id                 BIGSERIAL PRIMARY KEY,
  user_id            UUID NOT NULL,
  api_key_id         UUID,                -- nullable; gateway-issued key id if any
  model              TEXT NOT NULL,       -- actual upstream model: 'dos-ai', 'qwen-7b', 'gemini-2.5-flash'
  model_tier         TEXT NOT NULL,       -- 'standard' for now
  endpoint           TEXT NOT NULL,       -- '/v1/chat/completions' / '/v1/messages' etc
  provider           TEXT,                -- 'dos-ai' / 'gemini' / 'openai' (for fallback tracking)
  input_tokens       INT,
  output_tokens      INT,
  input_cost_cents   NUMERIC(10, 6),
  output_cost_cents  NUMERIC(10, 6),
  total_cost_cents   NUMERIC(10, 6),
  latency_ms         INT,
  status_code        INT NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Quota check query path: (user_id, model_tier, created_at) range scan
CREATE INDEX idx_bexly_usage_user_tier_month
  ON bexly.usage_transactions (user_id, model_tier, created_at DESC);

-- Cost reporting / dashboards
CREATE INDEX idx_bexly_usage_created_at
  ON bexly.usage_transactions (created_at DESC);
```

## Gateway logic (v2 — anniversary reset, atomic counter)

```text
POST /v1/bexly/chat/completions      (URL path is product key, not header)
  Authorization: Bearer <supabase_jwt>

1. Verify JWT via Supabase JWKS → user_id
2. Route by URL path → product = 'bexly'
3. SELECT plan, current_period_start FROM public.billing_accounts WHERE user_id = ?
   - period_start_date = DATE(current_period_start)
   - if NULL (free user, no Stripe period): fall back to first-of-month UTC
4. count = SELECT bexly.try_consume_quota(user_id, 'standard', plan, period_start_date)
   - returns NULL if quota exceeded
   - returns new count otherwise (atomic increment via INSERT ... ON CONFLICT)
5. IF count IS NULL → 429 with X-RateLimit-* headers
   ELSE → forward upstream, then INSERT into bexly.usage_transactions
        (audit log; counter is the quota source of truth)
```

The atomic function avoids the race window where two concurrent requests
both observe `count = limit-1` and both pass.

## Response headers (gateway returns on every Bexly request)

```
X-RateLimit-Limit: 600          # current plan limit for this user/tier
X-RateLimit-Remaining: 547      # limit - used
X-RateLimit-Reset: 1714521600   # unix timestamp at start of next month
X-RateLimit-Tier: standard      # which model_tier this quota covers
```

Bexly client reads these on every response to update the in-app
"X / 600 messages this month" UI.

## Quota query endpoint (optional, batch read)

```
GET /v1/usage/quota?product=bexly
Authorization: Bearer <supabase_jwt>

Response:
{
  "product": "bexly",
  "plan": "plus",
  "tiers": [
    {
      "model_tier": "standard",
      "limit": 600,
      "used": 53,
      "remaining": 547,
      "reset_at": "2026-05-01T00:00:00Z"
    }
  ]
}
```

Bexly calls this on app start and after every settings/billing screen open
to refresh the quota display without making a real AI request.

## Row-Level Security (RLS)

Both tables hold per-user data. RLS policies:

```sql
ALTER TABLE bexly.usage_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.plan_quotas        ENABLE ROW LEVEL SECURITY;

-- Users can read their own usage
CREATE POLICY usage_self_read ON bexly.usage_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Only the gateway (service role) can insert
CREATE POLICY usage_service_insert ON bexly.usage_transactions
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- plan_quotas is public read (everyone can see the pricing tiers)
CREATE POLICY quota_public_read ON bexly.plan_quotas
  FOR SELECT USING (true);

-- Only Bexly admins (service role) can modify quotas
CREATE POLICY quota_service_write ON bexly.plan_quotas
  FOR ALL USING (auth.role() = 'service_role');
```

## Migration order

1. **DOS.AI team**: add `X-Product` routing + JWT middleware to gateway.
2. **Bexly team** (this spec): create `bexly` schema + 2 tables + RLS + insert quota rows.
3. **DOS.AI team**: deploy gateway with `bexly` product entry in routing config.
4. **Bexly client**: every AI call adds `X-Product: bexly` header. Read `X-RateLimit-*` from response, surface in UI.
5. **Drop legacy `BEXLY_FREE_AI_KEY` env var** after Bexly client cuts over.

## Open questions for DOS.AI team

1. **Service role for INSERT**: gateway will run as a Postgres role with
   `service_role`. Confirm this is the role gateway uses, or specify the
   actual role name to use in RLS policies.
2. **`api_key_id` column**: keep as nullable since Bexly client uses Supabase
   JWT (no per-user API key). OK to leave as `NULL` for Bexly rows?
3. **Reset behavior**: month boundary uses `date_trunc('month', NOW())` in
   server timezone. If gateway runs in UTC, all users get reset at same
   wall-clock time. Acceptable, or do we want per-user timezone reset?
   (Recommend UTC for simplicity.)
4. **Atomic increment**: high-traffic users could race the COUNT-then-INSERT.
   Worst case is a few extra messages over quota. Acceptable, or should we
   use a sequence-based counter or `SELECT ... FOR UPDATE`?
   (Recommend acceptable, document as soft cap.)
