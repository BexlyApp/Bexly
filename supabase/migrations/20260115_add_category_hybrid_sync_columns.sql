-- Add Modified Hybrid Sync columns to categories table
-- This enables smart category sync: only modified/custom categories sync to cloud

-- 1. Add new columns to bexly.categories
ALTER TABLE bexly.categories
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'built-in',
ADD COLUMN IF NOT EXISTS built_in_id TEXT,
ADD COLUMN IF NOT EXISTS has_been_modified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- 2. Add constraints
ALTER TABLE bexly.categories
ADD CONSTRAINT check_source CHECK (source IN ('built-in', 'custom'));

-- 3. Create index for sync queries
CREATE INDEX IF NOT EXISTS idx_categories_needs_sync
  ON bexly.categories(user_id, source, has_been_modified, is_deleted)
  WHERE has_been_modified = TRUE OR source = 'custom';

CREATE INDEX IF NOT EXISTS idx_categories_built_in_id
  ON bexly.categories(built_in_id)
  WHERE built_in_id IS NOT NULL;

-- 4. Update RLS policies (replace existing)
DROP POLICY IF EXISTS "Users can CRUD their own categories" ON bexly.categories;

-- New policies with soft delete support
CREATE POLICY "Users can view own non-deleted categories"
  ON bexly.categories FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND is_deleted = FALSE);

CREATE POLICY "Users can insert own categories"
  ON bexly.categories FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own categories"
  ON bexly.categories FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own categories"
  ON bexly.categories FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- 5. Migration: Mark all existing categories as 'built-in' with modified flag
-- (This assumes all current categories are built-ins that have been synced)
UPDATE bexly.categories
SET
  source = 'built-in',
  has_been_modified = TRUE,  -- Keep them synced (migration safety)
  built_in_id = LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '_', 'g'))
WHERE source IS NULL OR source = '';

-- Note: After migration, admin should run cleanup script to:
-- 1. Match categories to built-in templates by name
-- 2. Set has_been_modified = FALSE for exact matches
-- 3. Delete unmodified built-ins from cloud (optional optimization)

COMMENT ON COLUMN bexly.categories.source IS 'Origin: built-in (from templates) or custom (user-created)';
COMMENT ON COLUMN bexly.categories.built_in_id IS 'Stable ID for built-in templates (e.g., food, transport)';
COMMENT ON COLUMN bexly.categories.has_been_modified IS 'TRUE if user modified built-in category (triggers sync)';
COMMENT ON COLUMN bexly.categories.is_deleted IS 'Soft delete flag (sync deletion across devices)';
