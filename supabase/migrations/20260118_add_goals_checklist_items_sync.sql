-- Migration for Goals and Checklist Items Supabase sync
-- This migration ensures goals and checklist_items tables have all required columns
-- for syncing from Bexly Flutter app to Supabase cloud

-- ========================================
-- GOALS TABLE
-- ========================================

-- Create goals table if not exists
CREATE TABLE IF NOT EXISTS bexly.goals (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  target_amount DOUBLE PRECISION NOT NULL,
  current_amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  icon_name TEXT,
  associated_account_id INTEGER,
  pinned BOOLEAN DEFAULT FALSE
);

-- Add missing columns if table already exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bexly' AND table_name = 'goals') THEN
    -- Add user_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'user_id') THEN
      ALTER TABLE bexly.goals ADD COLUMN user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- Add description if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'description') THEN
      ALTER TABLE bexly.goals ADD COLUMN description TEXT;
    END IF;

    -- Add start_date if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'start_date') THEN
      ALTER TABLE bexly.goals ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Add created_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'created_at') THEN
      ALTER TABLE bexly.goals ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add icon_name if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'icon_name') THEN
      ALTER TABLE bexly.goals ADD COLUMN icon_name TEXT;
    END IF;

    -- Add associated_account_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'associated_account_id') THEN
      ALTER TABLE bexly.goals ADD COLUMN associated_account_id INTEGER;
    END IF;

    -- Add pinned if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'goals' AND column_name = 'pinned') THEN
      ALTER TABLE bexly.goals ADD COLUMN pinned BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
END $$;

-- Create index for user_id for better query performance
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON bexly.goals(user_id);

-- Create index for pinned goals
CREATE INDEX IF NOT EXISTS idx_goals_pinned ON bexly.goals(pinned) WHERE pinned = TRUE;

-- ========================================
-- CHECKLIST_ITEMS TABLE
-- ========================================

-- Create checklist_items table if not exists
CREATE TABLE IF NOT EXISTS bexly.checklist_items (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  goal_id UUID NOT NULL REFERENCES bexly.goals(cloud_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount DOUBLE PRECISION,
  link TEXT,
  completed BOOLEAN DEFAULT FALSE
);

-- Add missing columns if table already exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bexly' AND table_name = 'checklist_items') THEN
    -- Add user_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'checklist_items' AND column_name = 'user_id') THEN
      ALTER TABLE bexly.checklist_items ADD COLUMN user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- Add cloud_id if missing (and make it primary key)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'bexly' AND table_name = 'checklist_items' AND column_name = 'cloud_id') THEN
      ALTER TABLE bexly.checklist_items ADD COLUMN cloud_id UUID;
      -- Update existing rows with new UUIDs
      UPDATE bexly.checklist_items SET cloud_id = gen_random_uuid() WHERE cloud_id IS NULL;
      -- Make it primary key
      ALTER TABLE bexly.checklist_items ALTER COLUMN cloud_id SET NOT NULL;
      ALTER TABLE bexly.checklist_items ADD PRIMARY KEY (cloud_id);
    END IF;
  END IF;
END $$;

-- Create index for user_id for better query performance
CREATE INDEX IF NOT EXISTS idx_checklist_items_user_id ON bexly.checklist_items(user_id);

-- Create index for goal_id for better query performance
CREATE INDEX IF NOT EXISTS idx_checklist_items_goal_id ON bexly.checklist_items(goal_id);

-- ========================================
-- ROW LEVEL SECURITY (RLS)
-- ========================================

-- Enable RLS on goals table
ALTER TABLE bexly.goals ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own goals
CREATE POLICY IF NOT EXISTS "Users can view their own goals"
  ON bexly.goals FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own goals
CREATE POLICY IF NOT EXISTS "Users can insert their own goals"
  ON bexly.goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own goals
CREATE POLICY IF NOT EXISTS "Users can update their own goals"
  ON bexly.goals FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own goals
CREATE POLICY IF NOT EXISTS "Users can delete their own goals"
  ON bexly.goals FOR DELETE
  USING (auth.uid() = user_id);

-- Enable RLS on checklist_items table
ALTER TABLE bexly.checklist_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own checklist items
CREATE POLICY IF NOT EXISTS "Users can view their own checklist items"
  ON bexly.checklist_items FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own checklist items
CREATE POLICY IF NOT EXISTS "Users can insert their own checklist items"
  ON bexly.checklist_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own checklist items
CREATE POLICY IF NOT EXISTS "Users can update their own checklist items"
  ON bexly.checklist_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own checklist items
CREATE POLICY IF NOT EXISTS "Users can delete their own checklist items"
  ON bexly.checklist_items FOR DELETE
  USING (auth.uid() = user_id);

-- IMPORTANT: After running this migration:
-- - Goals will auto-sync from Bexly app to Supabase
-- - Checklist items will auto-sync from Bexly app to Supabase
-- - Each goal/item is scoped to the authenticated user via user_id
-- - Cascade deletes ensure data integrity (deleting goal deletes its checklist items)
