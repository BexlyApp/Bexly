# Bexly Schema Migration to DOS-Me Supabase

## Overview

This document contains SQL migration scripts to create the **Bexly schema** in the DOS-Me Supabase project. Bexly will share the same Supabase project as DOS-Me, DOS.AI, and MetaDOS using schema-based isolation.

---

## Architecture

```
DOS-Me Supabase Project
├── public (shared)
│   ├── users (auth.users reference)
│   ├── wallets (Openfort - shared)
│   └── bank_accounts (Stripe - shared)
│
└── bexly (Bexly-specific)
    ├── transactions
    ├── budgets
    ├── categories
    ├── goals
    ├── recurring_transactions
    ├── chat_messages
    └── parsed_email_transactions
```

---

## Prerequisites

- ✅ DOS-Me Supabase project already has `public.users` table
- ✅ DOS-Me Supabase project already has `public.wallets` table (Openfort)
- ✅ DOS-Me Supabase project already has `public.bank_accounts` table (Stripe)
- ✅ Run this migration with Postgres superuser or owner role

---

## Migration SQL

### Step 1: Create Bexly Schema

```sql
-- Create bexly schema
CREATE SCHEMA IF NOT EXISTS bexly;

COMMENT ON SCHEMA bexly IS 'Bexly personal finance app - budgets, transactions, goals';

-- Grant permissions
GRANT USAGE ON SCHEMA bexly TO authenticated;
GRANT ALL ON SCHEMA bexly TO postgres;
```

---

### Step 2: Create Tables

#### 2.1 Transactions Table

```sql
CREATE TABLE IF NOT EXISTS bexly.transactions (
  cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES public.wallets(id) ON DELETE SET NULL,
  bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE SET NULL,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  note TEXT,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense', 'transfer')),
  transaction_date TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN DEFAULT FALSE NOT NULL,
  recurring_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT valid_amount CHECK (amount != 0)
);

COMMENT ON TABLE bexly.transactions IS 'User financial transactions (income, expense, transfer)';
COMMENT ON COLUMN bexly.transactions.wallet_id IS 'Reference to Openfort wallet (public.wallets)';
COMMENT ON COLUMN bexly.transactions.bank_account_id IS 'Reference to Stripe bank account (public.bank_accounts)';
COMMENT ON COLUMN bexly.transactions.recurring_id IS 'Reference to recurring_transactions if this is a recurring instance';
COMMENT ON COLUMN bexly.transactions.deleted_at IS 'Soft delete timestamp';

-- Indexes
CREATE INDEX idx_bexly_transactions_user_date
  ON bexly.transactions(user_id, transaction_date DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_bexly_transactions_wallet
  ON bexly.transactions(wallet_id)
  WHERE deleted_at IS NULL AND wallet_id IS NOT NULL;

CREATE INDEX idx_bexly_transactions_bank_account
  ON bexly.transactions(bank_account_id)
  WHERE deleted_at IS NULL AND bank_account_id IS NOT NULL;

CREATE INDEX idx_bexly_transactions_category
  ON bexly.transactions(user_id, category)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_bexly_transactions_type
  ON bexly.transactions(user_id, transaction_type)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_bexly_transactions_recurring
  ON bexly.transactions(recurring_id)
  WHERE recurring_id IS NOT NULL;
```

---

#### 2.2 Categories Table

```sql
CREATE TABLE IF NOT EXISTS bexly.categories (
  cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_user_category UNIQUE(user_id, name, type)
);

COMMENT ON TABLE bexly.categories IS 'User-defined transaction categories';

-- Indexes
CREATE INDEX idx_bexly_categories_user_type
  ON bexly.categories(user_id, type);
```

---

#### 2.3 Budgets Table

```sql
CREATE TABLE IF NOT EXISTS bexly.budgets (
  cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT valid_budget_amount CHECK (amount > 0),
  CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE bexly.budgets IS 'User spending budgets per wallet/category';

-- Indexes
CREATE INDEX idx_bexly_budgets_user
  ON bexly.budgets(user_id);

CREATE INDEX idx_bexly_budgets_wallet
  ON bexly.budgets(wallet_id);

CREATE INDEX idx_bexly_budgets_active
  ON bexly.budgets(user_id)
  WHERE end_date IS NULL OR end_date >= CURRENT_DATE;
```

---

#### 2.4 Goals Table

```sql
CREATE TABLE IF NOT EXISTS bexly.goals (
  cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_amount DECIMAL(20, 2) NOT NULL,
  current_amount DECIMAL(20, 2) DEFAULT 0 NOT NULL,
  deadline DATE,
  is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT valid_target_amount CHECK (target_amount > 0),
  CONSTRAINT valid_current_amount CHECK (current_amount >= 0)
);

COMMENT ON TABLE bexly.goals IS 'User savings goals';

-- Indexes
CREATE INDEX idx_bexly_goals_user
  ON bexly.goals(user_id);

CREATE INDEX idx_bexly_goals_wallet
  ON bexly.goals(wallet_id);

CREATE INDEX idx_bexly_goals_pinned
  ON bexly.goals(user_id, is_pinned)
  WHERE is_pinned = TRUE;
```

