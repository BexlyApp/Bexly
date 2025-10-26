import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';

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

  Future<List<Wallet>> getWalletsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(wallets)..where((w) => w.id.isIn(ids))).get();
  }

  Future<int> addWallet(WalletModel walletModel) async {
    Log.d('Saving New Wallet: ${walletModel.toJson()}', label: 'wallet');

    // 1. Save to local database
    final companion = walletModel.toCompanion(isInsert: true);
    final id = await into(wallets).insert(companion);

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        final savedWallet = await getWalletById(id);
        if (savedWallet != null) {
          await syncService.uploadWallet(savedWallet.toModel());
        }
      } catch (e, stack) {
        Log.e('Failed to upload wallet to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local save succeeded
      }
    }

    return id;
  }

  Future<bool> updateWallet(WalletModel walletModel) async {
    Log.d('Updating Wallet: ${walletModel.toJson()}', label: 'wallet');
    if (walletModel.id == null) {
      Log.e('Wallet ID is null, cannot update.');
      return false;
    }

    // 1. Update local database
    final companion = walletModel.toCompanion();
    final success = await update(wallets).replace(companion);

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadWallet(walletModel);
      } catch (e, stack) {
        Log.e('Failed to upload wallet update to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local update succeeded
      }
    }

    return success;
  }

  /// Deletes a wallet by its ID.
  Future<int> deleteWallet(int id) async {
    Log.d('Deleting Wallet with ID: $id', label: 'wallet');

    // 1. Get wallet to retrieve cloudId
    final wallet = await getWalletById(id);

    // 2. Delete from local database
    final count = await (delete(wallets)..where((w) => w.id.equals(id))).go();

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && wallet != null && wallet.cloudId != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.deleteWalletFromCloud(wallet.cloudId!);
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
      iconName: Value(walletModel.iconName),
      colorHex: Value(walletModel.colorHex),
      createdAt: walletModel.id == null
          ? Value(DateTime.now())
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await into(wallets).insertOnConflictUpdate(companion);
  }
}
