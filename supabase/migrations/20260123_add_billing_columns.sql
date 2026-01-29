-- Add missing billing_day column to recurring_transactions
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS billing_day INTEGER;

-- Also add missing core columns if they don't exist
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS custom_interval INTEGER;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS custom_unit TEXT;

-- Add comments
COMMENT ON COLUMN bexly.recurring_transactions.billing_day IS 'Day of month for billing (1-31) for monthly/quarterly/yearly OR day of week (0-6) for weekly recurring payments';
COMMENT ON COLUMN bexly.recurring_transactions.custom_interval IS 'Custom interval number (e.g., 3 for "every 3 months") - only used when frequency is custom';
COMMENT ON COLUMN bexly.recurring_transactions.custom_unit IS 'Custom interval unit (days, weeks, months, years) - only used when frequency is custom';
