-- Add missing columns to budgets table
-- wallet_id: Foreign key to wallets table
-- is_routine: Boolean flag for routine budgets

-- Add wallet_id column
ALTER TABLE bexly.budgets
  ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE;

-- Add is_routine column
ALTER TABLE bexly.budgets
  ADD COLUMN IF NOT EXISTS is_routine BOOLEAN NOT NULL DEFAULT false;

-- Create index for wallet_id for better performance
CREATE INDEX IF NOT EXISTS idx_budgets_wallet_id ON bexly.budgets(wallet_id);

-- IMPORTANT: After running this migration:
-- This migration adds wallet_id and is_routine columns to support Bexly app budget sync
