# Bexly Migration to DOS-Me Supabase - Master Plan

## Executive Summary

Migrate Bexly from standalone Firebase/Firestore to DOS-Me Supabase ecosystem. Consolidate all services (Database, Auth, Storage, Realtime) into single Supabase project with schema-based isolation.

**Timeline:** 2-3 weeks
**Risk Level:** Medium
**Rollback Plan:** Keep Firebase read-only for 1 week

---

## Current vs Target Architecture

### Current (Standalone)

```
┌─────────────────────────────────────┐
│  BEXLY (Standalone)                 │
├─────────────────────────────────────┤
│  Auth: Supabase Auth (bexly project)│
│  Database:                          │
│    - Local: Drift SQLite            │
│    - Cloud: Firebase Firestore      │
│  Storage: N/A                       │
│  Realtime: N/A                      │
│  Push: Firebase FCM                 │
│  Bank: DOS-Me Supabase API          │
└─────────────────────────────────────┘
```

**Problems:**
- ❌ Auth on Supabase, Data on Firestore → Split
- ❌ Bank accounts via DOS-Me API but auth separate
- ❌ No storage bucket for receipts/avatars
- ❌ No realtime sync (manual Firestore sync)

---

### Target (DOS-Me Ecosystem)

```
┌──────────────────────────────────────────────┐
│  DOS-ME SUPABASE (Unified Ecosystem)         │
├──────────────────────────────────────────────┤
│  Auth: Shared (public.users)                 │
│                                              │
│  Database:                                   │
│    ├─ public (shared)                       │
│    │   ├─ users                              │
│    │   ├─ wallets (Openfort)                │
│    │   └─ bank_accounts (Stripe)            │
│    │                                         │
│    ├─ dosme (social network)                │
│    ├─ bexly (finance app) ← NEW!           │
│    ├─ dosai (AI platform)                   │
│    └─ metados (gaming)                      │
│                                              │
│  Storage:                                    │
│    ├─ bexly-avatars ← NEW!                  │
│    ├─ bexly-receipts ← NEW!                 │
│    └─ bexly-exports ← NEW!                  │
│                                              │
│  Realtime:                                   │
│    └─ bexly.* channels ← NEW!               │
│                                              │
│  Push: Firebase FCM (keep)                  │
└──────────────────────────────────────────────┘
```

**Benefits:**
- ✅ Unified auth with DOS-Me, DOS.AI, MetaDOS
- ✅ Direct access to bank_accounts (no API)
- ✅ Storage buckets for receipts/avatars
- ✅ Realtime sync (Supabase Realtime > Firestore)
- ✅ Cost: $0/month (included in DOS-Me Pro)

---

## Migration Phases

### Phase 1: Schema Setup (Week 1 - Day 1-2)

**Owner:** DOS-Me Backend Team

**Tasks:**

1. **Create Bexly Schema**
   - Run SQL migration: [`BEXLY_SETUP_FOR_DOSME_SUPABASE.md`](../BEXLY_SETUP_FOR_DOSME_SUPABASE.md)
   - Tables: transactions, budgets, categories, goals, recurring_transactions, chat_messages, parsed_email_transactions
   - Indexes, RLS policies, triggers

2. **Create Storage Bucket**
   ```bash
   # In Supabase Dashboard → Storage → Create bucket
   - Name: bexly
   - Public: false (private)
   - Max file size: 10MB
   - Folder structure: avatars/, receipts/, exports/
   ```

