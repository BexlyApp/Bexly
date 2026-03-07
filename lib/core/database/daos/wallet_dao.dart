import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/utils/retry_helper.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  final Ref? _ref;

  WalletDao(super.db, [this._ref]);

  WalletModel _mapToWalletModel(Wallet walletData) {
    return walletData.toModel();
  }

  Stream<List<WalletModel>> watchAllWallets() {
    Log.d('Subscribing to watchAllWallets()', label: 'wallet');
    return select(wallets).watch().asyncMap((walletList) async {
      Log.d(
        'watchAllWallets emitted ${walletList.length} rows',
        label: 'wallet',
      );
      return walletList.map((e) => e.toModel()).toList();
    });
  }

  Stream<WalletModel?> watchWalletById(int id) {
    Log.d('Subscribing to watchWalletById($id)', label: 'wallet');
    return (select(wallets)..where((w) => w.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((walletData) async {
          if (walletData == null) return null;
          return _mapToWalletModel(walletData);
        });
  }

  /// Fetches all wallets.
  Future<List<Wallet>> getAllWallets() {
    return select(wallets).get();
  }

  Future<Wallet?> getWalletById(int id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  /// Get wallet by cloud ID (for sync operations)
  Future<Wallet?> getWalletByCloudId(String cloudId) {
    return (select(wallets)..where((w) => w.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  /// Get wallet by name (used as fallback during cloud sync)
  Future<Wallet?> getWalletByName(String name) {
    return (select(wallets)..where((w) => w.name.equals(name)))
        .getSingleOrNull();
  }

  /// Delete local wallet by cloud ID (used when cloud marks wallet as inactive)
  Future<void> deleteByCloudId(String cloudId) async {
    await (delete(wallets)..where((w) => w.cloudId.equals(cloudId))).go();
  }

  Future<List<Wallet>> getWalletsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(wallets)..where((w) => w.id.isIn(ids))).get();
  }

  Future<int> addWallet(WalletModel walletModel) async {
    Log.d('Saving New Wallet: ${walletModel.toJson()}', label: 'wallet');

    // Check if this is the first wallet (before inserting)
    final existingWallets = await getAllWallets();
    final isFirstWallet = existingWallets.isEmpty;

    // 1. Generate cloudId IMMEDIATELY to prevent race condition with sync
    final cloudId = walletModel.cloudId ?? const Uuid().v7();
    Log.d('Generated cloudId: $cloudId for wallet: ${walletModel.name}', label: 'wallet');

    // 2. Save to local database WITH cloudId
    final companion = WalletsCompanion(
      cloudId: Value(cloudId), // CRITICAL: Set cloudId at insert time!
      name: Value(walletModel.name),
      balance: Value(walletModel.balance),
      initialBalance: Value(walletModel.initialBalance),
      currency: Value(walletModel.currency),
      iconName: Value(walletModel.iconName),
      colorHex: Value(walletModel.colorHex),
      walletType: Value(walletModel.walletType.toDbString()),
      creditLimit: walletModel.creditLimit != null ? Value(walletModel.creditLimit) : const Value.absent(),
      billingDay: walletModel.billingDay != null ? Value(walletModel.billingDay) : const Value.absent(),
      interestRate: walletModel.interestRate != null ? Value(walletModel.interestRate) : const Value.absent(),
      ownerUserId: walletModel.ownerUserId != null ? Value(walletModel.ownerUserId) : const Value.absent(),
      isShared: Value(walletModel.isShared),
      createdAt: Value(walletModel.createdAt ?? DateTime.now()),
      updatedAt: Value(walletModel.updatedAt ?? DateTime.now()),
    );
    final id = await into(wallets).insert(companion);

    // 2. Set default wallet if this is the first wallet
    if (isFirstWallet && _ref != null) {
      try {
        await _ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(id);
        Log.d('Set default wallet to $id (first wallet)', label: 'wallet');
      } catch (e) {
        Log.e('Failed to set default wallet: $e', label: 'wallet');
      }
    }

    // 3. Upload to cloud with retry (if sync available)
    Log.d('🔍 Checking sync availability for wallet: ${walletModel.name}', label: 'sync');
    Log.d('   → _ref: ${_ref != null ? "EXISTS" : "NULL"}', label: 'sync');

    if (_ref != null) {
      Log.d('   → Calling _uploadWalletWithRetry for cloudId: $cloudId', label: 'sync');
      // Fire and forget upload (don't block UI)
      _uploadWalletWithRetry(id, cloudId).catchError((e) {
        Log.e('❌ Failed to upload wallet: $e', label: 'sync');
      });
    } else {
      Log.w('⚠️ CANNOT SYNC: _ref is NULL! Wallet created without Riverpod ref', label: 'sync');
    }

    return id;
  }

  Future<bool> updateWallet(WalletModel walletModel) async {
    Log.d('Updating Wallet: ${walletModel.toJson()}', label: 'wallet');
    Log.d('  → walletType: ${walletModel.walletType.name}', label: 'wallet');
    if (walletModel.id == null) {
      Log.e('Wallet ID is null, cannot update.');
      return false;
    }

    // 1. Update local database
    final companion = walletModel.toCompanion();
    final success = await update(wallets).replace(companion);

    // 2. Upload to cloud with retry (if sync available)
    if (success && _ref != null && walletModel.id != null) {
      // Fire and forget upload (don't block UI)
      _uploadWalletWithRetry(walletModel.id!, walletModel.cloudId ?? '').catchError((e) {
        Log.e('Failed to upload wallet update: $e', label: 'sync');
      });
    }

    return success;
  }

  /// Deletes a wallet by its ID.
  /// Get the number of transactions associated with a wallet.
  Future<int> getTransactionCount(int walletId) async {
    return await (db.selectOnly(db.transactions)
      ..addColumns([db.transactions.id.count()])
      ..where(db.transactions.walletId.equals(walletId)))
      .getSingle()
      .then((row) => row.read(db.transactions.id.count()) ?? 0);
  }

  /// Get total count of all related data (transactions, budgets, recurrings) for a wallet.
  Future<int> getRelatedDataCount(int walletId) async {
    final txCount = await getTransactionCount(walletId);
    final budgetCount = await (db.selectOnly(db.budgets)
      ..addColumns([db.budgets.id.count()])
      ..where(db.budgets.walletId.equals(walletId)))
      .getSingle()
      .then((row) => row.read(db.budgets.id.count()) ?? 0);
    final recurringCount = await (db.selectOnly(db.recurrings)
      ..addColumns([db.recurrings.id.count()])
      ..where(db.recurrings.walletId.equals(walletId)))
      .getSingle()
      .then((row) => row.read(db.recurrings.id.count()) ?? 0);
    return txCount + budgetCount + recurringCount;
  }

  /// Reassign all wallet-related data from one wallet to another.
  Future<int> reassignWalletData(int fromWalletId, int toWalletId) async {
    Log.d('Reassigning all data from wallet $fromWalletId to $toWalletId', label: 'wallet');
    final txCount = await (db.update(db.transactions)
      ..where((t) => t.walletId.equals(fromWalletId)))
      .write(TransactionsCompanion(walletId: Value(toWalletId)));
    await (db.update(db.budgets)
      ..where((b) => b.walletId.equals(fromWalletId)))
      .write(BudgetsCompanion(walletId: Value(toWalletId)));
    await (db.update(db.recurrings)
      ..where((r) => r.walletId.equals(fromWalletId)))
      .write(RecurringsCompanion(walletId: Value(toWalletId)));
    await (db.delete(db.sharedWallets)..where((s) => s.walletId.equals(fromWalletId))).go();
    return txCount;
  }

  /// Force delete a wallet and all its related data.
  Future<int> forceDeleteWallet(int id) async {
    Log.d('Force deleting wallet $id and all related data', label: 'wallet');

    // 1. Delete all related records that reference this wallet
    await (db.delete(db.transactions)..where((t) => t.walletId.equals(id))).go();
    await (db.delete(db.budgets)..where((b) => b.walletId.equals(id))).go();
    await (db.delete(db.recurrings)..where((r) => r.walletId.equals(id))).go();
    await (db.delete(db.sharedWallets)..where((s) => s.walletId.equals(id))).go();

    // 2. Get wallet for cloud cleanup
    final wallet = await getWalletById(id);

    // 3. Delete wallet locally
    final count = await (delete(wallets)..where((w) => w.id.equals(id))).go();

    // 4. Delete from cloud
    if (count > 0 && _ref != null && wallet != null && wallet.cloudId != null) {
      try {
        await _deleteWalletFromCloud(wallet.cloudId!);
      } catch (e, stack) {
        Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
      }
    }

    return count;
  }

  /// Throws an exception if there are transactions associated with this wallet.
  Future<int> deleteWallet(int id) async {
    Log.d('Deleting Wallet with ID: $id', label: 'wallet');

    // 1. Check for associated transactions
    final transactionCount = await (db.selectOnly(db.transactions)
      ..addColumns([db.transactions.id.count()])
      ..where(db.transactions.walletId.equals(id)))
      .getSingle()
      .then((row) => row.read(db.transactions.id.count()) ?? 0);

    if (transactionCount > 0) {
      Log.e('Cannot delete wallet $id: has $transactionCount associated transactions', label: 'wallet');
      throw Exception('Cannot delete wallet: $transactionCount transaction(s) still associated. Please delete or reassign transactions first.');
    }

    // 2. Clean up related records (budgets, recurrings, shared_wallets)
    await (db.delete(db.budgets)..where((b) => b.walletId.equals(id))).go();
    await (db.delete(db.recurrings)..where((r) => r.walletId.equals(id))).go();
    await (db.delete(db.sharedWallets)..where((s) => s.walletId.equals(id))).go();

    // 3. Get wallet to retrieve cloudId
    final wallet = await getWalletById(id);

    // 4. Delete from local database
    final count = await (delete(wallets)..where((w) => w.id.equals(id))).go();

    // 5. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && wallet != null && wallet.cloudId != null) {
      try {
        await _deleteWalletFromCloud(wallet.cloudId!);
      } catch (e, stack) {
        Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return count;
  }

  Future<void> upsertWallet(WalletModel walletModel) async {
    Log.d('Upserting Wallet: ${walletModel.toJson()}', label: 'wallet');
    Log.d('  → walletType: ${walletModel.walletType.name}', label: 'wallet');

    // For upsert, if ID is null, it's an insert.
    // If ID is present, it's an update on conflict.
    // The toCompanion handles Value.absent() for ID on insert.
    final companion = WalletsCompanion(
      id: walletModel.id == null
          ? const Value.absent()
          : Value(walletModel.id!),
      name: Value(walletModel.name.trim()),
      balance: Value(walletModel.balance),
      currency: Value(walletModel.currency),
      walletType: Value(walletModel.walletType.name), // FIXED: Add wallet_type
      iconName: Value(walletModel.iconName),
      colorHex: Value(walletModel.colorHex),
      createdAt: walletModel.id == null
          ? Value(DateTime.now())
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await into(wallets).insertOnConflictUpdate(companion);
  }

  /// Create or update wallet (used by sync service to pull from cloud)
  /// Uses cloudId to find existing wallet, or creates new one
  /// NOTE: This method does NOT sync back to cloud (to avoid infinite loop)
  Future<void> createOrUpdateWallet(WalletModel walletModel) async {
    Log.d('Creating or updating wallet from cloud: ${walletModel.cloudId}', label: 'wallet');

    // Check if wallet exists by cloudId
    final existingWallet = walletModel.cloudId != null
        ? await getWalletByCloudId(walletModel.cloudId!)
        : null;

    if (existingWallet != null) {
      // Update existing wallet (local only, no cloud sync)
      final updatedModel = walletModel.copyWith(id: existingWallet.id);
      final companion = updatedModel.toCompanion();
      await update(wallets).replace(companion);
      Log.d('Updated existing wallet ${existingWallet.id} from cloud', label: 'wallet');
    } else {
      // Fallback: check by name to handle cloud duplicate wallet scenario
      final existingByName = await getWalletByName(walletModel.name);
      if (existingByName != null) {
        // Link existing local wallet to this cloud record (re-associate cloud_id)
        final updatedModel = walletModel.copyWith(id: existingByName.id);
        final companion = updatedModel.toCompanion();
        await update(wallets).replace(companion);
        Log.d('Linked existing wallet ${existingByName.id} to cloud id ${walletModel.cloudId}', label: 'wallet');
      } else {
        // Create new wallet (local only, no cloud sync)
        final companion = walletModel.toCompanion(isInsert: true);
        final id = await into(wallets).insert(companion);
        Log.d('Created new wallet $id from cloud', label: 'wallet');
      }
    }
  }

  /// Recalculate wallet balance from transactions
  /// This should be called after syncing transactions from cloud
  Future<void> recalculateBalance(int walletId) async {
    Log.d('Recalculating balance for wallet $walletId', label: 'wallet');

    // Get all transactions for this wallet
    final transactions = await (db.select(db.transactions)
      ..where((t) => t.walletId.equals(walletId)))
      .get();

    // Calculate balance: income - expense
    // transactionType: 0 = income, 1 = expense, 2 = transfer
    double balance = 0.0;
    for (final tx in transactions) {
      if (tx.transactionType == 0) { // income
        balance += tx.amount;
      } else if (tx.transactionType == 1) { // expense
        balance -= tx.amount;
      }
      // transfer is handled separately, ignore for now
    }

    // Update wallet balance
    await (update(wallets)..where((w) => w.id.equals(walletId)))
        .write(WalletsCompanion(balance: Value(balance)));

    Log.i('Wallet $walletId balance recalculated: $balance from ${transactions.length} transactions', label: 'wallet');
  }

  /// Recalculate all wallets' balances from transactions
  Future<void> recalculateAllBalances() async {
    Log.d('Recalculating balances for all wallets', label: 'wallet');

    final allWallets = await getAllWallets();
    for (final wallet in allWallets) {
      await recalculateBalance(wallet.id);
    }

    Log.i('Recalculated balances for ${allWallets.length} wallets', label: 'wallet');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPLOAD HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Upload wallet with retry logic (fire and forget)
  Future<void> _uploadWalletWithRetry(int walletId, String cloudId) async {
    return RetryHelper.retry(
      operationName: 'Upload wallet $cloudId',
      operation: () async {
        final wallet = await getWalletById(walletId);
        if (wallet == null) {
          throw Exception('Wallet $walletId not found');
        }
        await _syncWalletToCloud(wallet.toModel());
        Log.d('✅ Wallet uploaded: ${wallet.name}', label: 'sync');
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLOUD SYNC HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Sync wallet to cloud (Supabase + Firebase for backward compatibility)
  Future<void> _syncWalletToCloud(WalletModel wallet) async {
    if (_ref == null) return;

    // Try Supabase first (primary sync method)
    try {
      final supabaseSync = _ref.read(supabaseSyncServiceProvider);
      if (supabaseSync.isAuthenticated) {
        await supabaseSync.uploadWallet(wallet);
        Log.d('Wallet synced to Supabase', label: 'sync');
        return; // Success, no need to try Firebase
      }
    } catch (e) {
      Log.w('Supabase sync failed, trying Firebase: $e', label: 'sync');
    }

    // Fallback to Firebase if Supabase fails
    try {
      final firebaseSync = _ref.read(realtimeSyncServiceProvider);
      if (firebaseSync != null && firebaseSync.isAuthenticated) {
        await firebaseSync.uploadWallet(wallet);
        Log.d('Wallet synced to Firebase', label: 'sync');
      }
    } catch (e) {
      Log.e('Firebase sync also failed: $e', label: 'sync');
      rethrow;
    }
  }

  /// Delete wallet from cloud (Supabase + Firebase)
  Future<void> _deleteWalletFromCloud(String cloudId) async {
    if (_ref == null) return;

    // Try Supabase first
    try {
      final supabaseSync = _ref.read(supabaseSyncServiceProvider);
      if (supabaseSync.isAuthenticated) {
        await supabaseSync.deleteWalletFromCloud(cloudId);
        Log.d('Wallet deleted from Supabase', label: 'sync');
        return;
      }
    } catch (e) {
      Log.w('Supabase delete failed, trying Firebase: $e', label: 'sync');
    }

    // Fallback to Firebase
    try {
      final firebaseSync = _ref.read(realtimeSyncServiceProvider);
      if (firebaseSync != null && firebaseSync.isAuthenticated) {
        await firebaseSync.deleteWalletFromCloud(cloudId);
        Log.d('Wallet deleted from Firebase', label: 'sync');
      }
    } catch (e) {
      Log.e('Firebase delete also failed: $e', label: 'sync');
      rethrow;
    }
  }
}
