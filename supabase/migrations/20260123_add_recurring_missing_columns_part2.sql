-- Add remaining missing columns to recurring_transactions table in bexly schema
-- Part 2: Critical columns for sync functionality

-- Add billing_day column
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS billing_day INTEGER;

-- Add custom frequency columns
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS custom_interval INTEGER;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS custom_unit TEXT;

-- Add next_due_date column (CRITICAL for recurring logic)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS next_due_date TIMESTAMPTZ;

-- Add currency column
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS currency TEXT;

-- Add description column
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS description TEXT;

-- Add status column (to replace is_active boolean with richer enum)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Add comments for documentation
COMMENT ON COLUMN bexly.recurring_transactions.billing_day IS 'Day of month (1-31) for monthly/quarterly/yearly OR day of week (0-6) for weekly';
COMMENT ON COLUMN bexly.recurring_transactions.custom_interval IS 'Custom interval number (e.g., 3 for every 3 months)';
COMMENT ON COLUMN bexly.recurring_transactions.custom_unit IS 'Custom interval unit: days, weeks, months, years';
COMMENT ON COLUMN bexly.recurring_transactions.next_due_date IS 'Next payment due date - CRITICAL for recurring charge logic';
COMMENT ON COLUMN bexly.recurring_transactions.currency IS 'Currency code (ISO 4217, e.g., USD, VND, EUR)';
COMMENT ON COLUMN bexly.recurring_transactions.description IS 'Optional description or notes';
COMMENT ON COLUMN bexly.recurring_transactions.status IS 'Status: active, paused, cancelled, expired';
