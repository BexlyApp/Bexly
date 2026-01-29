# Firestore to Supabase Migration Plan

## Executive Summary

Migrate all data sync from Firebase Firestore to Supabase PostgreSQL to consolidate authentication and data storage into a single platform. Keep FCM for push notifications.

**Timeline:** 3-4 weeks
**Risk Level:** Medium (requires careful data migration and testing)

---

## Current Architecture

```
┌─────────────────────────────────────────┐
│           BEXLY APP                     │
├─────────────────────────────────────────┤
│  Auth: Supabase Auth                    │ ← NEW (migrated)
│  Local: Drift SQLite (offline support)  │ ← Keep
│  Cloud Sync: Firebase Firestore         │ ← TO REMOVE
│  Push: Firebase FCM                     │ ← Keep
│  Bank: dos.me Supabase API              │ ← Keep
└─────────────────────────────────────────┘
```

**Problems:**
- ❌ Auth on Supabase, Data on Firestore → Inconsistent
- ❌ Firestore rules use Firebase Auth UIDs, but users use Supabase Auth
- ❌ Two databases to maintain
- ❌ Two billing systems

---

## Target Architecture

```
┌─────────────────────────────────────────┐
│           BEXLY APP                     │
├─────────────────────────────────────────┤
│  Auth: Supabase Auth                    │ ✅
│  Local: Drift SQLite (offline support)  │ ✅
│  Cloud Sync: Supabase PostgreSQL        │ ✅ NEW
│  Realtime: Supabase Realtime            │ ✅ NEW
│  Push: Firebase FCM                     │ ✅ Keep
│  Bank: dos.me Supabase API              │ ✅
└─────────────────────────────────────────┘
```

**Benefits:**
- ✅ Single source of truth (Supabase)
- ✅ Auth + Data in same place → Unified RLS policies
- ✅ PostgreSQL > Firestore (joins, transactions, constraints)
- ✅ Supabase Realtime with PostgreSQL triggers
- ✅ Aligned with dos.me backend
- ✅ Better pricing at scale

---

## Migration Phases

### Phase 1: Design & Setup (Week 1)

**1.1 Design Supabase Schema**
- Create tables matching Drift schema
- Design RLS policies
- Setup indexes for performance
- Plan migration scripts

**1.2 Setup Supabase Project**
- Use existing Supabase project (already has auth)
- Enable Realtime for required tables
- Configure connection pooling

**Tables to create:**
- `wallets`
- `transactions`
- `categories`
- `budgets`
- `goals`
- `recurring_transactions`
- `chat_messages`
- `parsed_email_transactions`

---

### Phase 2: Implementation (Week 2)

**2.1 Create Supabase Sync Service**
- `lib/core/services/sync/supabase_sync_service.dart`
- Replaces `firestore_database.dart`
- Implements same interface as Firestore sync
- Handle conflict resolution (last-write-wins with timestamps)

**2.2 Implement Realtime Subscriptions**
- Listen to changes from other devices
- Update local Drift DB on remote changes
- Optimistic updates (local first, sync background)

**2.3 Update Providers**
- Replace Firestore providers with Supabase
- Keep same API for app code (minimal changes)

---

### Phase 3: Data Migration (Week 3)

**3.1 Migration Script**
- Read all data from Firestore
- Transform to Supabase schema
- Bulk insert to Supabase
- Verify data integrity

**3.2 Dual-Write Period (7 days)**
- Write to BOTH Firestore AND Supabase
- Monitor for sync issues
- Verify data consistency
- Rollback plan if issues

**3.3 Switch to Supabase-only**
- Disable Firestore writes
- Monitor for 48 hours
- Keep Firestore read-only for 1 week (fallback)

---

### Phase 4: Cleanup (Week 4)

**4.1 Remove Firestore Code**
- Delete `firestore_database.dart`
- Remove Firestore dependencies from `pubspec.yaml`
- Delete Firestore security rules
- Update documentation

**4.2 Keep FCM**
- FCM is infrastructure layer (push notifications)
- Supabase doesn't have native push service
- FCM tokens stored in Supabase `users.fcm_token`

---

## Detailed Implementation

### Supabase Schema

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Wallets table
CREATE TABLE wallets (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  currency TEXT NOT NULL,
  balance DECIMAL(20, 2) DEFAULT 0,
  icon TEXT,
  color TEXT,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT unique_user_wallet UNIQUE(user_id, cloud_id)
);

-- Transactions table
CREATE TABLE transactions (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES wallets(cloud_id) ON DELETE CASCADE,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  note TEXT,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense', 'transfer')),
  transaction_date TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT valid_amount CHECK (amount != 0)
);

-- Categories table
CREATE TABLE categories (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_user_category UNIQUE(user_id, name, type)
);

