import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/utils/uuid_generator.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';

/// Cloud sync service using UUID v7 for globally unique IDs
///
/// Strategy:
/// - Local data: integer IDs (auto-increment)
/// - Cloud data: UUID v7 (cloudId) as document ID
/// - Mapping: cloudId stored in local database for sync
class CloudSyncService {
  final AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final String? _userId;

  CloudSyncService({
    required AppDatabase localDb,
    required FirebaseFirestore firestore,
    String? userId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _userId = userId;

  bool get isAuthenticated => _userId != null;

  /// Get reference to user's data collection
  CollectionReference get _userCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  /// Sync a wallet to Firestore
  Future<void> syncWallet(Wallet wallet) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync wallet: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Generate cloudId if not exists
      String cloudId = wallet.cloudId ?? UuidGenerator.generate();

      final data = {
        'localId': wallet.id,
        'name': wallet.name,
        'balance': wallet.balance,
        'currency': wallet.currency,
        'iconName': wallet.iconName,
        'colorHex': wallet.colorHex,
        'createdAt': Timestamp.fromDate(wallet.createdAt),
        'updatedAt': Timestamp.fromDate(wallet.updatedAt),
      };

      // Use cloudId as Firestore document ID
      await _userCollection
          .doc('wallets')
          .collection('items')
          .doc(cloudId)
          .set(data, SetOptions(merge: true));

      // Update local database with cloudId if it was just generated
      if (wallet.cloudId == null) {
        await (_localDb.update(_localDb.wallets)
              ..where((w) => w.id.equals(wallet.id)))
            .write(
          WalletsCompanion(
            cloudId: Value(cloudId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      Log.i('Synced wallet ${wallet.id} with cloudId: $cloudId', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync wallet: $e', label: 'sync');
    }
  }

  /// Sync a transaction to Firestore
  Future<void> syncTransaction(Transaction transaction) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync transaction: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Generate cloudId if not exists
      String cloudId = transaction.cloudId ?? UuidGenerator.generate();

      final data = {
        'localId': transaction.id,
        'transactionType': transaction.transactionType,
        'amount': transaction.amount,
        'date': Timestamp.fromDate(transaction.date),
        'title': transaction.title,
        'categoryId': transaction.categoryId,
        'walletId': transaction.walletId,
        'notes': transaction.notes,
        'imagePath': transaction.imagePath,
        'isRecurring': transaction.isRecurring,
        'createdAt': Timestamp.fromDate(transaction.createdAt),
        'updatedAt': Timestamp.fromDate(transaction.updatedAt),
      };

      // Use cloudId as Firestore document ID
      await _userCollection
          .doc('transactions')
          .collection('items')
          .doc(cloudId)
          .set(data, SetOptions(merge: true));

      // Update local database with cloudId if it was just generated
      if (transaction.cloudId == null) {
        await (_localDb.update(_localDb.transactions)
              ..where((t) => t.id.equals(transaction.id)))
            .write(
          TransactionsCompanion(
            cloudId: Value(cloudId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      Log.i('Synced transaction ${transaction.id} with cloudId: $cloudId', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync transaction: $e', label: 'sync');
    }
  }

  /// Sync all wallets to Firestore
  Future<void> syncAllWallets() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      final wallets = await _localDb.walletDao.getAllWallets();
      int synced = 0;

      for (final wallet in wallets) {
        await syncWallet(wallet);
        synced++;
      }

      Log.i('Synced $synced/${wallets.length} wallets', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync all wallets: $e', label: 'sync');
    }
  }

  /// Sync all transactions to Firestore
  Future<void> syncAllTransactions() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      final transactions = await _localDb.transactionDao.getAllTransactions();
      int synced = 0;

      for (final transaction in transactions) {
        await syncTransaction(transaction);
        synced++;
      }

      Log.i('Synced $synced/${transactions.length} transactions', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync all transactions: $e', label: 'sync');
    }
  }

  /// Full sync - upload all local data to cloud
  /// This is typically called after first login
  Future<void> fullSync() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      Log.i('Starting full sync to cloud...', label: 'sync');

      await syncAllWallets();
      await syncAllTransactions();

      Log.i('✅ Full sync completed successfully', label: 'sync');

      // Ensure categories exist after any full sync path
      try {
        final categories = await _localDb.categoryDao.getAllCategories();
        if (categories.isEmpty) {
          Log.i('📦 No categories found after fullSync, creating defaults...', label: 'sync');
          print('📦 [Sync] No categories after fullSync, creating defaults...');
          await CategoryPopulationService.populate(_localDb);
          final newCategories = await _localDb.categoryDao.getAllCategories();
          Log.i('✅ Created ${newCategories.length} default categories after fullSync', label: 'sync');
          print('✅ [Sync] Created ${newCategories.length} default categories after fullSync');
        }
      } catch (e) {
        Log.w('⚠️ Category ensure after fullSync failed: $e', label: 'sync');
        print('⚠️ [Sync] Category ensure after fullSync failed: $e');
      }
    } catch (e) {
      Log.e('❌ Full sync failed: $e', label: 'sync');
      rethrow;
    }
  }

  /// Delete a wallet from Firestore
  Future<void> deleteWallet(Wallet wallet) async {
    if (!isAuthenticated || wallet.cloudId == null) return;

    try {
      await _userCollection
          .doc('wallets')
          .collection('items')
          .doc(wallet.cloudId!)
          .delete();
      Log.i('Deleted wallet ${wallet.id} from cloud', label: 'sync');
    } catch (e) {
      Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
    }
  }

  /// Delete a transaction from Firestore
  Future<void> deleteTransaction(Transaction transaction) async {
    if (!isAuthenticated || transaction.cloudId == null) return;

    try {
      await _userCollection
          .doc('transactions')
          .collection('items')
          .doc(transaction.cloudId!)
          .delete();
      Log.i('Deleted transaction ${transaction.id} from cloud', label: 'sync');
    } catch (e) {
      Log.e('Failed to delete transaction from cloud: $e', label: 'sync');
    }
  }
}

/// Provider for CloudSyncService
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final localDb = ref.watch(databaseProvider);
  // IMPORTANT: Use Bexly Firebase app for Firestore, NOT dos-me (which is auth-only)
  final firestore = FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly");
  final userId = ref.watch(userIdProvider);

  return CloudSyncService(
    localDb: localDb,
    firestore: firestore,
    userId: userId,
  );
});