3. **Enable Realtime**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE bexly.transactions;
   ALTER PUBLICATION supabase_realtime ADD TABLE bexly.chat_messages;
   ALTER PUBLICATION supabase_realtime ADD TABLE bexly.parsed_email_transactions;
   ```

4. **Verify Setup**
   ```sql
   -- Check schema
   SELECT * FROM information_schema.schemata WHERE schema_name = 'bexly';

   -- Check tables
   SELECT * FROM information_schema.tables WHERE table_schema = 'bexly';

   -- Check RLS
   SELECT * FROM pg_policies WHERE schemaname = 'bexly';
   ```

**Deliverables:**
- ✅ Bexly schema created
- ✅ Storage buckets ready
- ✅ Realtime enabled
- ✅ Verification report

---

### Phase 2: Auth Migration (Week 1 - Day 3-4)

**Owner:** Bexly Team

**Tasks:**

1. **Update Supabase Config**
   ```dart
   // lib/core/config/supabase_config.dart

   // OLD: Standalone Bexly project
   // static const supabaseUrl = 'https://bexly-xyz.supabase.co';

   // NEW: DOS-Me project
   static const supabaseUrl = 'https://dos-me-xyz.supabase.co';
   static const supabasePublishableKey = 'sb_publishable_xxx'; // NEW: Publishable key (safe for public)
   ```

2. **Update Supabase Client**
   ```dart
   // lib/core/services/supabase_init_service.dart
   await Supabase.initialize(
     url: SupabaseConfig.supabaseUrl,
     anonKey: SupabaseConfig.supabasePublishableKey, // Uses publishable key
     authOptions: const FlutterAuthClientOptions(
       authFlowType: AuthFlowType.pkce,
     ),
     // Specify bexly schema as default
     realtimeClientOptions: const RealtimeClientOptions(
       schema: 'bexly',
     ),
   );
   ```

3. **Test Auth Flow**
   - Sign up new user
   - Sign in existing user
   - Google Sign In
   - Password reset
   - Verify user created in `auth.users`

**Deliverables:**
- ✅ Supabase config updated
- ✅ Auth flow tested
- ✅ Users can login

---

### Phase 3: Database Migration (Week 1 Day 5 - Week 2 Day 3)

**Owner:** Bexly Team

**Tasks:**

1. **Create Supabase Sync Service**

Create `lib/core/services/sync/supabase_sync_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bexly/core/database/app_database.dart';

class SupabaseSyncService {
  final SupabaseClient _supabase;
  final AppDatabase _localDb;

  SupabaseSyncService({
    required SupabaseClient supabase,
    required AppDatabase localDb,
  })  : _supabase = supabase,
        _localDb = localDb;

  /// Sync transactions to Supabase
  Future<void> syncTransactions() async {
    final localTransactions = await _localDb.transactionDao.getAllTransactions();

    for (final tx in localTransactions) {
      // Skip if already synced
      if (tx.cloudId != null) continue;

      final data = {
        'cloud_id': tx.cloudId ?? _generateUUID(),
        'user_id': _supabase.auth.currentUser!.id,
        'wallet_id': tx.walletId,
        'category': tx.category,
        'amount': tx.amount,
        'note': tx.note,
        'transaction_type': tx.transactionType,
        'transaction_date': tx.transactionDate.toIso8601String(),
        'created_at': tx.createdAt.toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('transactions')
          .upsert(data);

      // Update local with cloud_id
      await _localDb.transactionDao.updateCloudId(tx.id, data['cloud_id']);
    }
  }

  /// Download transactions from Supabase
  Future<void> downloadTransactions() async {
    final response = await _supabase
        .schema('bexly')
        .from('transactions')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id);

    for (final row in response) {
      // Insert/update local DB
      await _localDb.transactionDao.upsertFromCloud(row);
    }
  }

  /// Setup Realtime subscription
  void subscribeToChanges() {
    _supabase
        .channel('bexly-transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'bexly',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _supabase.auth.currentUser!.id,
          ),
          callback: (payload) {
            _handleRealtimeChange(payload);
          },
        )
        .subscribe();
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _localDb.transactionDao.insertFromCloud(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _localDb.transactionDao.updateFromCloud(payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _localDb.transactionDao.deleteByCloudId(payload.oldRecord['cloud_id']);
        break;
    }
  }

  String _generateUUID() {
    return Uuid().v4();
  }
}
```

2. **Update Providers**

```dart
// lib/core/services/sync/sync_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
SupabaseSyncService supabaseSyncService(SupabaseSyncServiceRef ref) {
  final supabase = Supabase.instance.client;
  final db = ref.watch(databaseProvider);

  return SupabaseSyncService(
    supabase: supabase,
    localDb: db,
  );
}