-- Budgets table
CREATE TABLE budgets (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES wallets(cloud_id) ON DELETE CASCADE,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Goals table
CREATE TABLE goals (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES wallets(cloud_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_amount DECIMAL(20, 2) NOT NULL,
  current_amount DECIMAL(20, 2) DEFAULT 0,
  deadline DATE,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recurring transactions table
CREATE TABLE recurring_transactions (
  cloud_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES wallets(cloud_id) ON DELETE CASCADE,
  category TEXT,
  amount DECIMAL(20, 2) NOT NULL,
  note TEXT,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  next_occurrence DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat messages table
CREATE TABLE chat_messages (
  message_id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_from_user BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Parsed email transactions table
CREATE TABLE parsed_email_transactions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  gmail_message_id TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  amount DECIMAL(20, 2) NOT NULL,
  currency TEXT NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  merchant TEXT,
  transaction_date TIMESTAMPTZ NOT NULL,
  confidence DECIMAL(3, 2) NOT NULL,
  raw_subject TEXT,
  raw_body TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_gmail_message UNIQUE(user_id, gmail_message_id)
);

-- Indexes for performance
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_wallets_user ON wallets(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_chat_messages_user_time ON chat_messages(user_id, timestamp DESC);
CREATE INDEX idx_parsed_emails_user_status ON parsed_email_transactions(user_id, status);

-- Row Level Security (RLS) Policies

-- Wallets RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallets"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wallets"
  ON wallets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wallets"
  ON wallets FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wallets"
  ON wallets FOR DELETE
  USING (auth.uid() = user_id);

-- Transactions RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON transactions FOR DELETE
  USING (auth.uid() = user_id);

-- Categories RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own categories"
  ON categories FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Budgets RLS
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own budgets"
  ON budgets FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Goals RLS
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals"
  ON goals FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Recurring transactions RLS
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own recurring transactions"
  ON recurring_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Chat messages RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat messages"
  ON chat_messages FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Parsed email transactions RLS
ALTER TABLE parsed_email_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own parsed emails"
  ON parsed_email_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to tables
CREATE TRIGGER update_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recurring_transactions_updated_at
  BEFORE UPDATE ON recurring_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Implementation Code Structure

```
lib/core/services/sync/
├── supabase_sync_service.dart          # Main sync service
├── sync_interface.dart                 # Abstract interface
├── models/
│   ├── sync_result.dart
│   └── sync_conflict.dart
└── strategies/
    ├── wallet_sync_strategy.dart
    ├── transaction_sync_strategy.dart
    ├── chat_message_sync_strategy.dart
    └── base_sync_strategy.dart

lib/core/database/
├── supabase_database.dart              # Supabase client wrapper
└── database_provider.dart              # Updated to support both

lib/features/*/riverpod/
└── *_sync_providers.dart               # Updated providers
```

---

## Migration Script (Python)

```python
#!/usr/bin/env python3
"""
Firestore to Supabase migration script
Reads data from Firestore and writes to Supabase
"""

import firebase_admin
from firebase_admin import credentials, firestore
from supabase import create_client
import os
from datetime import datetime
from typing import Dict, List

# Initialize Firebase
cred = credentials.Certificate('firebase-service-account.json')
firebase_admin.initialize_app(cred)
db = firestore.client(database='bexly')

# Initialize Supabase
supabase_url = os.environ.get('SUPABASE_URL')
supabase_key = os.environ.get('SUPABASE_SERVICE_KEY')
supabase = create_client(supabase_url, supabase_key)

def migrate_user_data(firebase_user_id: str, supabase_user_id: str):
    """Migrate all data for a single user"""

    print(f"Migrating user {firebase_user_id} -> {supabase_user_id}")

    # Migrate wallets
    wallets_ref = db.collection('users').document(firebase_user_id).collection('data').document('wallets').collection('items')
    wallets = wallets_ref.stream()

    for wallet in wallets:
        data = wallet.to_dict()
        supabase_data = {
            'cloud_id': data.get('cloudId'),
            'user_id': supabase_user_id,
            'name': data.get('name'),
            'currency': data.get('currency'),
            'balance': data.get('balance'),
            'icon': data.get('icon'),
            'color': data.get('color'),
            'is_archived': data.get('isArchived', False),
            'created_at': data.get('createdAt').isoformat() if data.get('createdAt') else None,
            'updated_at': data.get('updatedAt').isoformat() if data.get('updatedAt') else None,
        }

        result = supabase.table('wallets').upsert(supabase_data).execute()
        print(f"  Migrated wallet: {data.get('name')}")

    # Migrate transactions
    transactions_ref = db.collection('users').document(firebase_user_id).collection('data').document('transactions').collection('items')
    transactions = transactions_ref.stream()

    for transaction in transactions:
        data = transaction.to_dict()
        supabase_data = {
            'cloud_id': data.get('cloudId'),
            'user_id': supabase_user_id,
            'wallet_id': data.get('walletId'),
            'category': data.get('category'),
            'amount': data.get('amount'),
            'note': data.get('note'),
            'transaction_type': data.get('transactionType'),
            'transaction_date': data.get('transactionDate').isoformat() if data.get('transactionDate') else None,
            'is_recurring': data.get('isRecurring', False),
            'recurring_id': data.get('recurringId'),
            'created_at': data.get('createdAt').isoformat() if data.get('createdAt') else None,
            'updated_at': data.get('updatedAt').isoformat() if data.get('updatedAt') else None,
        }

        result = supabase.table('transactions').upsert(supabase_data).execute()

    print(f"  Migrated transactions")

    # Similar for other collections...
    # - categories
    # - budgets
    # - goals
    # - recurring_transactions
    # - chat_messages

def migrate_all_users():
    """Migrate all users from Firebase to Supabase"""

    # Get user mapping (Firebase UID -> Supabase UUID)
    # This assumes you have a mapping table or can query by email

    users_ref = db.collection('users')
    users = users_ref.stream()

    for user in users:
        firebase_uid = user.id

        # TODO: Get Supabase UUID for this user
        # Option 1: Query Supabase auth.users by email
        # Option 2: Use pre-built mapping table

        # migrate_user_data(firebase_uid, supabase_uuid)
        pass

if __name__ == '__main__':
    # Test with single user first
    # migrate_user_data('firebase_uid_here', 'supabase_uuid_here')

    # Then migrate all
    # migrate_all_users()

    print("Migration complete!")
```

---

## Risk Mitigation

### Data Loss Prevention
- ✅ Dual-write period (write to both DBs)
- ✅ Keep Firestore read-only for 1 week after switch
- ✅ Daily backups of Supabase during migration
- ✅ Rollback plan documented

### Performance
- ✅ Batch operations for bulk sync
- ✅ Indexes on frequently queried columns
- ✅ Connection pooling enabled
- ✅ Monitor query performance with Supabase dashboard

### User Impact
- ✅ No downtime required
- ✅ Gradual rollout (beta → 10% → 50% → 100%)
- ✅ Feature flag to switch between Firestore/Supabase
- ✅ Monitoring and alerting

---

## Testing Plan

### Unit Tests
- Sync service methods
- Conflict resolution logic
- Data transformations

### Integration Tests
- Drift ↔ Supabase sync
- Realtime subscription updates
- Multi-device sync

### E2E Tests
- Create wallet → Sync → Verify on Supabase
- Update transaction → Verify realtime update
- Offline → Online sync

### Beta Testing
- Internal team (1 week)
- Beta users (1 week)
- Monitor error rates, sync conflicts

---

## Rollout Strategy

### Week 1: Internal Testing
- Enable Supabase sync for dev builds
- Test on internal devices
- Monitor logs and errors

### Week 2: Beta Rollout
- 10% of users (feature flag)
- Monitor sync success rate
- Collect feedback

### Week 3: Gradual Rollout
- 50% of users
- Continue monitoring
- Fix issues as discovered

### Week 4: Full Rollout
- 100% of users
- Keep Firestore code for 1 more week (safety)
- Schedule cleanup

---

## Success Metrics

- ✅ 99.9% sync success rate
- ✅ < 2s sync latency
- ✅ Zero data loss
- ✅ < 5% increase in app crashes
- ✅ Positive user feedback

---

## Cleanup Checklist

After 1 week of successful Supabase-only operation:

- [ ] Remove Firestore dependencies from `pubspec.yaml`
- [ ] Delete `lib/core/database/firestore_database.dart`
- [ ] Delete `lib/core/services/sync/*_firestore_sync_service.dart`
- [ ] Remove Firestore security rules
- [ ] Update documentation
- [ ] Archive Firestore project (don't delete yet)
- [ ] Cancel Firestore billing (after 30 days)

---

## Keep FCM

```yaml
# pubspec.yaml - Keep these
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest

# Remove these
# cloud_firestore: ^x.x.x
# firebase_auth: ^x.x.x (already removed for Supabase)
```

FCM stays because:
- Infrastructure layer (not data layer)
- Supabase doesn't have native push service
- FCM is industry standard for mobile push
- FCM tokens stored in Supabase `users.fcm_token` table

---

## Timeline Summary

| Week | Phase | Tasks | Owner |
|------|-------|-------|-------|
| 1 | Design | Schema design, Setup Supabase, Write migration script | Backend |
| 2 | Implement | Sync service, Realtime, Update providers | Flutter |
| 3 | Migrate | Run migration, Dual-write, Monitor | DevOps |
| 4 | Cleanup | Remove Firestore, Documentation, Celebrate 🎉 | All |

**Total: 3-4 weeks**

---

## Next Steps

1. Review this plan
2. Approve schema design
3. Start Phase 1: Create Supabase tables
4. Begin implementing sync service

**Ready to start? Let's execute! 🚀**
