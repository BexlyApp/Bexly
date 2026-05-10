# Real-time Sync Integration Guide

This guide explains how to integrate real-time bidirectional sync into your DAO operations.

## Overview

The real-time sync system automatically syncs data between local SQLite database and Firebase Firestore using:
- **Cloud → Local**: Firestore snapshot listeners (automatic, real-time)
- **Local → Cloud**: Manual upload calls in DAO methods (this guide)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Action (UI)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  DAO Method (e.g., addWallet)                │
│  1. Save to local database (Drift/SQLite)                    │
│  2. Upload to Firestore (if authenticated)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼
┌──────────────────┐          ┌──────────────────┐
│  Local Database  │          │    Firestore     │
│  (SQLite/Drift)  │          │   (Cloud DB)     │
└──────────────────┘          └────────┬─────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │  Firestore Snapshots     │
                         │  (Auto sync to other     │
                         │   devices in real-time)  │
                         └──────────────────────────┘
```

## How to Integrate Sync into DAOs

### Step 1: Import Sync Provider

Add import to your DAO file:

```dart
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
```

### Step 2: Accept Ref Parameter

DAOs need access to Riverpod `Ref` to get sync service. Two approaches:

#### Approach A: Pass ref to individual methods (Recommended)

```dart
@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  Future<int> addWallet(WalletModel walletModel, WidgetRef ref) async {
    // 1. Save to local database first
    final companion = walletModel.toCompanion(isInsert: true);
    final id = await into(wallets).insert(companion);

    // 2. Upload to cloud (if authenticated)
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      final savedWallet = await getWalletById(id);
      if (savedWallet != null) {
        await syncService.uploadWallet(savedWallet.toModel());
      }
    } catch (e) {
      Log.e('Failed to upload wallet to cloud: $e', label: 'sync');
      // Don't throw - local save succeeded, cloud sync will retry later
    }

    return id;
  }
}
```

#### Approach B: Store ref in DAO (if many methods need it)

```dart
@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  final Ref _ref;

  WalletDao(super.db, this._ref);

  Future<int> addWallet(WalletModel walletModel) async {
    // Same implementation, but use this._ref instead of parameter
    final syncService = _ref.read(realtimeSyncServiceProvider);
    // ...
  }
}
```

### Step 3: Integrate Upload Calls

Add sync upload calls to these DAO methods:

#### Create Operations

```dart
Future<int> addWallet(WalletModel walletModel, WidgetRef ref) async {
  // 1. Save to local database
  final companion = walletModel.toCompanion(isInsert: true);
  final id = await into(wallets).insert(companion);

  // 2. Upload to cloud
  try {
    final syncService = ref.read(realtimeSyncServiceProvider);
    final savedWallet = await getWalletById(id);
    if (savedWallet != null) {
      await syncService.uploadWallet(savedWallet.toModel());
    }
  } catch (e) {
    Log.e('Failed to upload wallet: $e', label: 'sync');
  }

  return id;
}
```

#### Update Operations

```dart
Future<bool> updateWallet(WalletModel walletModel, WidgetRef ref) async {
  // 1. Update local database
  final companion = walletModel.toCompanion();
  final success = await update(wallets).replace(companion);

  // 2. Upload to cloud
  if (success) {
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      await syncService.uploadWallet(walletModel);
    } catch (e) {
      Log.e('Failed to upload wallet update: $e', label: 'sync');
    }
  }

  return success;
}
```

#### Delete Operations

```dart
Future<int> deleteWallet(int id, WidgetRef ref) async {
  // 1. Get wallet to get cloudId
  final wallet = await getWalletById(id);

  // 2. Delete from local database
  final count = await (delete(wallets)..where((w) => w.id.equals(id))).go();

  // 3. Delete from cloud (if has cloudId)
  if (count > 0 && wallet != null && wallet.cloudId != null) {
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      await syncService.deleteWalletFromCloud(wallet.cloudId!);
    } catch (e) {
      Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
    }
  }

  return count;
}
```

## Complete Example: WalletDao with Sync

```dart
import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  // Read operations (no sync needed)
  Stream<List<WalletModel>> watchAllWallets() {
    return select(wallets).watch().asyncMap((walletList) async {
      return walletList.map((e) => e.toModel()).toList();
    });
  }

  Future<Wallet?> getWalletById(int id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  // Create operation with sync
  Future<int> addWallet(WalletModel walletModel, WidgetRef ref) async {
    Log.d('Saving New Wallet: ${walletModel.toJson()}', label: 'wallet');

    // 1. Save to local database
    final companion = walletModel.toCompanion(isInsert: true);
    final id = await into(wallets).insert(companion);

    // 2. Upload to cloud
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      final savedWallet = await getWalletById(id);
      if (savedWallet != null) {
        await syncService.uploadWallet(savedWallet.toModel());
      }
    } catch (e) {
      Log.e('Failed to upload wallet to cloud: $e', label: 'sync');
      // Don't rethrow - local save succeeded
    }

    return id;
  }

  // Update operation with sync
  Future<bool> updateWallet(WalletModel walletModel, WidgetRef ref) async {
    Log.d('Updating Wallet: ${walletModel.toJson()}', label: 'wallet');

    if (walletModel.id == null) {
      Log.e('Wallet ID is null, cannot update.');
      return false;
    }

    // 1. Update local database
    final companion = walletModel.toCompanion();
    final success = await update(wallets).replace(companion);

    // 2. Upload to cloud
    if (success) {
      try {
        final syncService = ref.read(realtimeSyncServiceProvider);
        await syncService.uploadWallet(walletModel);
      } catch (e) {
        Log.e('Failed to upload wallet update to cloud: $e', label: 'sync');
      }
    }

    return success;
  }

  // Delete operation with sync
  Future<int> deleteWallet(int id, WidgetRef ref) async {
    Log.d('Deleting Wallet with ID: $id', label: 'wallet');

    // 1. Get wallet to retrieve cloudId
    final wallet = await getWalletById(id);

    // 2. Delete from local database
    final count = await (delete(wallets)..where((w) => w.id.equals(id))).go();

    // 3. Delete from cloud
    if (count > 0 && wallet != null && wallet.cloudId != null) {
      try {
        final syncService = ref.read(realtimeSyncServiceProvider);
        await syncService.deleteWalletFromCloud(wallet.cloudId!);
      } catch (e) {
        Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
      }
    }

    return count;
  }
}
```

## Updating UI Code

When calling DAO methods from UI, pass `ref`:

### Before (without sync):
```dart
class WalletProvider extends StateNotifier<AsyncValue<List<WalletModel>>> {
  final WalletDao _dao;

