# Tingee Open Banking Integration

> Status: Planning · Owner: Bexly team · Target: Q2-Q3 2026

## Context

Vietnam's Thông tư 64/2024 mandates Open Banking APIs at all VN banks by
2027-03-01, but the rollout is uneven. Rather than waiting and integrating
each bank one by one, Bexly will integrate **Tingee** as an aggregator —
the Vietnamese equivalent of Plaid.

[Tingee](https://developers.tingee.vn) provides a unified BaaS API across
Vietnamese banks with three product lines: bank account linking + real-time
transaction notifications (via webhooks), QR/Pay-by-Bank payments, and
direct debit. We have partner credentials.

## Why this matters

The single biggest UX improvement Bexly can make is killing manual
transaction entry. Today users have three options, all imperfect:

| Method | Friction | Coverage | Privacy |
|--------|----------|----------|---------|
| Manual entry | High (per-transaction) | 100% | Best |
| SMS parsing | Low (Android only) | Limited (banks send fewer SMS now) | OK |
| Notification listener | Low (Android only) | Decent for e-wallets | OK |
| Receipt OCR | Medium | 100% but post-hoc | Best |
| **Tingee Open Banking** | **Zero (after link)** | **All linked banks** | **User-consented** |

Open Banking is the only path to "transactions appear automatically, no
phone manipulation, works on iOS too."

## Authentication (Tingee → Bexly server)

Tingee uses HMAC-SHA512 with a partner-issued client ID + secret:

```
Headers:
  x-client-id:        <issued by Tingee>
  x-request-timestamp: <unix seconds, UTC+7, must be within 10 minutes of server>
  x-signature:        HMAC_SHA512(timestamp + ':' + requestBody, secretToken)
  Content-Type:       application/json
```

The secret token MUST live only in the Supabase Edge Function's secret
store. Never ship to the Bexly client.

## Architecture

```
┌─────────────────┐                    ┌──────────────────────┐
│  Bexly Flutter  │  link account flow │   Tingee Web/App     │
│     client      │ ─────────────────> │  (user authorizes)   │
└────────┬────────┘                    └───────────┬──────────┘
         │                                         │
         │ Realtime subscribe                      │ Webhook POST
         │ to bexly.tingee_transactions            │ (HMAC-signed)
         ▼                                         ▼
┌─────────────────────────────────────────────────────────────┐
│            Supabase                                          │
│  ┌────────────────────────┐    ┌────────────────────────┐  │
│  │ Edge Function:         │    │ Tables (schema bexly): │  │
│  │   tingee-webhook       │ ─> │   linked_bank_accounts │  │
│  │   - verify HMAC        │    │   tingee_transactions  │  │
│  │   - persist row        │    │   parsed_transactions  │  │
│  │   - notify Realtime    │    │     (existing)         │  │
│  └────────────────────────┘    └────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Phases

### Phase A — Read-only MVP (~3 weeks)

The minimum that delivers value: link a bank account, get real-time
transaction notifications, surface them in Bexly's existing
`pending_transactions` queue for user confirmation.

**Backend (Supabase):**

```sql
-- Linked accounts (user opts in per account)
CREATE TABLE bexly.linked_bank_accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  tingee_account_id TEXT NOT NULL,        -- Tingee's identifier
  bank_code       TEXT NOT NULL,          -- VCB, BIDV, MBB, etc.
  account_number_masked TEXT NOT NULL,    -- *****1234 — never store full number
  label           TEXT,                   -- user-set: "Salary", "Family"
  default_wallet_id INT,                  -- which Bexly wallet to assign tx to
  status          TEXT NOT NULL DEFAULT 'active',
                  -- 'active' | 'unlinked' | 'expired'
  linked_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlinked_at     TIMESTAMPTZ,
  UNIQUE (user_id, tingee_account_id)
);

-- Raw webhook log + processing state
CREATE TABLE bexly.tingee_transactions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id),
  linked_account_id     UUID REFERENCES bexly.linked_bank_accounts(id),
  tingee_transaction_id TEXT NOT NULL,    -- idempotency key from Tingee
  raw_payload           JSONB NOT NULL,
  amount                BIGINT,           -- VND in dong (no fractional)
  direction             TEXT,             -- 'in' | 'out'
  occurred_at           TIMESTAMPTZ,
  processed_at          TIMESTAMPTZ,
  bexly_transaction_id  INT,              -- once user confirms
  received_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tingee_transaction_id)
);

CREATE INDEX idx_tingee_tx_user_unprocessed
  ON bexly.tingee_transactions (user_id, received_at DESC)
  WHERE processed_at IS NULL;
```

RLS: users see only their own rows; only service role inserts.

**Edge Function (`supabase/functions/tingee-webhook`):**

```typescript
// Verify Tingee HMAC, persist, push to Realtime
1. Validate x-request-timestamp within ±10 min
2. Recompute HMAC_SHA512(timestamp + ':' + body, TINGEE_SECRET)
3. Compare with x-signature in constant time
4. Parse body — extract tingee_account_id, transaction_id, amount, direction
5. Upsert by tingee_transaction_id (idempotent — Tingee retries on 5xx)
6. INSERT into tingee_transactions with raw_payload preserved
7. Return 200 fast (Tingee retry policy is unforgiving)
```

**Flutter client:**

- Settings → "Linked Bank Accounts" screen
- "Link a bank" → opens Tingee's web link flow (or in-app webview), returns
  deep link `bexly://tingee/linked?account_id=...`