---

#### 2.5 Recurring Transactions Table

```sql
CREATE TABLE IF NOT EXISTS bexly.recurring_transactions (
  cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  note TEXT,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  next_occurrence DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT valid_recurring_amount CHECK (amount != 0),
  CONSTRAINT valid_recurring_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE bexly.recurring_transactions IS 'Recurring transaction templates (subscriptions, salary, etc.)';

-- Indexes
CREATE INDEX idx_bexly_recurring_user
  ON bexly.recurring_transactions(user_id);

CREATE INDEX idx_bexly_recurring_active
  ON bexly.recurring_transactions(user_id, is_active)
  WHERE is_active = TRUE;

CREATE INDEX idx_bexly_recurring_next_occurrence
  ON bexly.recurring_transactions(next_occurrence)
  WHERE is_active = TRUE;
```

---

#### 2.6 Chat Messages Table

```sql
CREATE TABLE IF NOT EXISTS bexly.chat_messages (
  message_id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_from_user BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  error TEXT,
  is_typing BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE bexly.chat_messages IS 'AI chat assistant conversation messages';

-- Indexes
CREATE INDEX idx_bexly_chat_user_time
  ON bexly.chat_messages(user_id, timestamp DESC);
```

---

#### 2.7 Parsed Email Transactions Table

```sql
CREATE TABLE IF NOT EXISTS bexly.parsed_email_transactions (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gmail_message_id TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  amount DECIMAL(20, 2) NOT NULL,
  currency TEXT NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  merchant TEXT,
  transaction_date TIMESTAMPTZ NOT NULL,
  confidence DECIMAL(3, 2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  raw_subject TEXT,
  raw_body TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_gmail_message UNIQUE(user_id, gmail_message_id),
  CONSTRAINT valid_confidence CHECK (confidence >= 0 AND confidence <= 1),
  CONSTRAINT valid_currency_length CHECK (length(currency) = 3)
);

COMMENT ON TABLE bexly.parsed_email_transactions IS 'Transactions parsed from Gmail banking emails (pending review)';

-- Indexes
CREATE INDEX idx_bexly_parsed_emails_user_status
  ON bexly.parsed_email_transactions(user_id, status);

CREATE INDEX idx_bexly_parsed_emails_pending
  ON bexly.parsed_email_transactions(user_id)
  WHERE status = 'pending';
```

---

### Step 3: Create Triggers (Updated_at)

```sql
-- Create trigger function (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column() IS 'Auto-update updated_at column on row update';

-- Apply triggers to Bexly tables
CREATE TRIGGER update_bexly_transactions_updated_at
  BEFORE UPDATE ON bexly.transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bexly_categories_updated_at
  BEFORE UPDATE ON bexly.categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bexly_budgets_updated_at
  BEFORE UPDATE ON bexly.budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bexly_goals_updated_at
  BEFORE UPDATE ON bexly.goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bexly_recurring_updated_at
  BEFORE UPDATE ON bexly.recurring_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

### Step 4: Row Level Security (RLS) Policies

```sql
-- Enable RLS on all Bexly tables
ALTER TABLE bexly.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.parsed_email_transactions ENABLE ROW LEVEL SECURITY;

-- Transactions policies
CREATE POLICY "Users can view own transactions"
  ON bexly.transactions FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert own transactions"
  ON bexly.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON bexly.transactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON bexly.transactions FOR DELETE
  USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Users can manage own categories"
  ON bexly.categories FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Budgets policies
CREATE POLICY "Users can manage own budgets"
  ON bexly.budgets FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Goals policies
CREATE POLICY "Users can manage own goals"
  ON bexly.goals FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Recurring transactions policies
CREATE POLICY "Users can manage own recurring transactions"
  ON bexly.recurring_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Chat messages policies
CREATE POLICY "Users can manage own chat messages"
  ON bexly.chat_messages FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Parsed email transactions policies
CREATE POLICY "Users can manage own parsed emails"
  ON bexly.parsed_email_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

### Step 5: Grant Permissions

```sql
-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bexly TO authenticated;

-- Grant sequence usage for serial columns
GRANT USAGE, SELECT ON SEQUENCE bexly.parsed_email_transactions_id_seq TO authenticated;

-- Default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
```

---

### Step 6: Enable Realtime (Optional)

```sql
-- Enable realtime for key tables (if needed)
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.parsed_email_transactions;
```

---

## Storage Buckets

