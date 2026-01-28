# Bexly Architecture Documentation

**Last Updated**: 2026-01-25
**Version**: 0.0.10+477

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Layers](#architecture-layers)
4. [Database Architecture](#database-architecture)
5. [Authentication & Sync](#authentication--sync)
6. [Feature Modules](#feature-modules)
7. [State Management](#state-management)
8. [Data Flow](#data-flow)
9. [Security](#security)
10. [Performance](#performance)

---

## Overview

Bexly is a **cross-platform personal finance app** built with Flutter, focusing on:
- **Local storage**: SQLite as source of truth with offline support
- **Cloud sync**: Supabase PostgreSQL for multi-device sync
- **Real-time**: Supabase Realtime for instant updates
- **AI-powered**: Chat assistant for expense tracking
- **Multi-wallet**: Support multiple currencies and account types

### Key Design Principles

1. **Offline Support**: App works without internet, syncs when online
2. **Local Data Ownership**: User data stored locally in SQLite
3. **Incremental Sync**: Only changed data syncs to cloud
4. **Optimistic Updates**: UI updates immediately, sync in background
5. **Conflict Resolution**: Last-write-wins using timestamps

---

## Technology Stack

### Frontend
```yaml
Framework: Flutter 3.x (Dart)
State Management: Riverpod 2.x + Hooks
UI Components: Material 3 + Custom widgets
Routing: Go Router (declarative)
Theme: FlexColorScheme
Icons: Font Awesome Flutter
```

### Backend & Services
```yaml
Authentication: Supabase Auth (OAuth + Email/Password)
Database (Cloud): Supabase PostgreSQL (bexly schema)
Database (Local): Drift (SQLite)
Realtime: Supabase Realtime (PostgreSQL CDC)
Push Notifications: Firebase Cloud Messaging (FCM)
AI Services:
  - Google Gemini (Primary)
  - OpenAI GPT-4o (Fallback)
  - Anthropic Claude (Optional)
Payment Processing: Stripe
Bank Connections: Plaid
```

### Infrastructure
```yaml
Hosting:
  - Android: Google Play Store
  - iOS: Apple App Store (via GitHub Actions)
  - Web: Planned
Backend API: DOS-Me (https://api.dos.me)
CDN: Supabase Storage
Analytics: Firebase Analytics
Crash Reporting: Firebase Crashlytics
```

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Screens    │  │   Widgets    │  │   Dialogs    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                  ▲          │
│         │                  │                  │          │
│         └──────────────────┴──────────────────┘          │
│                            │                             │
└────────────────────────────┼─────────────────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────┐
│                  STATE MANAGEMENT LAYER                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Providers  │  │   Notifiers  │  │     State    │  │
│  │  (Riverpod)  │  │   (Logic)    │  │   (Models)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                  ▲          │
└─────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼──────────┐
│                     DOMAIN LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Use Cases  │  │   Services   │  │   Models     │  │
│  │  (Business)  │  │   (Logic)    │  │  (Entities)  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                  ▲          │
└─────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼──────────┐
│                       DATA LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Local DB    │  │   Cloud DB   │  │  External    │  │
│  │  (Drift)     │  │  (Supabase)  │  │   APIs       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                  ▲          │
└─────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │
     SQLite File      PostgreSQL (dos.supabase.co)    HTTP
```

---

## Database Architecture

### Local Database (Drift SQLite)

**Location**: Device storage (platform-specific)
**Purpose**: Primary data storage (with offline support)

#### Core Tables

```dart
// Wallets - User accounts (cash, bank, credit card)
table wallets {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE              // UUID v7 for cloud sync
  name: TEXT
  balance: REAL
  currency: TEXT
  walletType: INTEGER               // 0=cash, 1=bank, 2=credit
  creditLimit: REAL?
  billingDay: INTEGER?
  interestRate: REAL?
  isShared: BOOLEAN
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Transactions - Income/Expense/Transfer records
table transactions {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  walletId: INTEGER FK → wallets.id
  categoryId: INTEGER FK → categories.id
  amount: REAL
  title: TEXT
  notes: TEXT?
  date: DATETIME
  transactionType: INTEGER          // 0=income, 1=expense, 2=transfer
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Categories - Expense/Income categories
table categories {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  title: TEXT
  icon: TEXT
  iconBackground: TEXT
  iconTypeValue: INTEGER
  source: TEXT                      // 'built-in' or 'custom'
  builtInId: TEXT?                  // Reference to built-in template (e.g., 'food')
  hasBeenModified: BOOLEAN          // Track if user modified built-in
  isDeleted: BOOLEAN                // Soft delete flag
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Budgets - Monthly budget limits per category
table budgets {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  walletId: INTEGER FK
  categoryId: INTEGER FK
  amount: REAL
  period: TEXT                      // monthly, weekly, etc.
  startDate: DATE
  endDate: DATE?
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Goals - Savings goals
table goals {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  walletId: INTEGER FK
  name: TEXT
  targetAmount: REAL
  currentAmount: REAL
  deadline: DATE?
  isPinned: BOOLEAN
  isDeleted: BOOLEAN DEFAULT FALSE  // Soft delete (Tombstone pattern)
  deletedAt: DATETIME?               // Deletion timestamp
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Recurring Transactions - Auto-recurring payments
table recurrings {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  walletId: INTEGER FK
  categoryId: INTEGER FK
  amount: REAL
  title: TEXT
  frequency: TEXT                   // daily, weekly, monthly, yearly
  nextDate: DATE
  isActive: BOOLEAN
  createdAt: DATETIME
  updatedAt: DATETIME
}

// Chat Messages - AI assistant conversation
table chat_messages {
  id: INTEGER PRIMARY KEY
  messageId: TEXT UNIQUE
  content: TEXT
  isFromUser: BOOLEAN
  timestamp: DATETIME
  error: TEXT?
  createdAt: DATETIME
}

// Parsed Email Transactions - Gmail-parsed transactions
table parsed_email_transactions {
  id: INTEGER PRIMARY KEY
  gmailMessageId: TEXT UNIQUE
  bankName: TEXT
  amount: REAL
  currency: TEXT
  transactionType: TEXT
  merchant: TEXT?
  transactionDate: DATETIME
  confidence: REAL                  // 0.0-1.0
  rawSubject: TEXT
  rawBody: TEXT
  status: TEXT                      // pending, approved, rejected
  createdAt: DATETIME
}
```

#### DAO Pattern

Each table has a dedicated DAO (Data Access Object):

```dart
// Example: WalletDao
class WalletDao extends DatabaseAccessor<AppDatabase> {
  // CRUD operations
  Future<List<Wallet>> getAllWallets()
  Future<Wallet?> getWalletById(int id)
  Future<Wallet?> getWalletByCloudId(String cloudId)
  Future<int> createWallet(WalletCompanion wallet)
  Future<void> updateWallet(WalletCompanion wallet)
  Future<void> deleteWallet(int id)

  // Sync operations
  Future<void> createOrUpdateWallet(WalletModel model)  // From cloud

  // Streams for reactive UI
  Stream<List<Wallet>> watchAllWallets()
  Stream<Wallet?> watchWallet(int id)
}
```

#### Tombstone Pattern (Soft Delete)

**Purpose**: Prevent "resurrection" bug where deleted items reappear from cloud after failed sync

**Implemented in**: Goals table (as of 2026-01-26)

**Future Implementation**: Transaction, Budget, Recurring tables (high priority)

##### Problem Statement

```
Timeline of the Bug:
1. User deletes goal (id=5, cloudId=abc123)
2. Local delete: ✅ SUCCESS (hard delete from SQLite)
3. Cloud delete: ❌ FAIL (network timeout)
4. 1 hour later, app pulls from cloud
5. Cloud still has goal abc123 → Item "resurrects" 👻
```

##### Solution: Tombstone Pattern

Instead of hard deleting records, mark them as deleted with `is_deleted` flag:

**Schema Changes**:
```dart
table goals {
  id: INTEGER PRIMARY KEY
  cloudId: TEXT UNIQUE
  // ... other fields ...
  isDeleted: BOOLEAN DEFAULT FALSE  // ✅ Soft delete flag
  deletedAt: DATETIME?               // ✅ Timestamp of deletion
}
```

**Delete Operation** (Instant UX + Eventually Consistent):
```dart
Future<int> deleteGoal(int id) async {
  final goal = await getGoalById(id);

  // 1. SOFT DELETE - Mark as deleted (instant UX)
  final count = await (update(goals)..where((g) => g.id.equals(id)))
    .write(GoalsCompanion(
      isDeleted: Value(true),
      deletedAt: Value(DateTime.now()),
    ));

  // 2. Cloud delete (fire and forget, don't block user)
  if (count > 0 && goal?.cloudId != null) {
    try {
      await syncService.deleteGoalFromCloud(goal.cloudId!);
    } catch (e) {
      // Don't rethrow - local soft delete succeeded
      // Will retry on next sync
    }
  }

  return count;
}
```

**Query Filtering** (All queries exclude soft-deleted):
```dart
Stream<List<Goal>> watchAllGoals() {
  return (select(goals)
    ..where((g) => g.isDeleted.equals(false)) // ✅ Filter deleted
  ).watch();
}

Future<Goal?> getGoalById(int id) {
  return (select(goals)
    ..where((g) => g.id.equals(id))
    ..where((g) => g.isDeleted.equals(false)) // ✅ Filter deleted
  ).getSingleOrNull();
}
```

**Restore Operation** (Undo delete):
```dart
Future<int> restoreGoal(int id) async {
  return await (update(goals)..where((g) => g.id.equals(id)))
    .write(GoalsCompanion(
      isDeleted: Value(false),
      deletedAt: Value(null),
    ));
}
```

**Cleanup Operation** (Remove old tombstones):
```dart
Future<int> cleanupDeletedGoals({int daysOld = 30}) async {
  final threshold = DateTime.now().subtract(Duration(days: daysOld));

  return await (delete(goals)
    ..where((g) => g.isDeleted.equals(true))
    ..where((g) => g.deletedAt.isSmallerThanValue(threshold))
  ).go();
}
```

##### Benefits

✅ **Instant UX**: Delete happens immediately, no waiting for network
✅ **Offline Support**: Works without internet connection
✅ **No Resurrection**: Soft-deleted items won't reappear from cloud
✅ **Undo Capability**: Can restore recently deleted items (within 30 days)
✅ **Eventually Consistent**: Cloud sync happens in background with retry
✅ **Industry Standard**: Used by Firebase, Realm, PouchDB, Notion

##### Trade-offs

⚠️ **Database Size**: Deleted items remain in DB (mitigated by periodic cleanup)
⚠️ **Query Overhead**: All queries must filter `isDeleted=false` (minimal impact)
⚠️ **Schema Migration**: Requires adding `isDeleted` and `deletedAt` columns

##### Implementation Status

| Table | Status | Priority | Notes |
|-------|--------|----------|-------|
| **Goals** | ✅ Implemented | High | Fixed resurrection bug (2026-01-26) |
| **Transactions** | 🔲 Planned | High | Most frequently deleted |
| **Budgets** | 🔲 Planned | High | Deleted often at period end |
| **Recurring** | 🔲 Planned | Medium | Moderate delete frequency |
| **Wallets** | ⏸️ Low Priority | Low | Rare deletion, has constraints |
| **Categories** | ⏸️ Low Priority | Low | Built-in, rarely deleted |

##### Code Files

- Schema: [lib/core/database/tables/goal_table.dart](../lib/core/database/tables/goal_table.dart)
- DAO: [lib/core/database/daos/goal_dao.dart](../lib/core/database/daos/goal_dao.dart)
- Model: [lib/features/goal/data/model/goal_model.dart](../lib/features/goal/data/model/goal_model.dart)

##### References

- **Firebase Firestore**: Uses `deleted` flag in documents
- **Realm**: Implements "Tombstone Objects" for sync
- **PouchDB/CouchDB**: `_deleted: true` for conflict resolution
- **Apple Notes**: "Recently Deleted" folder (30-day retention)
- **Google Drive**: Trash with auto-delete after 30 days

---

### Cloud Database (Supabase PostgreSQL)

**Location**: `bexly` schema in DOS Supabase (`https://dos.supabase.co`)
**Project ID**: `gulptwduchsjcsbndmua`
**Purpose**: Cloud sync, multi-device, backup

**CRITICAL**: All tables are in `bexly` schema, NOT `public` schema!
- ✅ Query: `.from('bexly.wallets')`
- ❌ WRONG: `.from('wallets')` → searches `public.wallets` (doesn't exist)

#### Schema: `bexly`

```sql
-- Wallets table (mirrors local structure)
CREATE TABLE bexly.wallets (
  cloud_id UUID PRIMARY KEY,        -- UUID v7 (time-ordered)
  user_id UUID NOT NULL,            -- Supabase auth.users.id (NOT DOS-Me ID)
  name TEXT NOT NULL,
  balance NUMERIC(20, 2) DEFAULT 0,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  wallet_type TEXT,                 -- 'cash', 'bank', 'credit_card'
  credit_limit NUMERIC(20, 2),
  billing_date INTEGER,
  interest_rate NUMERIC(5, 2),
  is_shared BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  linked_bank_account_id UUID,     -- FK to bank accounts
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,

  -- Foreign key to DOS-Me profiles table (unified user system)
  CONSTRAINT fk_wallets_user
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(user_id)  -- Links to Supabase auth
    ON DELETE CASCADE
);

-- Transactions table
CREATE TABLE bexly.transactions (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,            -- Supabase auth.users.id
  wallet_id UUID,                   -- References bexly.wallets.cloud_id
  category_id UUID,                 -- References bexly.categories.cloud_id
  bank_transaction_id UUID,        -- References bank_transactions
  transaction_type TEXT,            -- 'income', 'expense', 'transfer'
  amount NUMERIC(20, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  description TEXT,                 -- Transaction title/description
  notes TEXT,
  transaction_date TIMESTAMP NOT NULL,  -- When transaction occurred
  to_wallet_id UUID,               -- For transfers
  linked_transaction_id UUID,      -- Link transfer pairs
  recurring_id UUID,               -- If from recurring payment
  parsed_from_email BOOLEAN DEFAULT FALSE,
  email_id TEXT,                   -- Gmail message ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,

  CONSTRAINT fk_transactions_user
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(user_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_transactions_wallet
    FOREIGN KEY (wallet_id)
    REFERENCES bexly.wallets(cloud_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_transactions_category
    FOREIGN KEY (category_id)
    REFERENCES bexly.categories(cloud_id)
    ON DELETE SET NULL
);

-- Categories table
CREATE TABLE bexly.categories (
  cloud_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,           -- Supabase auth.users.id
  name TEXT NOT NULL,
  icon TEXT,                       -- Icon name/code
  color TEXT,                      -- Hex color (renamed from icon_background)
  category_type TEXT,              -- 'income' or 'expense'
  source TEXT DEFAULT 'built-in',  -- 'built-in' or 'custom'
  built_in_id TEXT,                -- Reference to built-in template (e.g., 'food')
  has_been_modified BOOLEAN DEFAULT FALSE,  -- Track modifications
  is_deleted BOOLEAN DEFAULT FALSE,  -- Soft delete support
  is_default BOOLEAN DEFAULT FALSE,  -- Deprecated: use source='built-in'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,

  CONSTRAINT fk_categories_user
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(user_id)
    ON DELETE CASCADE,

  CHECK (source IN ('built-in', 'custom'))
);

-- Chat messages table
CREATE TABLE bexly.chat_messages (
  cloud_id UUID PRIMARY KEY,      -- Changed from message_id for consistency
  user_id UUID NOT NULL,          -- Supabase auth.users.id
  conversation_id UUID NOT NULL,  -- Group messages by conversation
  role TEXT NOT NULL,             -- 'user' or 'assistant'
  content TEXT NOT NULL,
  related_transaction_id UUID,    -- Link to transaction if action performed
  related_budget_id UUID,
  related_goal_id UUID,
  related_category_id UUID,
  metadata JSONB DEFAULT '{}',    -- Extra data (AI model, tokens, etc.)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_chat_messages_user
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(user_id)
    ON DELETE CASCADE
);

-- ... other tables (budgets, goals, recurring_transactions, etc.)
-- See full migration: BEXLY_MIGRATION_READY_TO_RUN.sql
```

**Schema Query Pattern** (CRITICAL):
```dart
// ✅ CORRECT: Always specify bexly schema
await supabase.from('bexly.wallets').select();
await supabase.from('bexly.transactions').select();
await supabase.from('bexly.categories').select();

// ❌ WRONG: Defaults to public schema (tables don't exist there)
await supabase.from('wallets').select();  // ERROR: relation "public.wallets" does not exist
```

**Common Pitfall**:
- Forgetting to specify `bexly.` prefix causes `relation does not exist` errors
- Supabase client defaults to `public` schema if no schema specified
- All Bexly data lives in `bexly` schema, NOT `public`
- `public` schema only has DOS-Me infrastructure (profiles, auth_providers, etc.)

#### Row Level Security (RLS)

All tables have RLS policies to ensure users only access their own data:

```sql
-- Enable RLS
ALTER TABLE bexly.wallets ENABLE ROW LEVEL SECURITY;

-- Users can only access their own wallets
CREATE POLICY "Users can manage own wallets"
  ON bexly.wallets FOR ALL
  USING (
    user_id = (current_setting('request.jwt.claims', true)::json->>'dosme_user_id')::text
  )
  WITH CHECK (
    user_id = (current_setting('request.jwt.claims', true)::json->>'dosme_user_id')::text
  );
```

#### Indexes for Performance

```sql
-- Wallets indexes
CREATE INDEX idx_bexly_wallets_user ON bexly.wallets(user_id) WHERE is_active = true;
CREATE INDEX idx_bexly_wallets_cloud_id ON bexly.wallets(cloud_id);

-- Transactions indexes
CREATE INDEX idx_bexly_transactions_user_date ON bexly.transactions(user_id, date DESC);
CREATE INDEX idx_bexly_transactions_wallet ON bexly.transactions(wallet_id);
CREATE INDEX idx_bexly_transactions_category ON bexly.transactions(category_id);

-- Chat messages indexes
CREATE INDEX idx_bexly_chat_user_time ON bexly.chat_messages(user_id, timestamp DESC);
```

#### Realtime Subscriptions

Tables enabled for Supabase Realtime (PostgreSQL CDC):

```sql
-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.wallets;
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE bexly.chat_messages;
```

---

## Category Sync Strategy - Modified Hybrid Approach with Initial Sync

### Overview

**Problem**: Full sync creates 76 categories per user on cloud = 76M records for 1M users (huge storage waste!)

**Solution**: **Modified Hybrid Sync with Initial Sync** - Sync ALL categories once on first login, then only sync modified/custom

**Why Initial Sync is Required**:
- Transactions have FK constraints to categories
- Uploading transactions requires categories to exist on cloud first
- Without initial sync, first transaction upload fails with FK violation
- One-time 50KB upload (100 categories × 500 bytes) is acceptable overhead

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│          CATEGORY SYNC - MODIFIED HYBRID + INITIAL           │
└─────────────────────────────────────────────────────────────┘

FIRST LOGIN (Initial Sync):
  1. User logs in for the first time
  2. App checks: cloud has any categories for this user?
  3. If NO → Upload ALL 100 built-in categories to cloud
  4. Ensures FK constraints satisfied for transactions
  5. One-time cost: ~50KB (100 × 500 bytes)

SUBSEQUENT USAGE (Modified Hybrid Sync):
  - Built-in categories already on cloud
  - Only sync when user modifies built-in OR creates custom
  - 90-97% reduction in ongoing sync volume

BUILT-IN CATEGORIES (100 templates):
  - Stored locally on each device
  - Synced to cloud ONCE on first login
  - NOT synced again unless modified
  - Examples: "Food & Drinks", "Transport", "Shopping"

USER MODIFICATIONS:
  - User edits icon: 🍽️ → 🍕
  - Mark: has_been_modified = TRUE
  - Sync to cloud: { source: 'built-in', built_in_id: 'food', ... }

CUSTOM CATEGORIES:
  - User creates new: "Crypto Trading"
  - Mark: source = 'custom'
  - Sync to cloud immediately

CLOUD STORAGE (After Initial + Modifications):
  - Initial: 100 built-in categories (~50KB one-time)
  - Ongoing: Only modified built-ins (avg: 3-5 per user)
  - Ongoing: Only custom categories (avg: 2-3 per user)
  - Total ongoing: ~5-8 categories/user synced after initial
  - **Initial overhead: 50KB, then 90% reduction in ongoing sync!**
```

### Schema Fields

**Key Tracking Fields**:

```dart
class CategoryModel {
  // Existing fields
  String cloudId;
  String title;
  String icon;
  String iconBackground;

  // NEW: Sync strategy fields
  String source;            // 'built-in' or 'custom'
  String? builtInId;        // 'food', 'transport', etc. (stable ID)
  bool hasBeenModified;     // Track if user modified built-in
  bool isDeleted;           // Soft delete (sync deletion)
}
```

**Field Usage**:
- `source`: Identifies category origin ('built-in' from templates, 'custom' user-created)
- `builtInId`: Stable reference to built-in template (survives app updates)
- `hasBeenModified`: Flag for sync (TRUE = upload to cloud)
- `isDeleted`: Soft delete instead of hard delete (sync across devices)

### Sync Logic

#### Device 1: User Modifies Built-in Category

```dart
// User changes "Food" icon from 🍽️ → 🍕
Future<void> updateCategory(CategoryModel category) async {
  // 1. Check if it's a built-in category
  if (category.source == 'built-in') {
    // 2. Mark as modified
    category = category.copyWith(hasBeenModified: true);
  }

  // 3. Update local DB
  await db.categoryDao.updateCategory(category);

  // 4. Sync to cloud (fire and forget)
  if (category.hasBeenModified || category.source == 'custom') {
    await syncService.uploadCategory(category);
  }
}
```

#### Device 2 (New): Populate Categories

```dart
Future<void> initializeCategoriesOnNewDevice() async {
  print('📱 New device - initializing categories...');

  // 1. Query cloud: Get modified built-ins + custom categories
  final cloudCategories = await supabase
    .from('categories')
    .select('*')
    .eq('user_id', userId)
    .eq('is_deleted', false);

  // 2. Extract built_in_id of modified categories
  final modifiedBuiltInIds = cloudCategories
    .where((c) => c['source'] == 'built-in' && c['has_been_modified'] == true)
    .map((c) => c['built_in_id'] as String)
    .toSet();

  print('⏭️  Skip ${modifiedBuiltInIds.length} modified built-ins');

  // 3. Populate built-in categories (SKIP modified ones)
  int populated = 0;
  for (final builtIn in builtInCategories) { // 76 templates
    if (modifiedBuiltInIds.contains(builtIn.builtInId)) {
      continue; // ✅ Skip - user has custom version in cloud
    }

    await db.categoryDao.addCategory(builtIn);
    populated++;
  }

  print('✅ Populated $populated unmodified built-ins');

  // 4. Insert modified + custom from cloud
  for (final cloudCat in cloudCategories) {
    await db.categoryDao.addCategory(
      CategoryModel.fromJson(cloudCat),
    );
  }

  print('📥 Inserted ${cloudCategories.length} from cloud');
}
```

#### Sync Service: Initial Sync + Modified Hybrid

```dart
Future<void> syncCategoriesToCloud() async {
  if (_userId == null) {
    Log.w('Cannot sync categories: user not authenticated', label: _label);
    return;
  }

  try {
    final db = _ref.read(databaseProvider);
    final allCategories = await db.categoryDao.getAllCategories();

    // Check if cloud has any categories (initial sync check)
    final cloudCategoriesResponse = await _supabase
        .schema('bexly')
        .from('categories')
        .select('cloud_id')
        .eq('user_id', _userId!)
        .limit(1);

    final hasCloudCategories = (cloudCategoriesResponse as List).isNotEmpty;

    List<dynamic> categoriesToSync;

    if (!hasCloudCategories) {
      // ✅ INITIAL SYNC: Upload ALL categories once
      categoriesToSync = allCategories;
      Log.d('Initial sync: Syncing ALL ${allCategories.length} categories to Supabase...', label: _label);
    } else {
      // ✅ MODIFIED HYBRID SYNC: Only sync custom OR modified built-ins
      categoriesToSync = allCategories.where((category) {
        return category.source == 'custom' ||
               (category.source == 'built-in' && category.hasBeenModified == true);
      }).toList();

      Log.d('Syncing ${categoriesToSync.length}/${allCategories.length} categories (Modified Hybrid)', label: _label);
    }

    // Upload categories to cloud
    for (final category in categoriesToSync) {
      await _upsertCategory(category);
    }

    final savedCount = allCategories.length - categoriesToSync.length;
    Log.i('Categories synced successfully${savedCount > 0 ? " (saved $savedCount unmodified built-ins from re-sync)" : ""}', label: _label);
  } catch (e, stackTrace) {
    Log.e('Error syncing categories: $e', label: _label);
    rethrow;
  }
}
```

**Triggered by**: `LifecycleManager` on app startup (ensures categories exist before transactions sync)

### Edge Cases Handled

#### 1. App Update - New Built-in Categories

```dart
// v1.0 → v2.0: Added 4 new built-in categories
Future<void> onAppUpdate() async {
  final existing = await db.categoryDao.getAllBuiltInIds();

  for (final builtIn in builtInCategories) { // 80 in v2.0
    if (existing.contains(builtIn.builtInId)) {
      continue; // Already exists (modified or not)
    }

    // Add new built-in (local only)
    await db.categoryDao.addCategory(builtIn.copyWith(
      source: 'built-in',
      hasBeenModified: false,
    ));
  }
}
```

#### 2. Soft Delete - Sync Deletion Across Devices

```dart
Future<void> deleteCategory(String categoryId) async {
  final category = await db.categoryDao.getCategoryById(categoryId);

  // Soft delete (set flag)
  await db.categoryDao.updateCategory(
    category.copyWith(
      isDeleted: true,
      hasBeenModified: true, // ✅ Trigger sync
    ),
  );

  // Sync deletion to cloud
  await supabase.from('categories').upsert({
    'cloud_id': categoryId,
    'is_deleted': true,
  });
}

// Query: Filter out deleted
Stream<List<CategoryModel>> watchCategories() {
  return (select(categories)
    ..where((c) => c.isDeleted.equals(false)))
    .watch();
}
```

#### 3. Conflict Resolution - Last-Write-Wins

```dart
Future<void> resolveConflict(
  CategoryModel local,
  CategoryModel cloud,
) async {
  if (cloud.updatedAt.isAfter(local.updatedAt)) {
    // Cloud newer → Update local
    await db.categoryDao.updateCategory(cloud);
  } else {
    // Local newer → Upload to cloud
    await syncService.uploadCategory(local);
  }
}
```

#### 4. Restore to Default

```dart
Future<void> restoreToDefault(String categoryId) async {
  final category = await db.categoryDao.getCategoryById(categoryId);

  if (category.source != 'built-in') {
    throw Exception('Can only restore built-in categories');
  }

  // Find original template
  final original = builtInCategories.firstWhere(
    (c) => c.builtInId == category.builtInId,
  );

  // Restore to default values
  await db.categoryDao.updateCategory(
    category.copyWith(
      icon: original.icon,
      iconBackground: original.iconBackground,
      hasBeenModified: false, // ✅ No longer modified
    ),
  );

  // Delete from cloud (no need to sync unmodified built-in)
  await supabase
    .from('categories')
    .delete()
    .eq('cloud_id', category.cloudId);
}
```

### Storage Comparison (Updated with Initial Sync)

| Scale | Full Sync (Always) | Modified Hybrid + Initial | Savings |
|-------|-------------------|---------------------------|---------|
| **10K users** | 1M records<br>~200 MB | Initial: 1M (~200 MB)<br>Ongoing: 50K (~10 MB/month) | **Initial: 0%**<br>**Ongoing: -95%** |
| **100K users** | 10M records<br>~2 GB | Initial: 10M (~2 GB)<br>Ongoing: 500K (~100 MB/month) | **Initial: 0%**<br>**Ongoing: -95%** |
| **1M users** | 100M records<br>~20 GB | Initial: 100M (~20 GB)<br>Ongoing: 5M (~1 GB/month) | **Initial: 0%**<br>**Ongoing: -95%** |

**Key Insight**:
- **Initial sync** = Same as full sync (one-time 20GB for 1M users)
- **Ongoing sync** = 95% reduction (only 5% of categories modified/custom)
- **Trade-off**: One-time full upload for data integrity, massive ongoing savings

**Why This is Better**:
1. ✅ **Guarantees data integrity** - No FK violations for transactions
2. ✅ **Simple implementation** - No complex dependency resolution
3. ✅ **95% ongoing reduction** - Only sync what changes after initial
4. ✅ **Scalable** - 50KB per user one-time is acceptable
5. ✅ **Works offline** - Local categories always available

**Assumptions** (Realistic):
- Initial: 100% users get 100 categories (~50KB each)
- Ongoing: Only 5% of categories are modified or custom
- **1M users = 100M initial + 5M ongoing (-95% after initial)**

### Benefits

✅ **Data integrity guaranteed** → All transactions sync without FK errors
✅ **95% ongoing storage reduction** → Massive cost savings after initial sync
✅ **Perfect cross-device sync** → User modifications preserved
✅ **Simple implementation** → No complex dependency resolution
✅ **Lower ongoing bandwidth** → Only sync changes after initial
✅ **Scalable** → Ready for millions of users (50KB/user acceptable)
✅ **Restore capability** → User can revert to defaults

### Trade-offs

🟡 **One-time full upload** → 50KB per user on first login (acceptable)
🟡 **Initial sync cost** → Same as full sync, but only once
🟡 **Medium complexity** → Need to track modifications
🟡 **Migration required** → Convert existing sync data (if any)
🟡 **Built-in management** → Handle app updates carefully

**Verdict**: Initial sync overhead is WORTH IT for data integrity + 95% ongoing savings! ✅

### Implementation Status

✅ **Implemented in**: `lib/core/services/sync/supabase_sync_service.dart:466-552`
✅ **Triggered by**: `lib/core/services/lifecycle_manager.dart:75-103` (on app startup)
✅ **Status**: Active (January 2026)

---

## Authentication & Sync

### Authentication Architecture

```
┌──────────────────────────────────────────────────────┐
│                   USER AUTH FLOW                      │
└──────────────────────────────────────────────────────┘

Login Method → Supabase Auth → JWT Token → DOS-Me API
     ↓              ↓              ↓            ↓
  - Email      Generate      Store in     Validate
  - Google     JWT with      Secure       & Link
  - Facebook   user_id       Storage      User
  - Apple
                                ↓
                        Update Local State
                                ↓
                        Trigger Initial Sync
                                ↓
                        Navigate to Dashboard
```

#### Supabase Auth (Primary)

**Provider**: DOS Supabase (`https://dos.supabase.co`)
**Project ID**: `gulptwduchsjcsbndmua`

**Supported Methods**:
1. **Email/Password**: Native Supabase auth
2. **Google OAuth**: Configured with Google Cloud Console
3. **Facebook OAuth**: Configured with Facebook App
4. **Apple Sign-In**: Configured with Apple Developer

**Configuration**:
- OAuth Redirect URL: `bexly://login-callback`
- Session persistence: Enabled
- JWT expiry: 3600s (1 hour)
- Refresh token rotation: Enabled

**Code Implementation**:

```dart
// lib/core/services/supabase_init_service.dart
class SupabaseInitService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
}

// Sign in with email/password
final result = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign in with Google OAuth
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'bexly://login-callback',
);
```

#### User Profile Management

**Approach**: Local auth state as source of truth

**Data Sources**:
1. **Local Auth State** (`authStateProvider`): Source of truth
   - User name, email, profile picture
   - Persisted in SharedPreferences
   - Used for all UI displays

2. **Supabase User Metadata**: Backup/sync only
   - Synced from local when user updates profile
   - Used to populate local on first login (if empty)
   - NOT used directly for UI display

**Profile Update Flow**:
```dart
// When user updates profile in Personal Details screen:
// 1. Update local FIRST (instant feedback)
final updatedUser = localAuth.copyWith(name: newName);
authProvider.setUser(updatedUser);  // ✅ UI updates immediately

// 2. Sync to Supabase in background (fire and forget)
if (supabaseAuth.isAuthenticated) {
  try {
    await supabase.auth.updateProfile(fullName: newName);
    Log.i('Synced to Supabase');
  } catch (e) {
    Log.w('Sync failed: $e');
    // Don't show error - local update succeeded
  }
}
```

**Login Flow (Google Sign-In)**:
```dart
// After successful Google OAuth:
// 1. Get Supabase user metadata (from Google profile)
final supabaseUser = response.user;
final googleName = supabaseUser.userMetadata?['full_name'];  // "Anh Le"

// 2. Only update local if empty (preserve existing data)
final currentUser = authProvider.getUser();
authProvider.setUser(currentUser.copyWith(
  name: currentUser.name.isEmpty ? googleName : currentUser.name,
  email: supabaseUser.email,  // Always update email
));

// ✅ Result: Keeps user's custom name ("JOY"), doesn't overwrite
```

**Why This Approach?**:
- **Instant UI**: No waiting for cloud sync
- **Offline Support**: Profile works without internet
- **User Control**: Local edits not overwritten by cloud
- **Consistency**: Same data across all screens (Settings, Personal Details)

#### Firebase (Legacy - FCM Only)

**Still Used For**:
- Firebase Cloud Messaging (push notifications)
- Firebase Analytics (app analytics)
- Firebase Crashlytics (crash reporting)

**NOT Used For**:
- ❌ Authentication (migrated to Supabase)
- ❌ Firestore (migrated to Supabase PostgreSQL)

### Sync Architecture

**Approach**: Local-first with background cloud sync

```
┌──────────────────────────────────────────────────────┐
│          DATA FLOW (LOCAL → CLOUD SYNC)              │
└──────────────────────────────────────────────────────┘

User Action (Create/Update/Delete)
    ↓
1. Write to Local SQLite (Drift) FIRST ✅
    ↓
2. Update UI Immediately (instant feedback)
    ↓
3. Show success toast to user
    ↓
4. Sync to Supabase in background (fire and forget)
    ↓
┌─────────────────────────────────────────┐
│ BACKGROUND SYNC:                        │
│   IF AUTHENTICATED:                     │
│     → Upload to Supabase PostgreSQL     │
│     → Success: Log sync                 │
│     → Failure: Log warning, don't       │
│                notify user (local       │
│                update succeeded)        │
│                                         │
│   IF OFFLINE:                           │
│     → Skip sync, retry when online      │
└─────────────────────────────────────────┘
    ↓
CONFLICT RESOLUTION (when pulling from cloud):
    → Compare timestamps (updated_at)
    → Last-write-wins (LWW)
    → Update local if cloud is newer
```

**Key Points**:
- **Local = Source of Truth**: All reads from local SQLite
- **Instant Feedback**: UI updates before cloud sync
- **Background Sync**: Non-blocking, fire-and-forget
- **Offline Support**: App works fully offline, syncs when connected
- **No Forced Sync**: User never waits for cloud sync to complete

#### Sync Service

**File**: `lib/core/services/sync/supabase_sync_service.dart`

```dart
class SupabaseSyncService {
  // Check auth status
  bool get isAuthenticated;
  String? get userId;

  // Wallet sync
  Future<void> uploadWallet(WalletModel wallet);
  Future<void> pullWalletsFromCloud(WalletDao dao);

  // Transaction sync
  Future<void> uploadTransaction(Transaction transaction);
  Future<void> pullTransactionsFromCloud(TransactionDao dao);

  // Category sync
  Future<void> uploadCategory(Category category);
  Future<void> pullCategoriesFromCloud(CategoryDao dao);

  // Chat message sync
  Future<void> uploadChatMessage(ChatMessage message);
  Future<void> pullChatMessagesFromCloud(ChatMessageDao dao);

  // Batch sync
  Future<void> syncWalletsToCloud(List<WalletModel> wallets);
  Future<void> syncTransactionsToCloud(List<Transaction> transactions);
  Future<void> syncChatMessagesToCloud(List<ChatMessage> messages);

  // Realtime subscriptions
  RealtimeChannel subscribeToWallets(Function(Map) onUpdate);
  RealtimeChannel subscribeToTransactions(Function(Map) onUpdate);
  RealtimeChannel subscribeToChatMessages(Function(Map) onUpdate);
}
```

#### Conflict Resolution

**Strategy**: Last-Write-Wins (LWW) using `updated_at` timestamps

```dart
// When pulling from cloud
Future<void> _resolveConflict(
  LocalRecord local,
  CloudRecord cloud,
) async {
  // Compare timestamps
  if (cloud.updatedAt.isAfter(local.updatedAt)) {
    // Cloud is newer → Update local
    await _updateLocal(cloud);
    Log.i('Resolved conflict: Cloud wins');
  } else {
    // Local is newer → Upload to cloud
    await _uploadToCloud(local);
    Log.i('Resolved conflict: Local wins');
  }
}
```

#### Sync Triggers

**When sync happens**:
1. **On Login**: Initial sync pulls all data from cloud
2. **On Create/Update/Delete**: Auto-sync in background
3. **On Network Change**: Retry failed syncs when back online
4. **Manual Trigger**: Pull-to-refresh on dashboard
5. **Periodic**: Every 5 minutes if online (optional)

**Sync Priority**:
1. Wallets (highest - affects balance)
2. Transactions
3. Categories
4. Budgets & Goals
5. Chat Messages (lowest - local-first feature)

---

## Feature Modules

### Module Structure

```
lib/features/
├── wallet/                    # Wallet management
│   ├── data/
│   │   ├── models/
│   │   │   └── wallet_model.dart
│   │   └── services/
│   ├── domain/
│   │   └── enums/
│   │       └── wallet_type.dart
│   └── presentation/
│       ├── screens/
│       ├── widgets/
│       └── riverpod/
│           └── wallet_providers.dart
│
├── transaction/               # Transaction tracking
│   ├── data/
│   ├── domain/
│   └── presentation/
│
├── budget/                    # Budget management
│   ├── data/
│   ├── domain/
│   └── presentation/
│
├── ai_chat/                   # AI assistant
│   ├── data/
│   │   ├── services/
│   │   │   ├── ai_service.dart         # Abstract interface
│   │   │   ├── gemini_service.dart     # Google Gemini
│   │   │   ├── openai_service.dart     # OpenAI GPT-4
│   │   │   └── speech_service.dart     # Voice input
│   │   └── config/
│   │       └── ai_prompts.dart         # System prompts
│   ├── domain/
│   │   └── models/
│   │       └── chat_message.dart
│   └── presentation/
│       ├── screens/
│       │   └── ai_chat_screen.dart
│       └── riverpod/
│           ├── chat_provider.dart
│           └── chat_dao_provider.dart
│
├── email_sync/                # Gmail integration
│   ├── data/
│   │   └── services/
│   │       ├── gmail_auth_service.dart
│   │       └── gmail_sync_service.dart
│   ├── domain/
│   │   └── services/
│   │       ├── email_parser_service.dart
│   │       └── transaction_extractor_service.dart
│   └── presentation/
│
├── bank_connections/          # Plaid bank linking
│   ├── data/
│   ├── domain/
│   └── presentation/
│
├── settings/                  # App settings
│   ├── data/
│   ├── domain/
│   └── presentation/
│
└── auth/                      # Authentication UI
    ├── presentation/
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── forgot_password_screen.dart
    └── riverpod/
```

### Core Feature: AI Chat Assistant

**Purpose**: Natural language expense tracking via chat

**Flow**:
```
User: "Tao vừa ăn sáng 50k"
  ↓
AI Service (Gemini/OpenAI)
  ↓
Parse: {
  amount: 50000,
  category: "Food & Drinks",
  type: "expense",
  wallet: "My Wallet"
}
  ↓
Show Confirmation Buttons
  ↓
User Confirms
  ↓
Create Transaction in Local DB
  ↓
Sync to Supabase
  ↓
Update UI + Show Success
```

**AI Service Selection**:
1. **Primary**: Google Gemini Flash (fast, cheap)
2. **Fallback**: OpenAI GPT-4o-mini
3. **Optional**: Anthropic Claude Sonnet

**Transaction Parsing**:
- Amount detection (supports VND, USD, EUR, etc.)
- Category matching (fuzzy search in 76 default categories)
- Wallet detection (if multiple wallets)
- Date/time extraction
- Recurring pattern detection

### Core Feature: Email Sync

**Purpose**: Auto-import bank transactions from Gmail

**Supported Banks** (Vietnam):
- VCB (Vietcombank)
- Vietinbank
- Techcombank
- MB Bank
- ACB
- VPBank
- TPBank
- ... and more

**Flow**:
```
1. User connects Gmail via OAuth
2. App scans inbox for bank notification emails
3. Parse email content:
   - Transaction amount
   - Merchant name
   - Date/time
   - Account balance
4. Extract using AI (Gemini Vision)
5. Show in Review screen
6. User approves/rejects
7. If approved → Create transaction
```

**Parsing Algorithm**:
1. Check email subject/sender for bank keywords
2. Extract structured data from email body
3. Use AI to parse unstructured text
4. Confidence score (0.0-1.0)
5. If confidence < 0.7 → Flag for manual review

### Core Feature: Telegram Bot Integration

**Purpose**: Link Telegram account to Bexly for bot-based expense tracking via chat

**Bot**: `@BexlyBot` on Telegram

**Architecture**: Deep link flow with manual code fallback for maximum compatibility

#### User Flow

```
┌─────────────────────────────────────────────────────────────┐
│              TELEGRAM BOT LINKING FLOW                       │
└─────────────────────────────────────────────────────────────┘

Option 1: DEEP LINK FLOW (Primary - Mobile)
───────────────────────────────────────────────
1. User: Open Bexly → Settings → Bot Integration
2. User: Tap "Open Telegram" button
3. App: Launch Telegram with pre-filled "/link" command
4. User: Send /link to @BexlyBot
5. Bot: Reply with:
   - 🔗 Deep Link Button (bexly://telegram/link?token=xxx)
   - 6-digit code (fallback: last 6 chars of token)
6. User: Tap deep link button
7. System: Open Bexly app via deep link
8. App: Auto-verify JWT token → Link account
9. App: Show success toast with telegram_id
10. Done ✅

Option 2: MANUAL CODE FLOW (Fallback - Desktop/Issues)
───────────────────────────────────────────────────────
1. User: Copy 6-digit code from bot message
2. User: Return to Bexly → Bot Integration screen
3. User: Paste code into input field
4. App: Verify code → Link account
5. Done ✅
```

#### Deep Link Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="bexly" android:host="telegram" android:pathPrefix="/link"/>
</intent-filter>
```

**URL Format**: `bexly://telegram/link?token=<JWT>`

**Route Handling** (`lib/core/router/settings_router.dart`):
```dart
GoRoute(
  path: Routes.telegramLink,  // '/telegram/link'
  builder: (context, state) {
    final token = state.uri.queryParameters['token'];
    return BotIntegrationScreenWrapper(telegramLinkToken: token);
  },
)
```

#### JWT Token Flow

**Token Generation** (in `telegram-webhook` Edge Function):
```typescript
// Generate JWT with telegram_id payload
async function generateLinkToken(telegramId: string): Promise<string> {
  const jwtSecret = Deno.env.get("TELEGRAM_JWT_SECRET")!;
  const payload = {
    telegram_id: telegramId,
    app: "bexly",
    bot_username: "BexlyBot",
    api_url: "https://dos.supabase.co/functions/v1/link-telegram",
    exp: Math.floor(Date.now() / 1000) + 600,  // 10 min expiry
  };

  const key = await crypto.subtle.importKey(...);
  return await create({ alg: "HS256", typ: "JWT" }, payload, key);
}
```

**Token Verification** (in `link-telegram` Edge Function):
```typescript
// Verify JWT and extract telegram_id
const jwtSecret = Deno.env.get("TELEGRAM_JWT_SECRET");
const key = await crypto.subtle.importKey(
  "raw",
  new TextEncoder().encode(jwtSecret),
  { name: "HMAC", hash: "SHA-256" },
  false,
  ["verify"],
);

const payload = await verify(token, key);
const telegram_id = payload.telegram_id as string;
```

**Client-Side Handling** (`lib/core/services/telegram_deep_link_handler.dart`):
```dart
static Future<String?> linkWithToken(String token) async {
  final supabase = SupabaseInitService.client;
  final session = supabase.auth.currentSession;

  // Call Edge Function with JWT token
  final response = await supabase.functions.invoke(
    'link-telegram',
    body: {'telegram_token': token},
    headers: {'Authorization': 'Bearer ${session.accessToken}'},
  );

  if (response.status == 200) {
    return response.data['telegram_id'] as String?;
  }
  return null;
}
```

#### Edge Functions

**Function 1: `telegram-webhook`** (884.5kB)
- **Purpose**: Handle Telegram bot commands
- **Triggers**: Webhook from Telegram API
- **Commands**:
  - `/start` - Welcome message
  - `/link` - Generate deep link + 6-digit code
  - `/unlink` - Disconnect account with confirmation
- **Tech Stack**: Deno, djwt (JWT), Supabase client (jsr:@supabase/supabase-js@2)
- **Location**: `supabase/functions/telegram-webhook/index.ts`

**Function 2: `link-telegram`** (80kB)
- **Purpose**: Verify JWT token and create user_integrations record
- **Input**: `telegram_token` (JWT from deep link) OR `telegram_id` (manual)
- **Auth**: Requires Supabase JWT (user must be logged in)
- **Process**:
  1. Verify DOS-Me auth JWT (user identity)
  2. Verify Telegram JWT token (extract telegram_id)
  3. Check if telegram_id already linked (409 Conflict if yes)
  4. Insert into `bexly.user_integrations` table
- **Location**: `supabase/functions/link-telegram/index.ts`

**Deployment**:
```bash
# Using Supabase CLI with access token
SUPABASE_ACCESS_TOKEN=sbp_xxx supabase functions deploy telegram-webhook \
  --project-ref gulptwduchsjcsbndmua --no-verify-jwt

SUPABASE_ACCESS_TOKEN=sbp_xxx supabase functions deploy link-telegram \
  --project-ref gulptwduchsjcsbndmua --no-verify-jwt
```

#### Database Schema

**Table**: `bexly.user_integrations`

```sql
CREATE TABLE bexly.user_integrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,              -- Supabase auth.users.id
  platform TEXT NOT NULL,             -- 'telegram', 'whatsapp', etc.
  platform_user_id TEXT NOT NULL,     -- Telegram user ID (e.g., '8038733197')
  linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP,            -- Last bot interaction
  metadata JSONB DEFAULT '{}',        -- Extra data (username, etc.)

  CONSTRAINT fk_user_integrations_user
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(user_id)
    ON DELETE CASCADE,

  UNIQUE(platform, platform_user_id)  -- One Telegram account per user
);

-- Index for quick lookup
CREATE INDEX idx_user_integrations_platform
  ON bexly.user_integrations(platform, platform_user_id);
```

**Query Pattern**:
```dart
// Check if telegram_id is already linked
final existing = await supabase
  .from('user_integrations')
  .select('*')
  .eq('platform', 'telegram')
  .eq('platform_user_id', telegramId)
  .single();

if (existing != null) {
  // Already linked to another user
  throw ConflictException('This Telegram account is already linked');
}
```

#### Implementation Files

**Core Service** (`lib/core/services/telegram_deep_link_handler.dart`):
- Static method `linkWithToken(String token)`
- Calls `link-telegram` Edge Function
- Returns telegram_id on success, null on failure

**Screen Wrapper** (`lib/features/settings/presentation/screens/bot_integration_screen_wrapper.dart`):
- Wraps `BotIntegrationScreen`
- Auto-processes deep link token via `useEffect` hook
- Shows loading/success/error toasts
- Prevents duplicate processing with `hasProcessedToken` flag

**Routes** (`lib/core/router/routes.dart`):
```dart
static const String botIntegration = '/bot-integration';
static const String telegramLink = '/telegram/link';      // Deep link from bot
static const String telegramLinked = '/telegram/linked';  // Deprecated (web flow)
```

**Bot Integration Screen** (`lib/features/settings/presentation/screens/bot_integration_screen.dart`):
- "Open Telegram" button → `https://t.me/BexlyBot?text=/link`
- Manual code input field (6-digit)
- Link status display
- Unlink button

#### Security Considerations

1. **JWT Expiry**: Tokens expire in 10 minutes (600s)
2. **HTTPS Only**: All API calls over TLS
3. **CORS**: Configured for mobile app (`Access-Control-Allow-Origin: *`)
4. **RLS Policies**: User can only link to their own account
5. **Unique Constraint**: One Telegram account can only link to one Bexly user
6. **Auth Required**: Must be logged into Bexly before linking

#### Error Handling

**Common Errors**:
- `Invalid telegram_token` - Token expired or malformed
- `Unauthorized` - User not logged in to Bexly
- `Conflict 409` - Telegram account already linked to another user
- `Missing authorization header` - Auth token not provided

**User-Facing Messages**:
- Success: "Telegram account {telegram_id} linked successfully!"
- Failure: "Could not verify token. Please try manual code."
- Conflict: "This Telegram account is already linked to another user"

#### Manual Code Fallback

**Code Generation**:
```typescript
// Generate 6-digit code from JWT token
const code = linkToken.slice(-6).toUpperCase();
```

**Bot Message Format**:
```
🔗 Link your Bexly account

📱 Mobile: Tap the button below
⌨️ Manual: Code ABC123

(Open Bexly → Settings → Bot Integration → Enter code)

[🔗 Link Account] (deep link button)
```

**Future Enhancement**: Implement code verification endpoint for manual entry

#### Monitoring

**Logs** (Supabase Edge Function Logs):
- `[link-telegram] JWT verified successfully. User ID: xxx`
- `[link-telegram] Telegram token verified, extracted telegram_id: xxx`
- `[link-telegram] Link created successfully`
- `[telegram-webhook] Update: /link command from user xxx`

**Metrics to Track**:
- Link success rate (deep link vs manual)
- Token expiry failures
- Conflict errors (already linked)
- Average link completion time

#### Future Enhancements

1. **Manual Code Verification**: Dedicated endpoint for 6-digit code input
2. **iOS Deep Link**: Configure `Info.plist` for iOS support
3. **Bot Commands**: `/track`, `/balance`, `/report` for expense tracking
4. **Multi-Platform**: Support WhatsApp, Discord, Slack integrations
5. **Notification Preferences**: Let users choose which alerts to receive via bot

---

## State Management

### Riverpod Architecture

**Version**: Riverpod 2.x + Hooks

**Provider Types**:
1. **Provider**: Immutable data, no rebuild
2. **StateProvider**: Simple mutable state
3. **StateNotifierProvider**: Complex state + logic
4. **FutureProvider**: Async data loading
5. **StreamProvider**: Real-time data streams

### Example: Wallet Provider

```dart
// lib/features/wallet/presentation/riverpod/wallet_providers.dart

// Get all wallets (stream)
final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.walletDao.watchAllWallets();
});

// Get active wallet
final activeWalletProvider = StateProvider<Wallet?>((ref) => null);

// Wallet notifier (business logic)
class WalletNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletDao _dao;
  final SupabaseSyncService _sync;

  WalletNotifier(this._dao, this._sync) : super(const AsyncValue.loading());

  Future<void> createWallet(WalletCompanion wallet) async {
    // 1. Insert to local DB
    final id = await _dao.createWallet(wallet);

    // 2. Get created wallet with cloudId
    final created = await _dao.getWalletById(id);
    if (created == null) return;

    // 3. Sync to Supabase
    await _sync.uploadWallet(created.toModel());

    // 4. Refresh state
    state = AsyncValue.data(await _dao.getAllWallets());
  }

  Future<void> updateWallet(WalletCompanion wallet) async {
    await _dao.updateWallet(wallet);

    // Sync to cloud
    final updated = await _dao.getWalletById(wallet.id.value);
    if (updated != null) {
      await _sync.uploadWallet(updated.toModel());
    }

    state = AsyncValue.data(await _dao.getAllWallets());
  }

  Future<void> deleteWallet(int id) async {
    await _dao.deleteWallet(id);
    state = AsyncValue.data(await _dao.getAllWallets());
  }
}

final walletNotifierProvider = StateNotifierProvider<WalletNotifier, AsyncValue<List<Wallet>>>((ref) {
  final dao = ref.watch(databaseProvider).walletDao;
  final sync = ref.watch(supabaseSyncServiceProvider);
  return WalletNotifier(dao, sync);
});
```

### Example: Chat Provider

```dart
// lib/features/ai_chat/presentation/riverpod/chat_provider.dart

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatMessageDao _dao;
  final AIService _aiService;

  ChatNotifier(this._dao, this._aiService) : super(const ChatState());

  Future<void> sendMessage(String text) async {
    // 1. Add user message to local DB
    final userMessage = ChatMessage(
      id: uuid.v4(),
      content: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    await _dao.addMessage(userMessage.toCompanion());

    // 2. Show typing indicator
    state = state.copyWith(isTyping: true);

    try {
      // 3. Call AI service
      final response = await _aiService.sendMessage(text);

      // 4. Parse AI response for actions
      final parsedAction = _parseAction(response);

      // 5. Add AI response to DB
      final aiMessage = ChatMessage(
        id: uuid.v4(),
        content: response,
        isFromUser: false,
        timestamp: DateTime.now(),
        pendingAction: parsedAction,
      );

      await _dao.addMessage(aiMessage.toCompanion());

      // 6. Update state
      final messages = await _dao.getAllMessages();
      state = ChatState(messages: messages, isTyping: false);

    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  Future<void> executeAction(PendingAction action) async {
    // Handle AI-suggested actions (create transaction, etc.)
    switch (action.actionType) {
      case 'create_transaction':
        await _createTransactionFromAction(action.data);
        break;
      case 'update_budget':
        await _updateBudgetFromAction(action.data);
        break;
      // ... other actions
    }
  }
}
```

---

## Data Flow

### Read Flow (Query)

```
User Opens Screen
    ↓
Widget reads StreamProvider
    ↓
Provider watches Drift DAO stream
    ↓
DAO queries SQLite
    ↓
Returns Stream<List<Entity>>
    ↓
Riverpod caches result
    ↓
Widget rebuilds with data
    ↓
User sees UI ✅
```

### Write Flow (Command)

```
User Taps "Save"
    ↓
Call Notifier method
    ↓
Notifier validates input
    ↓
1. Write to Local SQLite (Drift) FIRST
    ↓
2. Update Notifier state
    ↓
3. Widget rebuilds with new data
    ↓
4. User sees updated UI ✅ (instant feedback)
    ↓
5. Show success toast
    ↓
6. Trigger sync to Supabase (background, non-blocking)
    ↓
(Background) Sync completes
    ↓
(If sync fails) Log warning only, don't notify user
```

**Key Points**:
- User never waits for cloud sync
- UI updates immediately after local write
- Success toast shown before cloud sync
- Sync failures are silent (logged only)

### Sync Flow (Cloud ↔ Local)

```
UPLOAD (Local → Cloud):
─────────────────────────
Local DB changes
    ↓
Detect via Drift triggers
    ↓
Call SupabaseSyncService.upload()
    ↓
Convert Drift entity → JSON
    ↓
POST to Supabase REST API
    ↓
Supabase validates RLS
    ↓
Write to bexly.* tables
    ↓
Return success
    ↓
Log sync completion

DOWNLOAD (Cloud → Local):
─────────────────────────
User pulls to refresh
    ↓
Call SupabaseSyncService.pull()
    ↓
GET from Supabase REST API
    ↓
Filter by user_id (RLS)
    ↓
Convert JSON → Drift entities
    ↓
Insert/Update local SQLite
    ↓
Drift streams emit updates
    ↓
UI rebuilds automatically

REALTIME (Cloud → Local):
─────────────────────────
Subscribe to Supabase channel
    ↓
Listen to PostgreSQL CDC
    ↓
On INSERT/UPDATE/DELETE event
    ↓
Receive payload via WebSocket
    ↓
Update local SQLite
    ↓
UI updates in real-time
```

---

## Security

### Authentication Security

1. **JWT Tokens**: Short-lived (1 hour), auto-refresh
2. **Secure Storage**: Tokens stored in platform keychain
3. **HTTPS Only**: All API calls over TLS 1.3
4. **OAuth Scopes**: Minimal permissions requested
5. **No Password Storage**: Passwords never stored locally

### Database Security

#### Local SQLite

- **Encryption**: SQLCipher (optional, not enabled yet)
- **File Permissions**: Platform-managed (iOS/Android sandboxing)
- **No Plaintext Secrets**: API keys in environment variables

#### Supabase PostgreSQL

- **Row Level Security (RLS)**: Every table protected
- **JWT Claims**: User ID validated on every query
- **Connection Pooling**: Prevents connection exhaustion
- **SQL Injection**: Parameterized queries only
- **Schema Isolation**: `bexly` schema separate from `public`

### API Key Management

```dart
// ❌ NEVER DO THIS:
const apiKey = 'sk-1234567890abcdef';

// ✅ CORRECT:
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiKey = dotenv.env['OPENAI_API_KEY']!;

// .env file (NEVER commit to git):
OPENAI_API_KEY=sk-real-key-here
GEMINI_API_KEY=AIza...
SUPABASE_KEY=sb_publishable...
```

**.gitignore**:
```
.env
*.jks
google-services.json
keystore.properties
```

### Data Privacy

- **Local Storage**: Sensitive data stored locally with offline support
- **E2E Sync**: Data encrypted in transit (TLS)
- **No Tracking**: No user analytics without consent
- **GDPR Compliant**: User can export/delete all data
- **Audit Logs**: Track who accessed what (Supabase logs)

---

## Performance

### App Launch Time

**Target**: < 2 seconds on mid-range devices

**Optimizations**:
1. **Lazy Loading**: Features loaded on-demand
2. **Code Splitting**: Deferred imports for heavy screens
3. **Asset Compression**: Images optimized with `flutter_image_compress`
4. **Native Splash**: Platform splash screen (no Flutter overhead)
5. **Database Warmup**: Drift connection cached

### UI Performance

**Target**: 60 FPS (16ms frame budget)

**Optimizations**:
1. **const Constructors**: Immutable widgets cached
2. **Keys**: Preserve widget state during rebuilds
3. **Provider Granularity**: Only rebuild affected widgets
4. **List Virtualization**: `ListView.builder` for long lists
5. **Image Caching**: `cached_network_image` for remote assets

### Database Performance

**Query Time Target**: < 100ms for complex queries

**Optimizations**:
1. **Indexes**: All foreign keys indexed
2. **Query Limits**: Paginate large result sets
3. **Batch Operations**: Bulk inserts use transactions
4. **Connection Pooling**: Reuse Drift connection
5. **Materialized Views**: Pre-compute aggregations (planned)

**Example Query Plan**:
```sql
-- ❌ SLOW: Full table scan
SELECT * FROM transactions WHERE user_id = '123';

-- ✅ FAST: Index scan
SELECT * FROM transactions
WHERE user_id = '123'
  AND date >= '2024-01-01'
ORDER BY date DESC
LIMIT 100;

-- Uses index: idx_transactions_user_date
```

### Network Performance

**Sync Time Target**: < 5 seconds for 1000 records

**Optimizations**:
1. **Batch Uploads**: Max 100 records per request
2. **Compression**: gzip on large payloads
3. **Incremental Sync**: Only changed records
4. **Request Deduplication**: Skip redundant syncs
5. **Retry Strategy**: Exponential backoff (1s, 2s, 4s, 8s)

### Memory Management

**Target**: < 100MB RAM usage

**Optimizations**:
1. **Stream Disposal**: Cancel Drift streams on dispose
2. **Image Memory**: Use `cacheWidth`/`cacheHeight`
3. **Provider Cleanup**: Auto-dispose on route exit
4. **Weak References**: For large cached objects
5. **GC Hints**: Call `gc()` after heavy operations (manual)

---

## Monitoring & Debugging

### Logging

**Tool**: Custom `Log` class (wrapper around `print`)

**Levels**:
- `Log.d()` - Debug (verbose)
- `Log.i()` - Info (important events)
- `Log.w()` - Warning (recoverable errors)
- `Log.e()` - Error (critical failures)

**Example**:
```dart
Log.i('User logged in: ${user.email}', label: 'auth');
Log.e('Sync failed: $error', label: 'sync');
```

### Crash Reporting

**Tool**: Firebase Crashlytics

**Auto-Reported**:
- Dart exceptions
- Native crashes (Android/iOS)
- ANRs (Application Not Responding)
- OOM (Out of Memory)

**Custom Events**:
```dart
FirebaseCrashlytics.instance.recordError(
  exception,
  stackTrace,
  reason: 'Sync service failure',
  information: ['userId: $userId', 'syncAttempt: $attempt'],
);
```

### Analytics

**Tool**: Firebase Analytics

**Tracked Events**:
- Screen views
- Button clicks
- Feature usage
- Error rates
- Sync success/failure
- AI chat interactions

---

## Deployment

### Android

**Build Command**:
```bash
flutter build apk --release              # Single APK
flutter build appbundle --release        # Play Store AAB
```

**Signing**:
- Keystore: `upload-keystore.jks` (NOT in git)
- Config: `android/key.properties` (NOT in git)

**Distribution**:
- Internal Testing: Firebase App Distribution
- Beta: Google Play Internal/Closed Testing
- Production: Google Play Open Testing → Production

### iOS

**Build Method**: GitHub Actions (cannot build on Windows)

**Workflow**:
1. Push to `main` branch
2. GitHub Actions triggers
3. Build on macOS runner
4. Sign with Apple certificates
5. Upload to TestFlight
6. (Manual) Submit to App Store

**Certificate Management**:
- Provisioning profiles in GitHub Secrets
- Auto-managed by Fastlane

### Web

**Status**: Planned (not yet deployed)

**Build Command**:
```bash
flutter build web --release --web-renderer html
```

**Hosting Options**:
- Supabase Storage (static hosting)
- Firebase Hosting
- Vercel
- Netlify

---

## Future Roadmap

### Q1 2026
- ✅ Complete Supabase migration
- ✅ Multi-device sync with Realtime
- ⏳ Web version MVP
- ⏳ Desktop apps (Windows/macOS)

### Q2 2026
- ⏳ Family sharing (shared wallets)
- ⏳ Receipt OCR (camera → transaction)
- ⏳ Investment tracking (stocks/crypto)
- ⏳ Bill reminders (push notifications)

### Q3 2026
- ⏳ Dark mode themes
- ⏳ Multi-language support (i18n)
- ⏳ Export to Excel/PDF
- ⏳ Voice commands (full voice UI)

### Q4 2026
- ⏳ Widgets (home screen balance)
- ⏳ Watch app (Apple Watch/Wear OS)
- ⏳ AI financial advisor
- ⏳ Open banking (EU PSD2)

---

## Contributing

### Code Style

**Formatting**:
```bash
dart format .
flutter analyze
```

**Linting**:
- Follow `analysis_options.yaml`
- Use `const` constructors where possible
- Prefer `final` over `var`
- Use descriptive variable names

**Naming**:
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Privates: `_leadingUnderscore`

### Git Workflow

**Branches**:
- `main` - Production (stable)
- `dev` - Development (unstable)
- `feature/*` - New features
- `fix/*` - Bug fixes
- `hotfix/*` - Critical prod fixes

**Commit Messages**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Add/update tests
- `docs` - Documentation
- `chore` - Build/tooling

**Example**:
```
feat(wallet): add credit card wallet type

- Add creditLimit field to WalletModel
- Update wallet creation UI with credit card option
- Sync credit card data to Supabase

Closes #123
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Added unit tests
- [ ] Added integration tests

## Checklist
- [ ] Code follows style guide
- [ ] Self-reviewed code
- [ ] Commented complex logic
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Added tests
- [ ] All tests pass
```

---

## Troubleshooting

### Common Issues

#### Build Errors

**Issue**: `MissingPluginException`
```
Solution:
flutter clean
flutter pub get
flutter run
```

**Issue**: `Gradle build failed`
```
Solution:
cd android
./gradlew clean
cd ..
flutter build apk
```

#### Runtime Errors

**Issue**: `Database is locked`
```
Solution: Close all Drift connections before reopening
await db.close();
db = AppDatabase();
```

**Issue**: `Supabase RLS denies access`
```
Solution: Check JWT token and user_id claim
final user = Supabase.instance.client.auth.currentUser;
print('User ID: ${user?.id}');
```

#### Sync Issues

**Issue**: `Sync not working`
```
Checklist:
1. Check network connection
2. Verify Supabase auth
3. Check RLS policies
4. Look for sync errors in logs
5. Try manual sync: pullFromCloud()
```

---

## Glossary

- **DAO**: Data Access Object (database layer)
- **Drift**: SQLite ORM for Flutter
- **RLS**: Row Level Security (Supabase)
- **CDC**: Change Data Capture (Realtime)
- **JWT**: JSON Web Token (authentication)
- **OAuth**: Open Authorization (social login)
- **FCM**: Firebase Cloud Messaging (push)
- **OCR**: Optical Character Recognition (scan text)
- **LWW**: Last-Write-Wins (conflict resolution)
- **UUID**: Universally Unique Identifier
- **CRUD**: Create, Read, Update, Delete

---

## Resources

- **Codebase**: https://github.com/BexlyApp/Bexly
- **Supabase Dashboard**: https://supabase.com/dashboard/project/gulptwduchsjcsbndmua
- **Play Store**: https://play.google.com/store/apps/details?id=com.joy.bexly
- **Documentation**: [docs/](docs/)
- **Migration Guide**: [docs/SUPABASE_MIGRATION_STATUS.md](docs/SUPABASE_MIGRATION_STATUS.md)

---

**Document Version**: 1.1
**Last Updated By**: Claude (AI Assistant)
**Next Review Date**: 2026-02-25
**Recent Updates**:
- Added Telegram Bot Integration section (deep link flow, JWT verification, Edge Functions)
