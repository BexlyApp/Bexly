-- Tingee Open Banking integration — Phase A (read-only).
-- See docs/plans/2026-04-27-tingee-open-banking.md for the full design.
--
-- Two tables:
--   bexly.linked_bank_accounts — one row per VA (virtual account) the user has
--                                authorised with Tingee.
--   bexly.tingee_transactions  — raw webhook log (one row per
--                                Tingee notification, idempotent on
--                                tingee_transaction_id).

-- =============================================================================
-- Linked accounts
-- =============================================================================

CREATE TABLE IF NOT EXISTS bexly.linked_bank_accounts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tingee_account_id     TEXT NOT NULL,            -- Tingee's identifier for the VA
  bank_code             TEXT NOT NULL,            -- VCB, BIDV, MBB, ACB, ...
  account_number_masked TEXT NOT NULL,            -- '*****1234' — full number stays at Tingee
  label                 TEXT,                     -- user-set: "Salary", "Family"
  default_wallet_id     INT,                      -- which Bexly wallet to assign tx to (FK is logical, drift table)
  status                TEXT NOT NULL DEFAULT 'active',
                        -- 'active' | 'unlinked' | 'expired'
  linked_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlinked_at           TIMESTAMPTZ,
  UNIQUE (user_id, tingee_account_id)
);

CREATE INDEX IF NOT EXISTS idx_linked_bank_accounts_user_status
  ON bexly.linked_bank_accounts (user_id, status);

ALTER TABLE bexly.linked_bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY linked_accounts_self_read
  ON bexly.linked_bank_accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY linked_accounts_self_update_label
  ON bexly.linked_bank_accounts
  FOR UPDATE USING (auth.uid() = user_id);

-- Inserts/deletes go through the Edge Function (service role) only — clients
-- can't create or remove links directly because the Tingee link/unlink flow
-- requires server-side calls signed with the Tingee secret.
CREATE POLICY linked_accounts_service_write
  ON bexly.linked_bank_accounts
  FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- Webhook log (one row per Tingee notification)
-- =============================================================================

CREATE TABLE IF NOT EXISTS bexly.tingee_transactions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  linked_account_id     UUID REFERENCES bexly.linked_bank_accounts(id) ON DELETE SET NULL,
  tingee_transaction_id TEXT NOT NULL,            -- Tingee's transactionCode field — idempotency key
  raw_payload           JSONB NOT NULL,           -- full Tingee webhook body (preserved for debug)
  amount                BIGINT,                   -- VND, no fractional
  direction             TEXT,                     -- 'in' | 'out'
  bank_code             TEXT,
  account_number        TEXT,                     -- masked — accountNumber from payload
  description           TEXT,                     -- content field from payload
  occurred_at           TIMESTAMPTZ,
  processed_at          TIMESTAMPTZ,              -- set when user confirms / auto-import creates Bexly tx
  bexly_transaction_id  INT,                      -- local Drift transaction id once processed
  received_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tingee_transaction_id)
);

CREATE INDEX IF NOT EXISTS idx_tingee_tx_user_unprocessed
  ON bexly.tingee_transactions (user_id, received_at DESC)
  WHERE processed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tingee_tx_linked_account
  ON bexly.tingee_transactions (linked_account_id, received_at DESC);

ALTER TABLE bexly.tingee_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY tingee_tx_self_read
  ON bexly.tingee_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Users can mark their own rows as processed (set processed_at,
-- bexly_transaction_id) once they confirm a transaction in the app.
CREATE POLICY tingee_tx_self_update
  ON bexly.tingee_transactions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY tingee_tx_service_insert
  ON bexly.tingee_transactions
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- Realtime publication so Bexly client can subscribe to new webhook rows
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE bexly.tingee_transactions;
