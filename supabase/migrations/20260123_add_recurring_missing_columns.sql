-- Add missing columns to recurring_transactions table in bexly schema

-- Add auto_create column (critical for sync)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS auto_create BOOLEAN DEFAULT false;

-- Add reminder columns (enable_reminder, reminder_days_before)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS enable_reminder BOOLEAN DEFAULT true;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS reminder_days_before INTEGER DEFAULT 3;

-- Add metadata columns (notes, vendor_name, icon_name, color_hex)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS notes TEXT;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS vendor_name TEXT;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS icon_name TEXT;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS color_hex TEXT;

-- Add tracking columns (last_charged_date, total_payments)
ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS last_charged_date TIMESTAMPTZ;

ALTER TABLE bexly.recurring_transactions
ADD COLUMN IF NOT EXISTS total_payments INTEGER DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN bexly.recurring_transactions.auto_create IS 'Whether to automatically create transactions when due';
COMMENT ON COLUMN bexly.recurring_transactions.enable_reminder IS 'Whether to enable payment reminders';
COMMENT ON COLUMN bexly.recurring_transactions.reminder_days_before IS 'Number of days before due date to send reminder';
COMMENT ON COLUMN bexly.recurring_transactions.vendor_name IS 'Vendor/service name (e.g., Netflix, Spotify)';
COMMENT ON COLUMN bexly.recurring_transactions.icon_name IS 'Icon name for display';
COMMENT ON COLUMN bexly.recurring_transactions.color_hex IS 'Color hex code for visual identification';
COMMENT ON COLUMN bexly.recurring_transactions.last_charged_date IS 'Last date when payment was processed';
COMMENT ON COLUMN bexly.recurring_transactions.total_payments IS 'Total number of payments made so far';