  Future<void> addWallet(WalletModel wallet) async {
    await _dao.addWallet(wallet);
  }
}
```

### After (with sync):
```dart
class WalletProvider extends StateNotifier<AsyncValue<List<WalletModel>>> {
  final WalletDao _dao;
  final Ref _ref;

  WalletProvider(this._dao, this._ref) : super(const AsyncValue.loading());

  Future<void> addWallet(WalletModel wallet) async {
    await _dao.addWallet(wallet, _ref);
  }
}
```

## Error Handling Strategy

**Important**: Always save to local database first, then sync to cloud.

```dart
Future<int> addWallet(WalletModel walletModel, WidgetRef ref) async {
  // 1. Save to local database FIRST
  final id = await into(wallets).insert(companion);

  // 2. Try to sync to cloud
  try {
    final syncService = ref.read(realtimeSyncServiceProvider);
    await syncService.uploadWallet(savedWallet.toModel());
  } catch (e) {
    // Log error but DON'T rethrow
    Log.e('Failed to upload: $e', label: 'sync');
    // Local save succeeded - user can continue using app
    // Sync will retry when connection restored
  }

  return id;
}
```

**Why?**
- App works offline
- User doesn't see errors if cloud sync fails
- Data is safe locally
- Sync will catch up when connection restored

## Testing Sync

### Test Real-time Sync (Cloud → Local)

1. Login to same account on 2 devices
2. Create wallet on Device A
3. Verify wallet appears on Device B in real-time (< 1 second)

### Test Upload (Local → Cloud)

1. Login on Device A
2. Create wallet on Device A
3. Check Firestore console - wallet should appear immediately
4. Open Device B - wallet should sync down automatically

### Test Offline Mode

1. Turn off wifi on Device A
2. Create wallet on Device A (saves locally)
3. Turn on wifi
4. Verify wallet syncs to cloud
5. Verify wallet appears on Device B

## Migration Checklist

To add sync to existing DAO:

- [ ] Import sync provider
- [ ] Add `WidgetRef ref` parameter to create/update/delete methods
- [ ] Add upload call after local save in create method
- [ ] Add upload call after local update in update method
- [ ] Get cloudId and call delete in delete method
- [ ] Update all callers to pass `ref`
- [ ] Test create/update/delete operations
- [ ] Test offline mode
- [ ] Test cross-device sync

## Available Sync Methods

```dart
// Wallets
await syncService.uploadWallet(WalletModel wallet);
await syncService.deleteWalletFromCloud(String cloudId);

// Categories
await syncService.uploadCategory(CategoryModel category);
await syncService.deleteCategoryFromCloud(String cloudId);

// Transactions
await syncService.uploadTransaction(TransactionModel transaction);
await syncService.deleteTransactionFromCloud(String cloudId);

// Budgets
await syncService.uploadBudget(BudgetModel budget);
await syncService.deleteBudgetFromCloud(String cloudId);

// Goals
await syncService.uploadGoal(GoalModel goal);
await syncService.deleteGoalFromCloud(String cloudId);
```

## Notes

- Sync is **automatic** for Cloud → Local (Firestore snapshots)
- Sync is **manual** for Local → Cloud (call upload methods in DAOs)
- CloudId is **auto-generated** (UUID v7) if not exists
- Conflict resolution uses **Last-Write-Wins** (compares `updatedAt` timestamps)
- Sync only works when **authenticated** (gracefully skips if offline/logged out)
- **Foreign keys** are handled automatically (e.g., uploading transaction auto-uploads category/wallet)

## Troubleshooting

### Sync not working?

1. Check user is authenticated: `FirebaseAuth.instance.currentUser != null`
2. Check sync is running: `ref.read(isSyncActiveProvider)`
3. Check Firestore rules allow read/write
4. Check logs for errors (filter by `label: 'sync'`)

### Data not appearing on other device?

1. Verify both devices logged into same account
2. Check Firestore console - data should be there
3. Check logs on receiving device for sync errors
4. Try logout/login to force re-sync

### Upload fails silently?

Check logs - uploads are wrapped in try-catch and logged but don't throw to avoid breaking user experience.