// Auto-sync on app start
@riverpod
Future<void> autoSync(AutoSyncRef ref) async {
  final syncService = ref.watch(supabaseSyncServiceProvider);

  // Download from cloud
  await syncService.downloadTransactions();

  // Upload local changes
  await syncService.syncTransactions();

  // Subscribe to realtime
  syncService.subscribeToChanges();
}
```

3. **Migrate Existing Data (Python Script)**

```python
#!/usr/bin/env python3
"""
Migrate Bexly data from Firestore to DOS-Me Supabase
"""

import firebase_admin
from firebase_admin import credentials, firestore
from supabase import create_client
import os

# Firebase (source)
cred = credentials.Certificate('bexly-firebase-key.json')
firebase_admin.initialize_app(cred)
firestore_db = firestore.client(database='bexly')

# Supabase (target)
supabase = create_client(
    os.environ['DOSME_SUPABASE_URL'],
    os.environ['DOSME_SUPABASE_SERVICE_KEY']
)

def migrate_user_transactions(firebase_uid: str, supabase_uuid: str):
    """Migrate transactions for a single user"""
    print(f"Migrating transactions for {firebase_uid} -> {supabase_uuid}")

    # Get Firestore transactions
    transactions_ref = (
        firestore_db
        .collection('users')
        .document(firebase_uid)
        .collection('data')
        .document('transactions')
        .collection('items')
    )

    transactions = transactions_ref.stream()

    for tx in transactions:
        data = tx.to_dict()

        # Transform to Supabase schema
        supabase_data = {
            'cloud_id': data.get('cloudId'),
            'user_id': supabase_uuid,
            'wallet_id': data.get('walletId'),
            'category': data.get('category'),
            'amount': float(data.get('amount', 0)),
            'note': data.get('note'),
            'transaction_type': data.get('transactionType'),
            'transaction_date': data.get('transactionDate').isoformat() if data.get('transactionDate') else None,
            'created_at': data.get('createdAt').isoformat() if data.get('createdAt') else None,
            'updated_at': data.get('updatedAt').isoformat() if data.get('updatedAt') else None,
        }

        # Insert to Supabase
        result = supabase.table('bexly.transactions').upsert(supabase_data).execute()
        print(f"  ✅ Migrated transaction {supabase_data['cloud_id']}")

def get_user_mapping():
    """Get Firebase UID -> Supabase UUID mapping"""
    # Query Supabase users by email to get mapping
    # Assuming emails are same in both systems

    # TODO: Implement user mapping logic
    # Option 1: Query by email
    # Option 2: Use pre-built CSV mapping
    pass

if __name__ == '__main__':
    # TODO: Run migration for all users
    # migrate_user_transactions('firebase_uid', 'supabase_uuid')

    print("Migration script ready. Update get_user_mapping() and run.")
```

**Deliverables:**
- ✅ Supabase sync service implemented
- ✅ Realtime subscriptions working
- ✅ Historical data migrated
- ✅ Drift ↔ Supabase sync verified

---

### Phase 4: Storage Integration (Week 2 Day 4-5)

**Owner:** Bexly Team

**Tasks:**

1. **Create Storage Service**

```dart
// lib/core/services/storage/bexly_storage_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class BexlyStorageService {
  final SupabaseClient _supabase;

  BexlyStorageService(this._supabase);

  /// Upload user avatar
  Future<String> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser!.id;
    final path = 'avatars/$userId/avatar.jpg';

    await _supabase.storage
        .from('bexly')
        .upload(path, imageFile, fileOptions: FileOptions(upsert: true));

    // Return signed URL (private bucket)
    return await _supabase.storage
        .from('bexly')
        .createSignedUrl(path, 3600); // 1 hour expiry
  }

  /// Upload receipt
  Future<String> uploadReceipt(File receiptFile, String transactionId) async {
    final userId = _supabase.auth.currentUser!.id;
    final ext = receiptFile.path.split('.').last;
    final path = 'receipts/$userId/${transactionId}_receipt.$ext';

    await _supabase.storage
        .from('bexly')
        .upload(path, receiptFile);

    return path; // Store path in bexly.transactions.receipt_url
  }

  /// Get receipt signed URL
  Future<String> getReceiptUrl(String path) async {
    return await _supabase.storage
        .from('bexly')
        .createSignedUrl(path, 3600);
  }

  /// Export CSV
  Future<String> exportTransactionsCsv(String csvContent) async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final path = 'exports/$userId/bexly_export_$timestamp.csv';

    await _supabase.storage
        .from('bexly')
        .uploadBinary(
          path,
          utf8.encode(csvContent),
          fileOptions: const FileOptions(contentType: 'text/csv'),
        );

    return await _supabase.storage
        .from('bexly')
        .createSignedUrl(path, 86400); // 24 hours
  }

  /// List user receipts
  Future<List<FileObject>> listReceipts() async {
    final userId = _supabase.auth.currentUser!.id;

    return await _supabase.storage
        .from('bexly')
        .list(path: 'receipts/$userId');
  }

  /// Delete receipt
  Future<void> deleteReceipt(String path) async {
    await _supabase.storage
        .from('bexly')
        .remove([path]);
  }
}
```

2. **Update UI Components**

```dart
// lib/features/profile/presentation/components/avatar_picker.dart

