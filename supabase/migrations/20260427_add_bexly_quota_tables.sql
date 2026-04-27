-- Bexly AI quota tables consumed by the DOS.AI Gateway when X-Product=bexly.
-- See docs/plans/2026-04-22-bexly-quota-schema.md and the DOS.AI gateway-jwt-auth
-- spec v2 (anniversary reset). Counter is keyed by period_start_date so it
-- aligns with `public.billing_accounts.current_period_start` once that exists.

-- =============================================================================
-- bexly.plan_quotas — config: how many messages each (plan, tier) gets per period
-- =============================================================================

CREATE TABLE IF NOT EXISTS bexly.plan_quotas (
  plan          TEXT NOT NULL,    -- 'free' | 'go' | 'plus' (matches billing_accounts.plan)
  model_tier    TEXT NOT NULL,    -- 'standard' (Bexly currently exposes one tier)
  monthly_limit INT  NOT NULL,    -- -1 = unlimited
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (plan, model_tier)
);

ALTER TABLE bexly.plan_quotas ENABLE ROW LEVEL SECURITY;

CREATE POLICY plan_quotas_public_read
  ON bexly.plan_quotas
  FOR SELECT USING (true);

CREATE POLICY plan_quotas_service_write
  ON bexly.plan_quotas
  FOR ALL USING (auth.role() = 'service_role');

-- Initial values match docs/PREMIUM_PLAN.md
INSERT INTO bexly.plan_quotas (plan, model_tier, monthly_limit) VALUES
  ('free', 'standard',  60),
  ('go',   'standard', 240),
  ('plus', 'standard', 600)
ON CONFLICT (plan, model_tier) DO NOTHING;

-- =============================================================================
-- bexly.usage_counters — atomic counter, one row per (user, tier, period)
-- =============================================================================
-- Gateway increments via INSERT ... ON CONFLICT DO UPDATE so quota check is
-- a single PK lookup instead of a COUNT() over usage_transactions.
--
-- period_start_date is the first day of the user's current billing period. For
-- DOS.Me Plus subscribers this is `DATE(billing_accounts.current_period_start)`.
-- For free users (no Stripe period) the gateway falls back to first-day-of-month
-- in UTC so reset still happens predictably.

CREATE TABLE IF NOT EXISTS bexly.usage_counters (
  user_id            UUID NOT NULL,
  model_tier         TEXT NOT NULL,    -- 'standard'
  period_start_date  DATE NOT NULL,    -- billing anniversary or month start
  count              INT  NOT NULL DEFAULT 0,
  last_request_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, model_tier, period_start_date)
);

CREATE INDEX IF NOT EXISTS idx_usage_counters_user_tier_recent
  ON bexly.usage_counters (user_id, model_tier, period_start_date DESC);

ALTER TABLE bexly.usage_counters ENABLE ROW LEVEL SECURITY;

-- Users can read only their own counters (for "X / 600 messages this period" UI)
CREATE POLICY usage_counters_self_read
  ON bexly.usage_counters
  FOR SELECT USING (auth.uid() = user_id);

-- Only the gateway service role mutates
CREATE POLICY usage_counters_service_write
  ON bexly.usage_counters
  FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- bexly.usage_transactions — audit log, one row per AI request
-- =============================================================================
-- Counters above are the source of truth for quota. This table is the audit
-- log for cost reporting + dispute resolution. Gateway writes both atomically
-- in the same transaction.

CREATE TABLE IF NOT EXISTS bexly.usage_transactions (
  id                 BIGSERIAL PRIMARY KEY,
  user_id            UUID        NOT NULL,
  api_key_id         UUID,                     -- nullable; null when client uses Supabase JWT
  period_start_date  DATE        NOT NULL,     -- which counter row this hit went against
  model              TEXT        NOT NULL,     -- upstream model name: 'dos-ai', 'qwen-7b', 'gemini-2.5-flash'
  model_tier         TEXT        NOT NULL,     -- 'standard'
  endpoint           TEXT        NOT NULL,     -- '/v1/chat/completions'
  provider           TEXT,                     -- 'dos-ai' | 'gemini' | 'openai' (fallback tracking)
  input_tokens       INT,
  output_tokens      INT,
  input_cost_cents   NUMERIC(10, 6),
  output_cost_cents  NUMERIC(10, 6),
  total_cost_cents   NUMERIC(10, 6),
  latency_ms         INT,
  status_code        INT         NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usage_tx_user_period
  ON bexly.usage_transactions (user_id, period_start_date, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_usage_tx_created_at
  ON bexly.usage_transactions (created_at DESC);

ALTER TABLE bexly.usage_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY usage_tx_self_read
  ON bexly.usage_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY usage_tx_service_write
  ON bexly.usage_transactions
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- Atomic quota check + increment — used by gateway middleware
-- =============================================================================
-- Returns the new count if under limit, or NULL if quota exceeded.
-- Gateway flow:
--   1. SELECT plan FROM public.billing_accounts WHERE user_id = ?
--   2. SELECT current_period_start FROM public.billing_accounts (or fallback)
--   3. SELECT bexly.try_consume_quota(user_id, tier, plan, period_start_date)
--      - if NULL → return 429
--      - else → forward upstream, then INSERT into usage_transactions

CREATE OR REPLACE FUNCTION bexly.try_consume_quota(
  p_user_id            UUID,
  p_model_tier         TEXT,
  p_plan               TEXT,
  p_period_start_date  DATE
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit  INT;
  v_count  INT;
BEGIN
  -- Look up quota for plan+tier; default to free tier if missing.
  SELECT monthly_limit INTO v_limit
  FROM bexly.plan_quotas
  WHERE plan = p_plan AND model_tier = p_model_tier;

  IF v_limit IS NULL THEN
    SELECT monthly_limit INTO v_limit
    FROM bexly.plan_quotas
    WHERE plan = 'free' AND model_tier = p_model_tier;
  END IF;

  IF v_limit IS NULL THEN
    -- No row even for free tier. Conservatively block.
    RETURN NULL;
  END IF;

  -- Atomic increment — if under limit, return new count; else block.
  INSERT INTO bexly.usage_counters (user_id, model_tier, period_start_date, count, last_request_at)
  VALUES (p_user_id, p_model_tier, p_period_start_date, 1, NOW())
  ON CONFLICT (user_id, model_tier, period_start_date)
  DO UPDATE SET
    count = CASE
              WHEN v_limit = -1 OR bexly.usage_counters.count < v_limit
                THEN bexly.usage_counters.count + 1
              ELSE bexly.usage_counters.count
            END,
    last_request_at = CASE
                        WHEN v_limit = -1 OR bexly.usage_counters.count < v_limit
                          THEN NOW()
                        ELSE bexly.usage_counters.last_request_at
                      END
  RETURNING count INTO v_count;

  -- If count didn't move (already at limit), signal quota exceeded.
  IF v_limit != -1 AND v_count > v_limit THEN
    RETURN NULL;
  END IF;

  RETURN v_count;
END;
$$;

-- Only the gateway (service role) can call this
REVOKE EXECUTE ON FUNCTION bexly.try_consume_quota FROM PUBLIC;
GRANT EXECUTE ON FUNCTION bexly.try_consume_quota TO service_role;
