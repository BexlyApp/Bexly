# 📊 BEXLY DATA CLASSIFICATION FOR DOS.ME ECOSYSTEM

> **Document Purpose**: Định nghĩa rõ ràng data nào của Bexly sẽ được shared trong DOS-Me ecosystem và data nào là Bexly-specific.
>
> **Created**: 2026-01-11
>
> **Migration Target**: Supabase PostgreSQL

---

## 🌍 **1. SHARED DATA** (Public Schema - Dùng chung toàn hệ sinh thái DOS)

Đây là data sẽ nằm trong **`public` schema** của DOS-Me Supabase, được share giữa Bexly, DOS.AI, MetaDOS và các apps khác trong ecosystem.

### **A. User & Authentication**

#### **public.users**
```sql
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);
```

**Mục đích**: Core user profiles được share giữa tất cả apps trong DOS ecosystem.

**Fields**:
- `id`: Foreign key tới Supabase Auth users
- `email`: Email address (unique)
- `display_name`: Tên hiển thị
- `avatar_url`: URL ảnh đại diện
- `created_at`, `updated_at`: Timestamps

---

#### **public.auth_providers**
```sql
CREATE TABLE public.auth_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('google', 'apple', 'github', 'facebook')),
    provider_user_id TEXT NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)
);

-- RLS Policies
ALTER TABLE public.auth_providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own auth providers"
    ON public.auth_providers FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own auth providers"
    ON public.auth_providers FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

**Mục đích**: OAuth provider connections (Google, Apple, GitHub login).

**Fields**:
- `provider`: OAuth provider name
- `provider_user_id`: User ID from OAuth provider
- `access_token`, `refresh_token`: OAuth tokens
- `expires_at`: Token expiration

---

### **B. Financial Infrastructure**

#### **public.bank_accounts** 🏦
```sql
CREATE TABLE public.bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL DEFAULT 'stripe', -- stripe, plaid, etc.
    account_id TEXT NOT NULL, -- Provider's account ID
    institution_name TEXT,
    institution_logo TEXT,
    account_name TEXT,
    account_mask TEXT, -- Last 4 digits: ****1234
    account_type TEXT CHECK (account_type IN ('checking', 'savings', 'credit', 'investment')),
    currency TEXT DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, account_id)
);

-- RLS Policies
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bank accounts"
    ON public.bank_accounts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own bank accounts"
    ON public.bank_accounts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bank accounts"
    ON public.bank_accounts FOR UPDATE
    USING (auth.uid() = user_id);
```

**Mục đích**: **CRITICAL SHARED TABLE** - Stripe Financial Connections bank accounts.

**⚠️ Integration Point**:
```dart
// Bexly's bank_connection_service.dart
POST https://dos.me/api/bank-accounts/connect
→ Saves to public.bank_accounts (SHARED TABLE!)
→ Used by: Bexly (personal finance) + DOS.AI (business analytics)
```

**Fields**:
- `provider`: 'stripe', 'plaid', etc.
- `account_id`: Provider's unique account identifier
- `institution_name`: Bank name (e.g., "Chase", "Bank of America")
- `account_mask`: Last 4 digits for privacy
- `account_type`: checking/savings/credit/investment
- `is_active`: Can be disconnected but keep history

---

#### **public.wallets** (Web3 Crypto Wallets)
```sql
CREATE TABLE public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL DEFAULT 'openfort', -- openfort, metamask, etc.
    address TEXT NOT NULL, -- Blockchain address
    chain TEXT NOT NULL CHECK (chain IN ('polygon', 'ethereum', 'solana', 'base')),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(address, chain)
);

-- RLS Policies
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallets"
    ON public.wallets FOR SELECT
    USING (auth.uid() = user_id);
```

**Mục đích**: Openfort Web3 crypto wallets (future use).

**⚠️ NOTE**: Đây là **crypto wallets**, KHÁC HOÀN TOÀN với Bexly financial wallets (cash/bank/credit card)!

**Fields**:
- `provider`: 'openfort', 'metamask', etc.
- `address`: Blockchain wallet address
- `chain`: polygon/ethereum/solana/base
- `is_primary`: Primary wallet flag

---

### **C. Organizations** (For DOS.AI Teams)

#### **public.organizations**
```sql
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    description TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organization members can view"
    ON public.organizations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.organization_members
            WHERE organization_id = id AND user_id = auth.uid()
        )
    );
