-- Bot pending transactions: temporary store for awaiting user confirmation
-- Used by Telegram/Messenger bots to hold parsed transactions before user confirms

CREATE TABLE IF NOT EXISTS bexly.bot_pending_transactions (
  id TEXT PRIMARY KEY,                    -- short random ID (8 chars) used in callback_data
  user_id UUID NOT NULL,
  platform TEXT NOT NULL DEFAULT 'telegram', -- 'telegram' | 'messenger'
  chat_id BIGINT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
  amount NUMERIC NOT NULL,
  category_id TEXT NOT NULL,             -- cloud_id of category
  wallet_id TEXT NOT NULL,               -- cloud_id of wallet
  description TEXT,
  transaction_date TIMESTAMPTZ NOT NULL,
  language TEXT NOT NULL DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '10 minutes')
);

-- Auto-cleanup expired rows
CREATE INDEX IF NOT EXISTS idx_bot_pending_expires_at ON bexly.bot_pending_transactions (expires_at);

-- Grant service role access
GRANT ALL ON bexly.bot_pending_transactions TO service_role;
