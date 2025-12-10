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

  /// Sync a recurring payment to Firestore
  Future<void> syncRecurring(Recurring recurring) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync recurring: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Generate cloudId if not exists
      String cloudId = recurring.cloudId ?? UuidGenerator.generate();

      final data = {
        'localId': recurring.id,
        'name': recurring.name,
        'amount': recurring.amount,
        'currency': recurring.currency,
        'categoryId': recurring.categoryId,
        'walletId': recurring.walletId,
        'frequency': recurring.frequency,
        'startDate': Timestamp.fromDate(recurring.startDate),
        'nextDueDate': Timestamp.fromDate(recurring.nextDueDate),
        'endDate': recurring.endDate != null ? Timestamp.fromDate(recurring.endDate!) : null,
        'autoCreate': recurring.autoCreate,
        'status': recurring.status,
        'notes': recurring.notes,
        'createdAt': Timestamp.fromDate(recurring.createdAt),
        'updatedAt': Timestamp.fromDate(recurring.updatedAt),
      };

      // Use cloudId as Firestore document ID
      await _userCollection
          .doc('recurrings')
          .collection('items')
          .doc(cloudId)
          .set(data, SetOptions(merge: true));

      // Update local database with cloudId if it was just generated
      if (recurring.cloudId == null) {
        await (_localDb.update(_localDb.recurrings)
              ..where((r) => r.id.equals(recurring.id)))
            .write(
          RecurringsCompanion(
            cloudId: Value(cloudId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      Log.i('Synced recurring ${recurring.id} with cloudId: $cloudId', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync recurring: $e', label: 'sync');
    }
  }

  /// Sync a category to Firestore
  Future<void> syncCategory(Category category) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync category: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Generate cloudId if not exists
      String cloudId = category.cloudId ?? UuidGenerator.generate();

      final data = {
        'localId': category.id,
        'title': category.title,
        'icon': category.icon,
        'iconBackground': category.iconBackground,
        'iconType': category.iconType,
        'transactionType': category.transactionType,
        'parentId': category.parentId,
        'localizedTitles': category.localizedTitles,
        'createdAt': Timestamp.fromDate(category.createdAt),
        'updatedAt': Timestamp.fromDate(category.updatedAt),
      };

      // Use cloudId as document ID
      await _userCollection.doc('categories').collection('items').doc(cloudId).set(data);

      // Update local record with cloudId if it was new
      if (category.cloudId == null) {
        await (_localDb.update(_localDb.categories)
          ..where((c) => c.id.equals(category.id!)))
          .write(
            CategoriesCompanion(
              cloudId: Value(cloudId),
              updatedAt: Value(DateTime.now()),
            ),
          );
      }

      Log.i('Synced category ${category.id} with cloudId: $cloudId', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync category: $e', label: 'sync');
    }
  }

  /// Sync all categories to Firestore
  Future<void> syncAllCategories() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      final categories = await _localDb.categoryDao.getAllCategories();
      int synced = 0;

      for (final category in categories) {
        await syncCategory(category);
        synced++;
      }

      Log.i('Synced $synced/${categories.length} categories', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync all categories: $e', label: 'sync');
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

  /// Sync all recurring payments to Firestore
  Future<void> syncAllRecurrings() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      final recurrings = await _localDb.recurringDao.getAllRecurrings();
      int synced = 0;

      for (final recurring in recurrings) {
        await syncRecurring(recurring);
        synced++;
      }

      Log.i('Synced $synced/${recurrings.length} recurring payments', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync all recurrings: $e', label: 'sync');
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

      await syncAllCategories(); // Sync categories first (transactions depend on them)
      await syncAllWallets();
      await syncAllTransactions();
      await syncAllRecurrings();

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

  /// Delete a recurring payment from Firestore
  Future<void> deleteRecurring(Recurring recurring) async {
    if (!isAuthenticated || recurring.cloudId == null) return;

    try {
      await _userCollection
          .doc('recurrings')
          .collection('items')
          .doc(recurring.cloudId!)
          .delete();
      Log.i('Deleted recurring ${recurring.id} from cloud', label: 'sync');
    } catch (e) {
      Log.e('Failed to delete recurring from cloud: $e', label: 'sync');
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