```

**Mục đích**: Organizations cho DOS.AI teams, Bexly family groups có thể migrate sang sau này.

---

#### **public.organization_members**
```sql
CREATE TABLE public.organization_members (
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('owner', 'admin', 'member')) DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (organization_id, user_id)
);

-- RLS Policies
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view organization members"
    ON public.organization_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.organization_members om
            WHERE om.organization_id = organization_id
            AND om.user_id = auth.uid()
        )
    );
```

**Mục đích**: Organization membership tracking.

**Fields**:
- `role`: 'owner', 'admin', 'member'
- `joined_at`: When member joined

---

## 💰 **2. BEXLY-SPECIFIC DATA** (Bexly Schema)

Đây là data chỉ Bexly app sử dụng, nằm trong **`bexly` schema** riêng biệt.

### **A. Core Financial Tables**

#### **bexly.wallets** (Financial Wallets)
```sql
CREATE TABLE bexly.wallets (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    balance NUMERIC(15,2) DEFAULT 0,
    initial_balance NUMERIC(15,2) DEFAULT 0,
    currency TEXT DEFAULT 'IDR',
    wallet_type TEXT CHECK (wallet_type IN ('cash', 'bank_account', 'credit_card')) DEFAULT 'cash',

    -- Credit card specific fields
    credit_limit NUMERIC(15,2),
    billing_day INTEGER CHECK (billing_day BETWEEN 1 AND 31),
    interest_rate NUMERIC(5,2),

    -- UI customization
    icon_name TEXT,
    color_hex TEXT,

    -- Family sharing
    is_shared BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT unique_wallet_name UNIQUE(user_id, name)
);

-- RLS Policies
ALTER TABLE bexly.wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallets"
    ON bexly.wallets FOR SELECT
    USING (
        auth.uid() = user_id
        OR
        -- Can view shared wallets from family
        EXISTS (
            SELECT 1 FROM bexly.shared_wallets sw
            JOIN bexly.family_members fm ON fm.family_id = sw.family_id
            WHERE sw.wallet_id = cloud_id
            AND fm.user_id = auth.uid()
            AND sw.is_active = TRUE
        )
    );

CREATE POLICY "Users can insert own wallets"
    ON bexly.wallets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wallets"
    ON bexly.wallets FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_wallets_user_id ON bexly.wallets(user_id);
