-- Recreate BEXLY schema with all tables, permissions, and RLS policies
-- After running this migration, you MUST add 'bexly' to "Exposed schemas" in Supabase Dashboard

-- 1. Create bexly schema
CREATE SCHEMA IF NOT EXISTS bexly;

-- 2. Grant permissions on schema
GRANT USAGE ON SCHEMA bexly TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA bexly TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA bexly TO anon, authenticated;

-- Auto-grant for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA bexly GRANT ALL ON SEQUENCES TO anon, authenticated;

-- 3. Create Wallets table
CREATE TABLE IF NOT EXISTS bexly.wallets (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'VND',
  balance NUMERIC(20, 2) NOT NULL DEFAULT 0,
  icon TEXT,
  color TEXT,
  wallet_type TEXT,
  billing_date INTEGER,
  interest_rate NUMERIC(5, 2),
  is_shared BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Create Categories table
CREATE TABLE IF NOT EXISTS bexly.categories (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  icon_background TEXT,
  icon_type TEXT,
  parent_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE SET NULL,
  description TEXT,
  localized_titles TEXT,
  is_system_default BOOLEAN NOT NULL DEFAULT FALSE,
  category_type TEXT NOT NULL CHECK (category_type IN ('income', 'expense')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Create Transactions table
CREATE TABLE IF NOT EXISTS bexly.transactions (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
  category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense', 'transfer')),
  amount NUMERIC(20, 2) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  transaction_date TIMESTAMPTZ NOT NULL,
  title TEXT NOT NULL,
  notes TEXT,
  parsed_from_email BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Create Chat Messages table
CREATE TABLE IF NOT EXISTS bexly.chat_messages (
  message_id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_from_user BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Create Budgets table
CREATE TABLE IF NOT EXISTS bexly.budgets (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE CASCADE,
  amount NUMERIC(20, 2) NOT NULL,
  period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Create Budget Alerts table
CREATE TABLE IF NOT EXISTS bexly.budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES bexly.budgets(cloud_id) ON DELETE CASCADE,
  threshold_percentage INTEGER NOT NULL,
  is_triggered BOOLEAN NOT NULL DEFAULT FALSE,
  triggered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Create Savings Goals table
CREATE TABLE IF NOT EXISTS bexly.savings_goals (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  target_amount NUMERIC(20, 2) NOT NULL,
  current_amount NUMERIC(20, 2) NOT NULL DEFAULT 0,
  deadline DATE,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_target_amount CHECK (target_amount > 0),
  CONSTRAINT valid_current_amount CHECK (current_amount >= 0)
);

-- 10. Create Recurring Transactions table
CREATE TABLE IF NOT EXISTS bexly.recurring_transactions (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
  category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  amount NUMERIC(20, 2) NOT NULL,
  title TEXT NOT NULL,
  notes TEXT,
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  last_executed TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Create Family Groups table
CREATE TABLE IF NOT EXISTS bexly.family_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Create Family Members table
CREATE TABLE IF NOT EXISTS bexly.family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES bexly.family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(group_id, user_id)
);

-- 13. Create Shared Wallets table
CREATE TABLE IF NOT EXISTS bexly.shared_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES bexly.family_groups(id) ON DELETE CASCADE,
  shared_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(wallet_id, group_id)
);

-- 14. Create User Settings table
CREATE TABLE IF NOT EXISTS bexly.user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  default_currency VARCHAR(3) NOT NULL DEFAULT 'VND',
  theme TEXT NOT NULL DEFAULT 'system',
  language TEXT NOT NULL DEFAULT 'vi',
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. Create Notifications table
CREATE TABLE IF NOT EXISTS bexly.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. Create Checklist Items table
CREATE TABLE IF NOT EXISTS bexly.checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON bexly.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_is_active ON bexly.wallets(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON bexly.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON bexly.categories(category_type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON bexly.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON bexly.transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON bexly.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON bexly.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON bexly.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON bexly.chat_messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON bexly.budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_user_id ON bexly.recurring_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_is_active ON bexly.recurring_transactions(is_active);

-- Enable Row Level Security on all tables
ALTER TABLE bexly.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.budget_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.shared_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.checklist_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
CREATE POLICY "Users can CRUD their own wallets"
  ON bexly.wallets FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own categories"
  ON bexly.categories FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own transactions"
  ON bexly.transactions FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own chat messages"
  ON bexly.chat_messages FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own budgets"
  ON bexly.budgets FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view budget alerts for their budgets"
  ON bexly.budget_alerts FOR SELECT TO authenticated
  USING (budget_id IN (SELECT cloud_id FROM bexly.budgets WHERE user_id = auth.uid()));

CREATE POLICY "Users can CRUD their own savings goals"
  ON bexly.savings_goals FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own recurring transactions"
  ON bexly.recurring_transactions FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view family groups they own"
  ON bexly.family_groups FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can view family members in their groups"
  ON bexly.family_members FOR SELECT TO authenticated
  USING (group_id IN (SELECT id FROM bexly.family_groups WHERE owner_id = auth.uid()));

CREATE POLICY "Users can view shared wallets in their groups"
  ON bexly.shared_wallets FOR SELECT TO authenticated
  USING (group_id IN (SELECT id FROM bexly.family_groups WHERE owner_id = auth.uid()));

CREATE POLICY "Users can CRUD their own settings"
  ON bexly.user_settings FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own notifications"
  ON bexly.notifications FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can CRUD their own checklist items"
  ON bexly.checklist_items FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- IMPORTANT: After running this migration, you MUST:
-- 1. Go to Supabase Dashboard → Settings → API → "Exposed schemas"
-- 2. Add 'bexly' to the list (e.g., "public, graphql_public, bexly")
-- 3. Save to restart PostgREST