Create a single storage bucket for all Bexly files with folder-based organization:

### Bexly Storage Structure

**Bucket Name:** `bexly`
**Public:** No (private - use signed URLs)
**Max File Size:** 10 MB
**Allowed MIME Types:** `image/*`, `application/pdf`, `text/csv`, `application/json`

**Folder Structure:**
```
bexly/
├── avatars/{user_id}/avatar.jpg
├── receipts/{user_id}/{transaction_id}_receipt.jpg
└── exports/{user_id}/bexly_export_2026-01-09.csv
```

### Bucket Policies (SQL)

```sql
-- Enable RLS for storage
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can upload to their own folder
CREATE POLICY "Users can upload to own Bexly folder"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'bexly'
  AND auth.uid()::text = (storage.foldername(name))[2]
  -- Path format: avatars/{user_id}/file.jpg
  --               [1]      [2]
);

-- Policy 2: Users can read own files
CREATE POLICY "Users can read own Bexly files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'bexly'
  AND auth.uid()::text = (storage.foldername(name))[2]
);

-- Policy 3: Users can update own files
CREATE POLICY "Users can update own Bexly files"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'bexly'
  AND auth.uid()::text = (storage.foldername(name))[2]
)
WITH CHECK (
  bucket_id = 'bexly'
  AND auth.uid()::text = (storage.foldername(name))[2]
);

-- Policy 4: Users can delete own files
CREATE POLICY "Users can delete own Bexly files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'bexly'
  AND auth.uid()::text = (storage.foldername(name))[2]
);
```

### Creating the Bucket (Supabase Dashboard)

1. Go to **Storage** → **Create a new bucket**
2. Settings:
   - **Name:** `bexly`
   - **Public:** `false` (private bucket)
   - **File size limit:** `10485760` bytes (10 MB)
   - **Allowed MIME types:** Leave empty to allow all types above
3. Click **Create bucket**
4. Run the SQL policies above in **SQL Editor**

---

## Edge Functions (Optional)

If you want to deploy Bexly Edge Functions to DOS-Me Supabase:

### Functions to create:

```bash
# In DOS-Me Supabase project
supabase functions new bexly-process-receipt
supabase functions new bexly-recurring-processor
supabase functions new bexly-export-csv
```

---

## Verification

After running the migration, verify:

```sql
-- Check schema exists
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'bexly';

-- Check tables created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'bexly';

-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'bexly';

-- Check policies created
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'bexly';

-- Check indexes created
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'bexly';

-- Check storage bucket created
SELECT id, name, public
FROM storage.buckets
WHERE id = 'bexly';

-- Check storage policies
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%Bexly%';
```

---

## Rollback (If Needed)

```sql
-- Drop all Bexly tables (CASCADE removes dependencies)
DROP TABLE IF EXISTS bexly.parsed_email_transactions CASCADE;
DROP TABLE IF EXISTS bexly.chat_messages CASCADE;
DROP TABLE IF EXISTS bexly.recurring_transactions CASCADE;
DROP TABLE IF EXISTS bexly.goals CASCADE;
DROP TABLE IF EXISTS bexly.budgets CASCADE;
DROP TABLE IF EXISTS bexly.categories CASCADE;
DROP TABLE IF EXISTS bexly.transactions CASCADE;

-- Drop schema
DROP SCHEMA IF EXISTS bexly CASCADE;

-- Drop storage policies
DROP POLICY IF EXISTS "Users can upload to own Bexly folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own Bexly files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own Bexly files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own Bexly files" ON storage.objects;

-- Delete storage bucket (do this in Supabase Dashboard → Storage → bexly → Settings → Delete bucket)
```

---

## Notes for DOS-Me Team

1. **Foreign Keys**: Bexly tables reference `public.wallets` and `public.bank_accounts`. Make sure these tables exist first.

2. **Auth**: Bexly uses `auth.users(id)` for user references. This is standard Supabase auth.

3. **Schema Isolation**: Bexly queries will use `bexly.*` schema. DOS-Me queries use `dosme.*`. No conflicts.

4. **RLS Security**: Each user can only see their own data. RLS policies enforce `auth.uid() = user_id`.

5. **Soft Deletes**: `transactions` table has `deleted_at` for soft deletes. Queries filter `WHERE deleted_at IS NULL`.

6. **Performance**: Indexes are optimized for common queries (user_id, date, category).

7. **API Keys**: Share the **publishable key** (`sb_publishable_...`) with Bexly team - it's safe for client apps. **Never share secret keys** (`sb_secret_...`).

---

## Contact

Questions? Contact Bexly team:
- GitHub: BexlyApp/Bexly
- Issues: Create issue in repo

---

**Migration Version:** 1.0
**Date:** 2026-01-09
**Author:** Bexly Team
**Reviewed by:** DOS-Me Team