CREATE INDEX idx_wallets_deleted_at ON bexly.wallets(deleted_at) WHERE deleted_at IS NULL;
```

**Mục đích**: Financial wallets - cash, bank accounts, credit cards.

**⚠️ KHÁC với public.wallets (crypto)!**

**Wallet Types**:
- `cash`: Tiền mặt
- `bank_account`: Tài khoản ngân hàng
- `credit_card`: Thẻ tín dụng (có credit_limit, billing_day, interest_rate)

**Credit Card Fields**:
- `credit_limit`: Hạn mức thẻ
- `billing_day`: Ngày chốt sao kê (1-31)
- `interest_rate`: Lãi suất (%/năm)

**Family Sharing**:
- `is_shared`: Có được chia sẻ với family không

---

#### **bexly.transactions**
```sql
CREATE TABLE bexly.transactions (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,

    -- Optional link to shared bank account
    bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE SET NULL,

    category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE SET NULL,
    transaction_type TEXT CHECK (transaction_type IN ('income', 'expense', 'transfer')) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    title TEXT,
    notes TEXT,
    image_path TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW(),

    -- Recurring payment tracking
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_id UUID REFERENCES bexly.recurring_transactions(cloud_id) ON DELETE SET NULL,

    -- Family sharing audit
    created_by_user_id UUID REFERENCES public.users(id),
    last_modified_by_user_id UUID REFERENCES public.users(id),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- RLS Policies
ALTER TABLE bexly.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
    ON bexly.transactions FOR SELECT
    USING (
        auth.uid() = user_id
        OR
        -- Can view transactions in shared wallets
        EXISTS (
            SELECT 1 FROM bexly.wallets w
            JOIN bexly.shared_wallets sw ON sw.wallet_id = w.cloud_id
            JOIN bexly.family_members fm ON fm.family_id = sw.family_id
            WHERE w.cloud_id = wallet_id
            AND fm.user_id = auth.uid()
            AND sw.is_active = TRUE
        )
    );

CREATE POLICY "Users can insert own transactions"
    ON bexly.transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
    ON bexly.transactions FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_transactions_user_id ON bexly.transactions(user_id);
CREATE INDEX idx_transactions_wallet_id ON bexly.transactions(wallet_id);
CREATE INDEX idx_transactions_date ON bexly.transactions(transaction_date DESC);
CREATE INDEX idx_transactions_deleted_at ON bexly.transactions(deleted_at) WHERE deleted_at IS NULL;
```

**Mục đích**: Tất cả giao dịch thu/chi/chuyển khoản.

**Transaction Types**:
- `income`: Thu nhập
- `expense`: Chi tiêu
- `transfer`: Chuyển khoản giữa các wallets

**Important Links**:
- `wallet_id` → bexly.wallets (required)
- `bank_account_id` → public.bank_accounts (optional, for imported bank transactions)
- `category_id` → bexly.categories (optional)
- `recurring_id` → bexly.recurring_transactions (optional, if auto-created from recurring)

**Family Sharing Audit**:
- `created_by_user_id`: User tạo transaction
- `last_modified_by_user_id`: User sửa lần cuối

---

#### **bexly.categories**
```sql
CREATE TABLE bexly.categories (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon TEXT,
    icon_background TEXT,
    icon_type TEXT,

    -- Subcategories support
    parent_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE CASCADE,

    description TEXT,
    localized_titles JSONB, -- {"en": "Food", "vi": "Ăn uống", "id": "Makanan"}
    is_system_default BOOLEAN DEFAULT FALSE, -- Cannot be deleted by user
    transaction_type TEXT CHECK (transaction_type IN ('income', 'expense')) NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_category UNIQUE(user_id, title, transaction_type)
);

-- RLS Policies
ALTER TABLE bexly.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own categories"
    ON bexly.categories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories"
    ON bexly.categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
    ON bexly.categories FOR UPDATE
    USING (auth.uid() = user_id AND is_system_default = FALSE);

-- Indexes
CREATE INDEX idx_categories_user_id ON bexly.categories(user_id);
CREATE INDEX idx_categories_parent_id ON bexly.categories(parent_id);
```

**Mục đích**: Danh mục giao dịch (Food, Transportation, Entertainment, etc.).

**Features**:
- **Subcategories**: `parent_id` cho nested categories
- **Localization**: `localized_titles` JSONB cho nhiều ngôn ngữ
- **System defaults**: `is_system_default = TRUE` không thể xóa
- **Transaction type**: Riêng cho income hoặc expense

**Example Localized Titles**:
```json
{
  "en": "Food & Dining",
  "vi": "Ăn uống",
  "id": "Makanan"
}
```

---

### **B. Financial Planning**

#### **bexly.budgets**
```sql
CREATE TABLE bexly.budgets (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
    category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_routine BOOLEAN DEFAULT FALSE, -- Repeating budget
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own budgets"
    ON bexly.budgets FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_budgets_user_id ON bexly.budgets(user_id);
CREATE INDEX idx_budgets_wallet_id ON bexly.budgets(wallet_id);
CREATE INDEX idx_budgets_date_range ON bexly.budgets(start_date, end_date);
```

**Mục đích**: Ngân sách chi tiêu theo category và wallet.

**Fields**:
- `is_routine`: Budget lặp lại (monthly, yearly, etc.)
- `start_date`, `end_date`: Budget period

---

#### **bexly.goals**
```sql
CREATE TABLE bexly.goals (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon_name TEXT,
    target_amount NUMERIC(15,2) NOT NULL,
    current_amount NUMERIC(15,2) DEFAULT 0,
    start_date DATE,
    end_date DATE,
    pinned BOOLEAN DEFAULT FALSE, -- Show on dashboard
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals"
    ON bexly.goals FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_goals_user_id ON bexly.goals(user_id);
CREATE INDEX idx_goals_pinned ON bexly.goals(user_id, pinned) WHERE pinned = TRUE;
```

**Mục đích**: Mục tiêu tiết kiệm (Buy a car, Vacation fund, Emergency fund).

**Fields**:
- `wallet_id`: Optional wallet link
- `pinned`: Hiện trên dashboard
- `current_amount`: Progress tracking

---

#### **bexly.checklist_items**
```sql
CREATE TABLE bexly.checklist_items (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID REFERENCES bexly.goals(cloud_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC(15,2),
    link TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.checklist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage checklist items"
    ON bexly.checklist_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM bexly.goals
            WHERE cloud_id = goal_id AND user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_checklist_goal_id ON bexly.checklist_items(goal_id);
```

**Mục đích**: Checklist cho từng goal (Research cars, Save $500, Visit dealership).

---

### **C. Recurring Payments**

#### **bexly.recurring_transactions**
```sql
CREATE TABLE bexly.recurring_transactions (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
    category_id UUID REFERENCES bexly.categories(cloud_id) ON DELETE SET NULL,

    -- Basic info
    name TEXT NOT NULL,
    description TEXT,
    vendor_name TEXT,
    amount NUMERIC(15,2) NOT NULL,
    currency TEXT DEFAULT 'IDR',

    -- Frequency configuration
    frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')) NOT NULL,
    custom_interval INTEGER, -- For custom frequency: every X units
    custom_unit TEXT CHECK (custom_unit IN ('days', 'weeks', 'months', 'years')),
    billing_day INTEGER CHECK (billing_day BETWEEN 1 AND 31),

    -- Status
    status TEXT CHECK (status IN ('active', 'paused', 'cancelled', 'expired')) DEFAULT 'active',

    -- Automation
    auto_create BOOLEAN DEFAULT FALSE, -- Auto create transactions on due date
    enable_reminder BOOLEAN DEFAULT FALSE,
    reminder_days_before INTEGER DEFAULT 1,

    -- UI customization
    notes TEXT,
    icon_name TEXT,
    color_hex TEXT,

    -- Dates
    start_date DATE NOT NULL,
    next_due_date DATE NOT NULL,
    end_date DATE,
    last_charged_date DATE,
    total_payments INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.recurring_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own recurring transactions"
    ON bexly.recurring_transactions FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_recurring_user_id ON bexly.recurring_transactions(user_id);
CREATE INDEX idx_recurring_next_due ON bexly.recurring_transactions(next_due_date) WHERE status = 'active';
CREATE INDEX idx_recurring_wallet_id ON bexly.recurring_transactions(wallet_id);
```

**Mục đích**: Quản lý recurring payments (Netflix, Spotify, rent, bills).

**Frequency Types**:
- `daily`, `weekly`, `monthly`, `quarterly`, `yearly`
- `custom`: Dùng `custom_interval` + `custom_unit` (e.g., every 3 months)

**Status**:
- `active`: Đang hoạt động
- `paused`: Tạm dừng
- `cancelled`: Đã hủy
- `expired`: Hết hạn (reached end_date)

**Automation**:
- `auto_create = TRUE`: Tự động tạo transactions vào `next_due_date`
- `enable_reminder`: Gửi notification trước X ngày

---

### **D. Family Sharing**

#### **bexly.family_groups**
```sql
CREATE TABLE bexly.family_groups (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    icon_name TEXT,
    color_hex TEXT,
    max_members INTEGER DEFAULT 5,
    invite_code TEXT UNIQUE NOT NULL, -- 8-char code for deep linking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.family_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view group"
    ON bexly.family_groups FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bexly.family_members
            WHERE family_id = cloud_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Owner can update group"
    ON bexly.family_groups FOR UPDATE
    USING (auth.uid() = owner_id);

-- Function to generate invite code
CREATE OR REPLACE FUNCTION generate_invite_code() RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude ambiguous chars
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Indexes
CREATE INDEX idx_family_groups_owner ON bexly.family_groups(owner_id);
CREATE INDEX idx_family_groups_invite_code ON bexly.family_groups(invite_code);
```

**Mục đích**: Family groups để share wallets.

**Fields**:
- `invite_code`: 8-char unique code (e.g., "AB3KL9XY") for deep link invites
- `max_members`: Maximum members allowed (default 5)

---

#### **bexly.family_members**
```sql
CREATE TABLE bexly.family_members (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES bexly.family_groups(cloud_id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    display_name TEXT,
    email TEXT,
    avatar_url TEXT,
    role TEXT CHECK (role IN ('owner', 'editor', 'viewer')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'active', 'left')) DEFAULT 'pending',
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- RLS Policies
ALTER TABLE bexly.family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view members"
    ON bexly.family_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bexly.family_members fm
            WHERE fm.family_id = family_id AND fm.user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_family_members_family_id ON bexly.family_members(family_id);
CREATE INDEX idx_family_members_user_id ON bexly.family_members(user_id);
```

**Mục đích**: Thành viên của family group.

**Roles**:
- `owner`: Chủ group (1 người)
- `editor`: Có thể tạo/sửa/xóa transactions
- `viewer`: Chỉ xem

**Status**:
- `pending`: Chờ accept invite
- `active`: Đã join
- `left`: Đã rời khỏi group

---

#### **bexly.family_invitations**
```sql
CREATE TABLE bexly.family_invitations (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES bexly.family_groups(cloud_id) ON DELETE CASCADE,
    invited_email TEXT NOT NULL,
    invited_by_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    invite_code TEXT UNIQUE NOT NULL,
    role TEXT CHECK (role IN ('editor', 'viewer')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'cancelled')) DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.family_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Invited users can view own invitations"
    ON bexly.family_invitations FOR SELECT
    USING (
        invited_email = (SELECT email FROM public.users WHERE id = auth.uid())
        OR
        EXISTS (
            SELECT 1 FROM bexly.family_members
            WHERE family_id = family_invitations.family_id AND user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_invitations_email ON bexly.family_invitations(invited_email);
CREATE INDEX idx_invitations_code ON bexly.family_invitations(invite_code);
CREATE INDEX idx_invitations_status ON bexly.family_invitations(status) WHERE status = 'pending';
```

**Mục đích**: Lời mời tham gia family.

**Status**:
- `pending`: Chờ response
- `accepted`: Đã accept
- `rejected`: Đã từ chối
- `expired`: Hết hạn
- `cancelled`: Owner hủy invite

---

#### **bexly.shared_wallets**
```sql
CREATE TABLE bexly.shared_wallets (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES bexly.family_groups(cloud_id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES bexly.wallets(cloud_id) ON DELETE CASCADE,
    shared_by_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE, -- Can unshare but keep history
    shared_at TIMESTAMPTZ DEFAULT NOW(),
    unshared_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, wallet_id)
);

-- RLS Policies
ALTER TABLE bexly.shared_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view shared wallets"
    ON bexly.shared_wallets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bexly.family_members
            WHERE family_id = shared_wallets.family_id AND user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_shared_wallets_family_id ON bexly.shared_wallets(family_id);
CREATE INDEX idx_shared_wallets_wallet_id ON bexly.shared_wallets(wallet_id);
CREATE INDEX idx_shared_wallets_active ON bexly.shared_wallets(family_id, is_active) WHERE is_active = TRUE;
```

**Mục đích**: Tracking wallets được share với family.

**Fields**:
- `is_active`: `FALSE` = unshared nhưng giữ history
- `shared_at`, `unshared_at`: Audit trail

---

### **E. AI & Automation**

#### **bexly.chat_messages**
```sql
CREATE TABLE bexly.chat_messages (
    message_id TEXT PRIMARY KEY, -- UUID as text
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_from_user BOOLEAN NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    error TEXT,
    is_typing BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat messages"
    ON bexly.chat_messages FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_chat_messages_user_id ON bexly.chat_messages(user_id);
CREATE INDEX idx_chat_messages_timestamp ON bexly.chat_messages(timestamp DESC);
```

**Mục đích**: Lịch sử chat với AI assistant.

**Fields**:
- `is_from_user`: `TRUE` = user message, `FALSE` = AI response
- `is_typing`: Typing indicator
- `error`: Error message nếu AI call failed

---

#### **bexly.parsed_email_transactions**
```sql
CREATE TABLE bexly.parsed_email_transactions (
    id SERIAL PRIMARY KEY, -- Serial for auto-increment
    cloud_id UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,

    -- Gmail metadata
    gmail_message_id TEXT NOT NULL,
    email_subject TEXT,
    from_email TEXT,

    -- Parsed transaction data
    amount NUMERIC(15,2) NOT NULL,
    currency TEXT DEFAULT 'VND',
    transaction_type TEXT CHECK (transaction_type IN ('income', 'expense')) NOT NULL,
    merchant TEXT,
    account_last4 TEXT,
    balance_after NUMERIC(15,2),
    transaction_date TIMESTAMPTZ NOT NULL,
    email_date TIMESTAMPTZ NOT NULL,

    -- AI parsing metadata
    confidence NUMERIC(3,2) DEFAULT 0.8 CHECK (confidence BETWEEN 0 AND 1),
    raw_amount_text TEXT,
    category_hint TEXT,
    bank_name TEXT,

    -- Review workflow
    status TEXT CHECK (status IN ('pending_review', 'approved', 'rejected', 'imported')) DEFAULT 'pending_review',
    imported_transaction_id UUID REFERENCES bexly.transactions(cloud_id),
    target_wallet_id UUID REFERENCES bexly.wallets(cloud_id),
    selected_category_id UUID REFERENCES bexly.categories(cloud_id),
    user_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, gmail_message_id)
);

-- RLS Policies
ALTER TABLE bexly.parsed_email_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own parsed emails"
    ON bexly.parsed_email_transactions FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_parsed_email_user_id ON bexly.parsed_email_transactions(user_id);
CREATE INDEX idx_parsed_email_status ON bexly.parsed_email_transactions(status) WHERE status = 'pending_review';
CREATE INDEX idx_parsed_email_date ON bexly.parsed_email_transactions(transaction_date DESC);
```

**Mục đích**: Auto-parsed transactions từ banking emails.

**Workflow**:
1. Gmail API fetch → AI parse → `pending_review`
2. User review → `approved` hoặc `rejected`
3. Approved → Import to transactions → `imported` + set `imported_transaction_id`

**AI Metadata**:
- `confidence`: 0-1 score (0.8 = 80% confident)
- `raw_amount_text`: Original text from email
- `category_hint`: AI-suggested category

---

#### **bexly.notifications**
```sql
CREATE TABLE bexly.notifications (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT CHECK (type IN ('daily_reminder', 'weekly_report', 'monthly_report', 'goal_milestone', 'recurring_payment')) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    scheduled_for TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bexly.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notifications"
    ON bexly.notifications FOR ALL
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_notifications_user_id ON bexly.notifications(user_id);
CREATE INDEX idx_notifications_unread ON bexly.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_scheduled ON bexly.notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;
```

**Mục đích**: Notification history và scheduling.

**Types**:
- `daily_reminder`: Nhắc nhở hàng ngày
- `weekly_report`, `monthly_report`: Báo cáo định kỳ
- `goal_milestone`: Đạt mốc goal
- `recurring_payment`: Nhắc recurring payment sắp đến hạn

---

## 🔗 **KEY INTEGRATION POINTS**

### **1. Bank Account Integration** (CRITICAL)
```typescript
// Bexly → DOS-Me API → Supabase
POST https://dos.me/api/bank-accounts/connect
{
  userId: "uuid",
  stripeAccountId: "acct_xxx",
  institutionName: "Chase",
  accountMask: "****1234"
}

// Response
{
  id: "uuid",
  accountId: "acct_xxx"
}

// Bexly saves to:
// 1. public.bank_accounts (shared table)
// 2. Can link to bexly.transactions via bank_account_id
```

**Flow**:
1. User connects bank via Stripe Financial Connections (in Bexly app)
2. Bexly calls DOS-Me API endpoint
3. DOS-Me saves to `public.bank_accounts` (shared table)
4. Bexly transactions can reference `bank_account_id`
5. DOS.AI can also use same bank accounts for business analytics

---

### **2. User Authentication**
```sql
-- User signs up
INSERT INTO auth.users (email, password)
RETURNING id;

-- Trigger creates public.users record
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

### **3. Data Ownership & RLS**

**Public Schema** (shared):
```sql
-- RLS based on auth.uid()
CREATE POLICY "Users own their data"
ON public.bank_accounts FOR ALL
USING (user_id = auth.uid());
```

**Bexly Schema** (scoped):
```sql
-- RLS with family sharing support
CREATE POLICY "Users can view own and shared wallets"
ON bexly.wallets FOR SELECT
USING (
    user_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM bexly.shared_wallets sw
        JOIN bexly.family_members fm ON fm.family_id = sw.family_id
        WHERE sw.wallet_id = cloud_id
        AND fm.user_id = auth.uid()
        AND sw.is_active = TRUE
    )
);
```

---

## 📊 **SUMMARY TABLE**

| Schema | Tables | Purpose | Shared Across Apps? |
|--------|--------|---------|---------------------|
| **public** | 6 tables | User, Auth, Bank Accounts, Web3 Wallets, Organizations | ✅ YES - All DOS apps |
| **bexly** | 13 tables | Financial wallets, transactions, budgets, goals, recurring, family, AI, email sync | ❌ NO - Bexly only |

---

## 🚀 **MIGRATION CHECKLIST**

### **Phase 1: Public Schema** (DOS-Me Team)
- [ ] Create `public.users` table + RLS
- [ ] Create `public.auth_providers` table + RLS
- [ ] Create `public.bank_accounts` table + RLS ⚠️ **CRITICAL for Bexly**
- [ ] Create `public.wallets` table + RLS (Web3)
- [ ] Create `public.organizations` + `organization_members` + RLS
- [ ] Setup auth triggers (auth.users → public.users)

### **Phase 2: Bexly Schema** (Bexly Team)
- [ ] Create `bexly` schema
- [ ] Run migration SQL from `BEXLY_MIGRATION_READY_TO_RUN.sql`
- [ ] Setup all RLS policies
- [ ] Create indexes
- [ ] Test cross-schema foreign keys (bexly.transactions → public.bank_accounts)

### **Phase 3: Integration Testing**
- [ ] Test bank connection flow: Bexly → DOS-Me API → public.bank_accounts
- [ ] Test user signup: auth.users → public.users trigger
- [ ] Test family sharing RLS policies
- [ ] Test transaction creation with bank_account_id link
- [ ] Test data sync from Firebase → Supabase

---

## 📝 **NOTES**

### **Database Naming Conventions**
- **Table names**: Lowercase with underscores (e.g., `bank_accounts`, `family_groups`)
- **Primary keys**: `id` (public schema) or `cloud_id` (bexly schema, UUID v7)
- **Foreign keys**: `{table}_id` (e.g., `user_id`, `wallet_id`)
- **Timestamps**: Always `TIMESTAMPTZ` (timezone-aware)
- **Soft deletes**: `deleted_at TIMESTAMPTZ` (NULL = active)

### **UUID Strategy**
- **public schema**: `gen_random_uuid()` (Supabase default)
- **bexly schema**: UUID v7 (time-ordered) generated in Dart code for offline sync support

### **RLS Security**
- ALL tables have RLS enabled
- Public schema: Simple `user_id = auth.uid()`
- Bexly schema: Complex policies with family sharing support

### **Performance Considerations**
- Indexes on all foreign keys
- Indexes on frequently queried columns (date, status, is_active)
- Partial indexes for soft deletes (`WHERE deleted_at IS NULL`)

---

**Document Version**: 1.0
**Last Updated**: 2026-01-11
**Maintained by**: Bexly Team
**For**: DOS-Me Ecosystem Integration
