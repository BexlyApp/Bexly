# Budget Sync Migration - Required Database Changes

## Problem
Budget auto-sync to Supabase is failing with error:
```
PostgrestException: Could not find the 'is_routine' column of 'budgets' in the schema cache
```

## Root Cause
Supabase `bexly.budgets` table is missing 2 critical columns that Bexly app expects:
1. `wallet_id` - Foreign key to wallets table
2. `is_routine` - Boolean flag for routine/recurring budgets

## Solution - SQL Migration

**File**: `supabase/migrations/20260118_add_budget_missing_columns.sql`

Run this SQL in Supabase Dashboard → SQL Editor:

```sql
-- Add missing columns to budgets table
-- wallet_id: Foreign key to wallets table (each budget belongs to a specific wallet)
-- is_routine: Boolean flag for routine budgets (recurring monthly budgets vs one-time budgets)

-- Add wallet_id column
ALTER TABLE bexly.budgets
  ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE;

-- Add is_routine column
ALTER TABLE bexly.budgets
  ADD COLUMN IF NOT EXISTS is_routine BOOLEAN NOT NULL DEFAULT false;

-- Create index for wallet_id for better query performance
CREATE INDEX IF NOT EXISTS idx_budgets_wallet_id ON bexly.budgets(wallet_id);
```

## Verification

After running migration, verify with:

```sql
-- Check columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'bexly'
  AND table_name = 'budgets'
ORDER BY ordinal_position;

-- Should show:
-- cloud_id       | uuid    | NO
-- user_id        | uuid    | NO
-- category_id    | uuid    | YES
-- amount         | numeric | NO
-- period         | text    | NO
-- start_date     | date    | NO
-- end_date       | date    | YES
-- wallet_id      | uuid    | YES  ← NEW
-- is_routine     | boolean | NO   ← NEW
-- created_at     | timestamp | NO
-- updated_at     | timestamp | NO
```

## Impact

Once migration is applied:
- ✅ Budget creation via AI chat will auto-sync to Supabase
- ✅ Budget updates will sync to cloud
- ✅ Budget deletion will sync to cloud
- ✅ Multi-wallet budget support (each budget tied to specific wallet)
- ✅ Routine budget tracking (monthly recurring vs one-time budgets)

## Notes

- **Safe to run**: Uses `IF NOT EXISTS` - won't break if columns already exist
- **No data loss**: Existing budget rows will remain unchanged
- **Default values**:
  - `wallet_id` defaults to NULL (can be updated later)
  - `is_routine` defaults to FALSE (non-recurring)
- **Foreign key**: `wallet_id` references `bexly.wallets(cloud_id)` with CASCADE delete

## Priority

**HIGH** - Blocking budget sync feature for all users. Should be deployed ASAP.

---

**Migration file location**: `d:\Projects\Bexly\supabase\migrations\20260118_add_budget_missing_columns.sql`

**Related code changes**:
- `lib/core/database/daos/budget_dao.dart` - Now using Supabase sync
- `lib/core/services/sync/supabase_sync_service.dart` - Added budget sync methods
- `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` - Fixed provider race conditions