// Add upload button
ElevatedButton(
  onPressed: () async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final storageService = ref.read(bexlyStorageServiceProvider);
    final avatarUrl = await storageService.uploadAvatar(File(image.path));

    // Update user profile
    await supabase.from('public.users').update({'avatar_url': avatarUrl});
  },
  child: Text('Upload Avatar'),
);
```

**Deliverables:**
- ✅ Storage service implemented
- ✅ Avatar upload working
- ✅ Receipt upload working
- ✅ CSV export working

---

### Phase 5: Realtime Sync (Week 3 Day 1-2)

**Owner:** Bexly Team

**Tasks:**

1. **Implement Realtime Providers**

```dart
// lib/features/transaction/riverpod/transaction_realtime_provider.dart

@riverpod
class TransactionRealtime extends _$TransactionRealtime {
  RealtimeChannel? _channel;

  @override
  void build() {
    _subscribeToChanges();
  }

  void _subscribeToChanges() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    _channel = supabase
        .channel('transactions-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'bexly',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Invalidate transaction providers to refetch
            ref.invalidate(transactionListProvider);
            ref.invalidate(transactionStatsProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
```

2. **Test Multi-Device Sync**
   - Device A: Create transaction
   - Device B: Should see transaction appear (realtime)
   - Device A: Update transaction
   - Device B: Should see update (realtime)

**Deliverables:**
- ✅ Realtime subscriptions implemented
- ✅ Multi-device sync tested
- ✅ Performance verified (<2s latency)

---

### Phase 6: Testing & Rollout (Week 3 Day 3-5)

**Owner:** Bexly Team + QA

**Tasks:**

1. **Unit Tests**
   ```dart
   // test/services/supabase_sync_service_test.dart

   test('syncTransactions uploads local changes', () async {
     // Create local transaction
     await localDb.transactionDao.insert(mockTransaction);

     // Sync to Supabase
     await syncService.syncTransactions();

     // Verify uploaded
     final response = await supabase
         .from('bexly.transactions')
         .select()
         .eq('cloud_id', mockTransaction.cloudId);

     expect(response, isNotEmpty);
   });
   ```

2. **Integration Tests**
   - Create transaction → Verify in Supabase
   - Update transaction → Verify sync
   - Delete transaction → Verify soft delete
   - Offline → Online sync

3. **E2E Tests**
   - Sign up → Create wallet → Add transaction → Sync
   - Multi-device: Create on Device A → See on Device B
   - Conflict resolution: Edit same transaction on 2 devices

4. **Beta Testing**
   - Internal team (3 days)
   - Beta users (2 days)
   - Monitor error rates

5. **Performance Testing**
   - Sync 1000 transactions → <10s
   - Realtime latency → <2s
   - App startup time → <3s

**Deliverables:**
- ✅ All tests passing
- ✅ Beta feedback addressed
- ✅ Performance benchmarks met

---

### Phase 7: Cleanup (Week 3 Day 5+)

**Owner:** Bexly Team

**Tasks:**

1. **Remove Firestore Code**
   ```bash
   # Delete Firestore services
   rm -rf lib/core/database/firestore_database.dart
   rm -rf lib/core/services/sync/firestore_sync_service.dart
   ```

2. **Remove Firebase Dependencies**
   ```yaml
   # pubspec.yaml
   dependencies:
     # Remove these
     # cloud_firestore: ^x.x.x
     # firebase_auth: ^x.x.x

     # Keep FCM
     firebase_core: ^latest
     firebase_messaging: ^latest
   ```

3. **Update Documentation**
   - README: Update architecture diagram
   - API docs: Update database section
   - Changelog: Document migration

4. **Archive Firestore Data**
   - Export all Firestore data to backup
   - Keep Firestore project read-only for 30 days
   - Schedule deletion after 60 days

**Deliverables:**
- ✅ Firestore code removed
- ✅ Dependencies cleaned
- ✅ Documentation updated
- ✅ Firestore archived

---

## Rollback Plan

If migration fails, rollback steps:

1. **Stop Supabase Sync**
   ```dart
   // Disable in code
   const enableSupabaseSync = false;
   ```

2. **Re-enable Firestore**
   ```dart
   // Switch back to Firestore
   const useFirestore = true;
   ```

3. **Restore Data from Backup**
   ```bash
   # Restore Firestore from backup
   firebase firestore:restore gs://backup-bucket/2026-01-09
   ```

4. **Redeploy Previous Version**
   ```bash
   # Revert to last stable build
   git checkout v1.0.0
   flutter build apk --release
   ```

---

## Success Metrics

- ✅ 99.9% sync success rate
- ✅ <2s realtime latency
- ✅ Zero data loss
- ✅ <5% increase in app crashes
- ✅ Positive user feedback
- ✅ Cost: $0/month (vs $25/month Firebase)

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Data loss during migration | Low | High | Export Firestore before migration, verify counts |
| Auth sync issues | Medium | High | Test thoroughly with multiple accounts |
| Performance degradation | Low | Medium | Load testing before rollout |
| User complaints | Medium | Low | Beta testing, gradual rollout |
| Firestore → Supabase schema mismatch | Low | Medium | Careful schema design, data validation |

---

## Timeline Summary

| Week | Phase | Owner | Deliverables |
|------|-------|-------|--------------|
| W1 D1-2 | Schema Setup | DOS-Me Team | Bexly schema created, buckets ready |
| W1 D3-4 | Auth Migration | Bexly Team | Auth switched to DOS-Me Supabase |
| W1 D5 - W2 D3 | Database Migration | Bexly Team | Sync service + data migrated |
| W2 D4-5 | Storage Integration | Bexly Team | Storage service implemented |
| W3 D1-2 | Realtime Sync | Bexly Team | Realtime working |
| W3 D3-5 | Testing & Rollout | Bexly + QA | All tests passing, live |
| W3 D5+ | Cleanup | Bexly Team | Firestore removed |

**Total: 2-3 weeks**

---

## Cost Savings

| Item | Before | After | Savings |
|------|--------|-------|---------|
| Supabase (Bexly standalone) | $25/mo | $0/mo | $25/mo |
| Firebase Firestore | $0/mo (free tier) | $0/mo | $0/mo |
| **Total** | **$25/mo** | **$0/mo** | **$25/mo** |

**Annual Savings: $300/year** 🎉

---

## References

- [Bexly Schema for DOS-Me Supabase](../BEXLY_SCHEMA_FOR_DOSME_SUPABASE.md)
- [Firestore to Supabase Migration Guide](./FIRESTORE_TO_SUPABASE_MIGRATION.md)
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)

---

## Next Steps

1. ✅ Review this plan with DOS-Me team
2. ✅ DOS-Me team: Run schema migration
3. ✅ Bexly team: Start Phase 2 (Auth migration)
4. 🚀 Execute plan!

---

**Plan Version:** 1.0
**Date:** 2026-01-09
**Author:** Bexly Team
**Approved by:** DOS-Me Team ✅
