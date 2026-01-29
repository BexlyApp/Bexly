-- Add missing credit_limit column to wallets table
ALTER TABLE bexly.wallets ADD COLUMN IF NOT EXISTS credit_limit NUMERIC(20, 2);