- New screen `LinkedAccountsScreen` lists `linked_bank_accounts` rows
- Existing `PendingTransactionsScreen` already shows unprocessed items —
  Tingee transactions land there as a new source alongside SMS + email
- Subscribe to Supabase Realtime `bexly.tingee_transactions` filtered by
  user_id where `processed_at IS NULL`
- When a row arrives, run existing AI categorization pipeline → user taps
  "Confirm" (or auto-confirm if user has set "auto-import from this account")

**Out of scope for Phase A:**

- Initiating payments (only receiving notifications)
- Historical backfill (only new transactions from link time forward)
- Direct debit
- QR generation

### Phase B — Pay-by-Bank for recurring (~2 weeks, after Phase A stable)

User clicks "Pay" on a recurring bill or budget item. Bexly server calls
Tingee to generate a VietQR or deep link. User completes in their banking
app. Tingee webhook confirms. Bexly marks the recurring as paid for the
period.

Adds to `tingee_payments` table. Reuses existing `recurrings` table — just
adds a `last_payment_method = 'tingee_pay_by_bank'` field.

### Phase C — Direct Debit (~3 weeks, after Phase B)

Highest trust tier. User authorizes once during account link, then Bexly
can trigger automatic charges for recurring bills. Requires:

- Explicit consent UI with clear amount caps and frequency limits
- Matching VN compliance rules for recurring authorization
- Hard limit per transaction + monthly cap, surfaced in UI
- Easy revoke from account screen

This phase requires legal review before launch.

## Privacy and security

- **Account number**: store only last-4 masked. Full number never leaves
  Tingee's vault. Bexly references accounts by Tingee's `tingee_account_id`.
- **HMAC secret**: in Supabase Edge Function secrets, rotated quarterly.
- **Bexly client never talks to Tingee directly** for any operation that
  needs the secret. The link flow is the one exception (it's a public
  redirect URL).
- **Unlink immediately revokes**: deleting a `linked_bank_accounts` row
  also calls Tingee's revoke endpoint and stops accepting webhooks.
- **Audit trail**: `tingee_transactions.raw_payload` retained for 90 days
  for debugging, then anonymized.

## Tier gating (matches `docs/PREMIUM_PLAN.md`)

| Tier | Linked accounts | Auto-import | Pay-by-Bank | Direct Debit |
|------|-----------------|-------------|-------------|--------------|
| Free | 1 | manual confirm | ❌ | ❌ |
| Go | 3 | manual or auto | ✅ | ❌ |
| Premium | unlimited | auto-import | ✅ | ✅ |

Adds two new fields to `SubscriptionLimits`: `maxLinkedBankAccounts`,
`allowDirectDebit`. Update `subscription_tier.dart` accordingly.

## Endpoint reference (from Tingee docs)

| Path | Method | Purpose |
|------|--------|---------|
| `/v1/get-banks` | GET | List supported VN banks (used to populate link UI dropdown) |
| `/v1/get-va-paging` | GET | List user's virtual accounts (paginated) |
| `/v1/create-va` | POST | Create / link a virtual account |
| `/v1/confirm-va` | POST | Confirm VA details |
| `/v1/register-notify` | POST | Subscribe to webhook for an account |
| `/v1/confirm-register-notify` | POST | Confirm webhook registration |
| `/v1/delete-va` | DELETE | Unlink VA |
| `/v1/confirm-delete-va` | POST | Confirm VA deletion |
| `/v1/transaction/get-paging` | GET | Historical transactions (paginated) |
| `/v1/refund` | POST | Refund a transaction |

## Webhook reliability (from Tingee docs)

- Retry: max 5 lần nếu server phản hồi lỗi hoặc timeout (interval/delay
  không nói rõ trong doc; cần test thực tế hoặc hỏi Tingee).
- Idempotency: dùng transaction code làm dedupe key. Bexly's
  `tingee_transaction_id` UNIQUE constraint sẽ no-op các retry trùng.
- Signature verification format: `HMAC_SHA512(timestamp + ':' + JSON.stringify(body), secretToken)`.

Vì Tingee chỉ retry 5 lần, Edge Function phải đảm bảo respond 200 nhanh
(tách validate → enqueue → return; xử lý nặng làm async). Nếu sau 5 lần
vẫn fail, dùng `/v1/transaction/get-paging` để poll bù lúc client kết
nối lại — backup mechanism này giải quyết edge case Tingee bỏ cuộc.

## Open questions

1. **Sandbox flow**: cần credentials riêng cho dev vs prod không? Xác
   nhận trước khi bắt đầu Phase A để CI staging chạy được.

(Pricing không phải vấn đề — Tingee là đối tác.)

## Success metrics

- Phase A: 200+ users link an account in first month after launch.
- Auto-import accuracy: 90%+ of linked-account transactions get correctly
  categorized by AI on first try.
- Time-to-categorized: median 5 seconds from bank push → Bexly
  notification.
- Phase B: 30% of recurring bills paid via in-app Pay-by-Bank within 90
  days of feature launch.
