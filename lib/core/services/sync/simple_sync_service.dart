import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';

/// Simple one-way sync service that uploads local data to Firestore
/// when user is authenticated
class SimpleSyncService {
  final AppDatabase _localDb;
  final firestore.FirebaseFirestore _firestore;
  final String? _userId;

  SimpleSyncService({
    required AppDatabase localDb,
    required firestore.FirebaseFirestore firestore,
    String? userId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _userId = userId;

  bool get isAuthenticated => _userId != null;

  /// Get reference to user's data collection
  firestore.CollectionReference get _userCollection {
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
      final data = {
        'id': wallet.id,
        'name': wallet.name,
        'balance': wallet.balance,
        'currency': wallet.currency,
        'iconName': wallet.iconName,
        'colorHex': wallet.colorHex,
        'createdAt': firestore.Timestamp.fromDate(wallet.createdAt),
        'updatedAt': firestore.Timestamp.fromDate(wallet.updatedAt),
      };

      await _userCollection
          .doc('wallets')
          .collection('items')
          .doc(wallet.id.toString())
          .set(data, firestore.SetOptions(merge: true));

      Log.i('Synced wallet ${wallet.id}', label: 'sync');
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
      final data = {
        'id': transaction.id,
        'transactionType': transaction.transactionType,
        'amount': transaction.amount,
        'date': firestore.Timestamp.fromDate(transaction.date),
        'title': transaction.title,
        'categoryId': transaction.categoryId,
        'walletId': transaction.walletId,
        'notes': transaction.notes,
        'imagePath': transaction.imagePath,
        'isRecurring': transaction.isRecurring,
        'createdAt': firestore.Timestamp.fromDate(transaction.createdAt),
        'updatedAt': firestore.Timestamp.fromDate(transaction.updatedAt),
      };

      await _userCollection
          .doc('transactions')
          .collection('items')
          .doc(transaction.id.toString())
          .set(data, firestore.SetOptions(merge: true));

      Log.i('Synced transaction ${transaction.id}', label: 'sync');
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
      for (final wallet in wallets) {
        await syncWallet(wallet);
      }
      Log.i('Synced ${wallets.length} wallets', label: 'sync');
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
      for (final transaction in transactions) {
        await syncTransaction(transaction);
      }
      Log.i('Synced ${transactions.length} transactions', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync all transactions: $e', label: 'sync');
    }
  }

  /// Full sync - upload all local data to cloud
  Future<void> fullSync() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      Log.i('Starting full sync...', label: 'sync');
      await syncAllWallets();
      await syncAllTransactions();
      Log.i('Full sync completed', label: 'sync');

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
      Log.e('Full sync failed: $e', label: 'sync');
      rethrow;
    }
  }

  /// Delete a wallet from Firestore
  Future<void> deleteWallet(int walletId) async {
    if (!isAuthenticated) return;

    try {
      await _userCollection
          .doc('wallets')
          .collection('items')
          .doc(walletId.toString())
          .delete();
      Log.i('Deleted wallet $walletId from cloud', label: 'sync');
    } catch (e) {
      Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
    }
  }

  /// Delete a transaction from Firestore
  Future<void> deleteTransaction(int transactionId) async {
    if (!isAuthenticated) return;

    try {
      await _userCollection
          .doc('transactions')
          .collection('items')
          .doc(transactionId.toString())
          .delete();
      Log.i('Deleted transaction $transactionId from cloud', label: 'sync');
    } catch (e) {
      Log.e('Failed to delete transaction from cloud: $e', label: 'sync');
    }
  }
}

/// Provider for SimpleSyncService
final simpleSyncServiceProvider = Provider<SimpleSyncService>((ref) {
  final localDb = ref.watch(databaseProvider);
  // IMPORTANT: Use Bexly Firebase app for Firestore, NOT dos-me (which is auth-only)
  final firestoreInstance = firestore.FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly");
  final userId = ref.watch(userIdProvider);

  return SimpleSyncService(
    localDb: localDb,
    firestore: firestoreInstance,
    userId: userId,
  );
});
