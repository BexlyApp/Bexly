import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/data_population_service/wallet_population_service.dart';

/// Data structure for sync conflict information
class SyncConflictInfo {
  final int localItemCount;
  final int cloudItemCount;
  final DateTime? localLastUpdate;
  final DateTime? cloudLastUpdate;
  final String? latestLocalTransaction;
  final String? latestCloudTransaction;
  final int localWalletCount;
  final int cloudWalletCount;
  final int localTransactionCount;
  final int cloudTransactionCount;

  SyncConflictInfo({
    required this.localItemCount,
    required this.cloudItemCount,
    this.localLastUpdate,
    this.cloudLastUpdate,
    this.latestLocalTransaction,
    this.latestCloudTransaction,
    required this.localWalletCount,
    required this.cloudWalletCount,
    required this.localTransactionCount,
    required this.cloudTransactionCount,
  });
}

/// Service to handle conflict detection and resolution
class ConflictResolutionService {
  final AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final String _userId;
  final WalletDao? _walletDao;

  ConflictResolutionService({
    required AppDatabase localDb,
    required FirebaseFirestore firestore,
    required String userId,
    WalletDao? walletDao,
  })  : _localDb = localDb,
        _firestore = firestore,
        _userId = userId,
        _walletDao = walletDao;

  /// Get user's data collection reference
  CollectionReference get _userCollection {
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  /// Check if there's a conflict between local and cloud data
  Future<SyncConflictInfo?> detectConflict() async {
    try {
      // Check if cloud data exists
      Log.i('🔍 Querying cloud wallets (limit 1)...', label: 'sync');
      final cloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ Cloud wallets query completed: ${cloudWallets.docs.length} docs', label: 'sync');

      Log.i('🔍 Querying cloud transactions (limit 1)...', label: 'sync');
      final cloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ Cloud transactions query completed: ${cloudTransactions.docs.length} docs', label: 'sync');

      // If no cloud data exists, no conflict
      if (cloudWallets.docs.isEmpty && cloudTransactions.docs.isEmpty) {
        Log.i('No cloud data found, no conflict', label: 'sync');
        return null;
      }

      // Get local data counts
      final localWallets = await _localDb.walletDao.getAllWallets();
      final localTransactions = await _localDb.transactionDao.getAllTransactions();

      // If no local data, no conflict (can safely download cloud data)
      if (localWallets.isEmpty && localTransactions.isEmpty) {
        Log.i('No local data found, no conflict', label: 'sync');
        return null;
      }

      // Both local and cloud have data - potential conflict detected!
      Log.w('Potential conflict: both local and cloud have data', label: 'sync');

      // Get cloud data counts and latest updates
      Log.i('🔍 Querying all cloud wallets...', label: 'sync');
      final allCloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ All cloud wallets query completed: ${allCloudWallets.docs.length} docs', label: 'sync');

      // Fetch all cloud transactions and find latest locally (no orderBy to avoid index requirement)
      Log.i('🔍 Querying all cloud transactions...', label: 'sync');
      final allCloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ All cloud transactions query completed: ${allCloudTransactions.docs.length} docs', label: 'sync');

      // AUTO-RESOLVE LOGIC: Check if this is a trivial conflict that can be auto-resolved
      final localWalletCount = localWallets.length;
      final cloudWalletCount = allCloudWallets.docs.length;
      final localTxCount = localTransactions.length;
      final cloudTxCount = allCloudTransactions.docs.length;

      // Rule 1: If both have same counts and ZERO transactions -> Auto-merge (no data loss risk)
      if (localWalletCount == cloudWalletCount && localTxCount == 0 && cloudTxCount == 0) {
        Log.i('✅ Auto-resolve: Same wallet count ($localWalletCount) and no transactions on either side. No conflict needed.', label: 'sync');
        return null; // No conflict dialog needed
      }

      // Rule 2: If one side has ONLY wallets (no transactions) and counts match -> Prefer the side with more recent data or just merge
      if (localTxCount == 0 && cloudTxCount == 0 && localWalletCount == cloudWalletCount) {
        Log.i('✅ Auto-resolve: Both sides have $localWalletCount wallet(s) and 0 transactions. Safe to merge.', label: 'sync');
        return null;
      }

      // If we reach here, it's a real conflict that needs user decision
      Log.w('⚠️ Real conflict detected - user decision required', label: 'sync');

      // Get latest transaction info
      String? latestLocalTx;
      DateTime? localLastUpdate;
      if (localTransactions.isNotEmpty) {
        final latest = localTransactions.reduce((a, b) =>
            a.updatedAt.isAfter(b.updatedAt) ? a : b);
        latestLocalTx = '${latest.title} (${latest.amount})';
        localLastUpdate = latest.updatedAt;
      }

      // Find latest cloud transaction by iterating (instead of using orderBy)
      String? latestCloudTx;
      DateTime? cloudLastUpdate;
      if (allCloudTransactions.docs.isNotEmpty) {
        for (final doc in allCloudTransactions.docs) {
          final data = doc.data();
          final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
          if (updatedAt != null && (cloudLastUpdate == null || updatedAt.isAfter(cloudLastUpdate))) {
            cloudLastUpdate = updatedAt;
            latestCloudTx = '${data['title']} (${data['amount']})';
          }
        }
      }

      return SyncConflictInfo(
        localItemCount: localWallets.length + localTransactions.length,
        cloudItemCount: allCloudWallets.docs.length + allCloudTransactions.docs.length,
        localLastUpdate: localLastUpdate,
        cloudLastUpdate: cloudLastUpdate,
        latestLocalTransaction: latestLocalTx,
        latestCloudTransaction: latestCloudTx,
        localWalletCount: localWallets.length,
        cloudWalletCount: allCloudWallets.docs.length,
        localTransactionCount: localTransactions.length,
        cloudTransactionCount: allCloudTransactions.docs.length,
      );
    } catch (e) {
      Log.e('Error detecting conflict: $e', label: 'sync');
      return null;
    }
  }

  /// Replace local data with cloud data
  Future<void> useCloudData() async {
    try {
      Log.i('Using cloud data, clearing local data...', label: 'sync');

      // Clear all local data EXCEPT system default categories
      await _localDb.transaction(() async {
        await _localDb.delete(_localDb.transactions).go();
        await _localDb.delete(_localDb.wallets).go();
        // CRITICAL: Only delete non-system categories to preserve defaults
        await (_localDb.delete(_localDb.categories)
          ..where((c) => c.isSystemDefault.equals(false)))
          .go();
        await _localDb.delete(_localDb.budgets).go();
        await _localDb.delete(_localDb.goals).go();
        await _localDb.delete(_localDb.checklistItems).go();
      });

      // Download cloud data
      await _downloadCloudData();

      // CRITICAL: Ensure we ALWAYS have at least one wallet
      // App cannot function without a wallet!
      final wallets = await _localDb.walletDao.getAllWallets();
      if (wallets.isEmpty) {
        Log.i('📦 No wallets after cloud pull, populating defaults...', label: 'sync');
        if (_walletDao != null) {
          // Use walletDao with sync support if available
          await WalletPopulationService.populateWithDao(_walletDao);
        } else {
          // Fallback to no-sync population
          await WalletPopulationService.populate(_localDb);
        }
        Log.i('✅ Default wallet populated', label: 'sync');
      }

      // CRITICAL: Ensure we ALWAYS have categories
      // If cloud has categories, they were downloaded above
      // If cloud is empty, create default categories
      final categories = await _localDb.categoryDao.getAllCategories();
      if (categories.isEmpty) {
        Log.i('📦 No categories from cloud, creating defaults...', label: 'sync');
        await CategoryPopulationService.populate(_localDb);
        Log.i('✅ Default categories created', label: 'sync');
      } else {
        Log.i('✅ Categories loaded from cloud: ${categories.length}', label: 'sync');
      }

      Log.i('✅ Successfully replaced local data with cloud data', label: 'sync');
    } catch (e) {
      Log.e('❌ Failed to use cloud data: $e', label: 'sync');
      rethrow;
    }
  }

  /// Keep local data and upload to cloud (overwrite cloud)
  Future<void> useLocalData() async {
    try {
      Log.i('Using local data, will upload to cloud...', label: 'sync');

      // Clear cloud data first
      await _clearCloudData();

      // This will be handled by normal sync flow
      // The caller should trigger fullSync() after this

      Log.i('✅ Cleared cloud data, ready for local upload', label: 'sync');
    } catch (e) {
      Log.e('❌ Failed to use local data: $e', label: 'sync');
      rethrow;
    }
  }

  /// Download all cloud data to local database
  Future<void> _downloadCloudData() async {
    try {
      // Download categories
      print('🔍 [DOWNLOAD] Starting category download...');
      final categoriesSnapshot = await _userCollection
          .doc('categories')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      print('✓ [DOWNLOAD] Downloaded ${categoriesSnapshot.docs.length} categories');

      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final cloudId = doc.id;
        final categoryTitle = data['title'] as String;

        // CRITICAL FIX: Check if category already exists (by cloudId OR by title+isSystemDefault)
        // This prevents duplicate categories when syncing default categories from cloud
        final existingCategoriesByCloudId = await (_localDb.select(_localDb.categories)
          ..where((c) => c.cloudId.equals(cloudId)))
          .get();

        final existingCategoriesByTitle = await (_localDb.select(_localDb.categories)
          ..where((c) => c.title.equals(categoryTitle) & c.isSystemDefault.equals(true)))
          .get();

        // Handle potential duplicates - take first match
        final existingCategoryByCloudId = existingCategoriesByCloudId.isNotEmpty ? existingCategoriesByCloudId.first : null;
        final existingCategoryByTitle = existingCategoriesByTitle.isNotEmpty ? existingCategoriesByTitle.first : null;

        final existingCategory = existingCategoryByCloudId ?? existingCategoryByTitle;

        // Clean up duplicates if found
        if (existingCategoriesByCloudId.length > 1) {
          Log.w('Found ${existingCategoriesByCloudId.length} categories with same cloudId=$cloudId. Keeping first, deleting rest...', label: 'sync');
          for (int i = 1; i < existingCategoriesByCloudId.length; i++) {
            await (_localDb.delete(_localDb.categories)
              ..where((c) => c.id.equals(existingCategoriesByCloudId[i].id)))
              .go();
          }
        }
        if (existingCategoriesByTitle.length > 1 && existingCategoryByCloudId == null) {
          Log.w('Found ${existingCategoriesByTitle.length} categories with title=$categoryTitle and isSystemDefault=true. Keeping first, deleting rest...', label: 'sync');
          for (int i = 1; i < existingCategoriesByTitle.length; i++) {
            await (_localDb.delete(_localDb.categories)
              ..where((c) => c.id.equals(existingCategoriesByTitle[i].id)))
              .go();
          }
        }

        if (existingCategory != null) {
          // Update existing category (add cloudId if missing)
          // CRITICAL: Preserve isSystemDefault flag - never allow cloud to override it
          await (_localDb.update(_localDb.categories)
            ..where((c) => c.id.equals(existingCategory.id)))
            .write(CategoriesCompanion(
              cloudId: Value(cloudId), // Add cloudId to local category
              title: Value(categoryTitle),
              icon: Value(data['icon'] as String),
              iconBackground: Value(data['iconBackground'] as String),
              iconType: Value(data['iconType']?.toString()),
              parentId: Value(data['parentId'] as int?),
              description: Value(data['description'] as String?),
              // Note: isSystemDefault is NOT updated - preserve local value
              updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
            ));
          print('[DOWNLOAD] Updated existing category: $categoryTitle (id=${existingCategory.id}, cloudId=$cloudId)');
        } else {
          // Insert new category (custom category created on another device)
          await _localDb.into(_localDb.categories).insert(
            CategoriesCompanion(
              cloudId: Value(cloudId),
              title: Value(categoryTitle),
              icon: Value(data['icon'] as String),
              iconBackground: Value(data['iconBackground'] as String),
              iconType: Value(data['iconType']?.toString()),
              parentId: Value(data['parentId'] as int?),
              description: Value(data['description'] as String?),
              isSystemDefault: Value(data['isSystemDefault'] as bool? ?? false),
              createdAt: Value((data['createdAt'] as Timestamp).toDate()),
              updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
            ),
          );
          print('[DOWNLOAD] Inserted new category: $categoryTitle (cloudId=$cloudId)');
        }
      }
      print('✅ [DOWNLOAD] Categories inserted to local DB');

      // Download wallets
      print('🔍 [DOWNLOAD] Starting wallet download...');
      final walletsSnapshot = await _userCollection
          .doc('wallets')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      print('✓ [DOWNLOAD] Downloaded ${walletsSnapshot.docs.length} wallets from cloud');

      for (final doc in walletsSnapshot.docs) {
        final data = doc.data();
        final cloudId = doc.id;

        // Check if wallet with this cloudId already exists
        // Use .get() instead of .getSingleOrNull() to handle potential duplicates
        final existingWallets = await (_localDb.select(_localDb.wallets)
          ..where((w) => w.cloudId.equals(cloudId)))
          .get();

        if (existingWallets.isNotEmpty) {
          // Delete duplicates if any (keep only the first one)
          if (existingWallets.length > 1) {
            Log.w('Found ${existingWallets.length} wallets with same cloudId=$cloudId. Cleaning up duplicates...', label: 'sync');
            for (int i = 1; i < existingWallets.length; i++) {
              await (_localDb.delete(_localDb.wallets)
                ..where((w) => w.id.equals(existingWallets[i].id)))
                .go();
              Log.i('Deleted duplicate wallet id=${existingWallets[i].id}', label: 'sync');
            }
          }

          // Update existing wallet
          await (_localDb.update(_localDb.wallets)
            ..where((w) => w.cloudId.equals(cloudId)))
            .write(WalletsCompanion(
              name: Value(data['name'] as String),
              balance: Value(data['balance'] as double),
              currency: Value(data['currency'] as String),
              iconName: Value(data['iconName'] as String?),
              colorHex: Value(data['colorHex'] as String?),
              updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
            ));
        } else {
          // Insert new wallet
          await _localDb.into(_localDb.wallets).insert(
            WalletsCompanion(
              cloudId: Value(cloudId),
              name: Value(data['name'] as String),
              balance: Value(data['balance'] as double),
              currency: Value(data['currency'] as String),
              iconName: Value(data['iconName'] as String?),
              colorHex: Value(data['colorHex'] as String?),
              createdAt: Value((data['createdAt'] as Timestamp).toDate()),
              updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
            ),
          );
        }
      }
      print('✅ [DOWNLOAD] Wallets inserted to local DB');

      // Download transactions
      print('🔍 [DOWNLOAD] Starting transaction download...');
      final transactionsSnapshot = await _userCollection
          .doc('transactions')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      print('✓ [DOWNLOAD] Downloaded ${transactionsSnapshot.docs.length} transactions from cloud');

      // Get default/first wallet for fallback when walletId is null
      final allWallets = await _localDb.walletDao.getAllWallets();
      final defaultWallet = allWallets.isNotEmpty ? allWallets.first : null;

      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();

        // Handle missing categoryId or walletId with fallback
        var categoryId = data['categoryId'] as int?;
        var walletId = data['walletId'] as int?;

        // Skip if categoryId is null (can't guess category)
        if (categoryId == null) {
          print('⚠️ [DOWNLOAD] Skipping transaction ${doc.id} - missing categoryId (cannot infer category)');
          continue;
        }

        // Fallback to default wallet if walletId is null
        if (walletId == null) {
          if (defaultWallet != null) {
            walletId = defaultWallet.id;
            print('⚠️ [DOWNLOAD] Transaction ${doc.id} missing walletId - using default wallet "${defaultWallet.name}" (${defaultWallet.currency})');
            print('   WARNING: If this transaction was from a different currency wallet, the amount may be incorrect');
          } else {
            print('⚠️ [DOWNLOAD] Skipping transaction ${doc.id} - missing walletId and no default wallet available');
            continue;
          }
        }

        // CRITICAL FIX: Check if transaction already exists by cloudId to prevent duplicates
        final existingTransaction = await (_localDb.select(_localDb.transactions)
              ..where((t) => t.cloudId.equals(doc.id)))
            .getSingleOrNull();

        if (existingTransaction != null) {
          print('⚠️ [DOWNLOAD] Skipping transaction ${doc.id} - already exists in local DB (local ID: ${existingTransaction.id})');
          continue;
        }

        await (_localDb.into(_localDb.transactions)).insert(
          TransactionsCompanion.insert(
            transactionType: data['transactionType'] as int,
            amount: data['amount'] as double,
            date: (data['date'] as Timestamp).toDate(),
            title: data['title'] as String,
            categoryId: categoryId,
            walletId: walletId,
            cloudId: Value(doc.id),
            notes: Value(data['notes'] as String?),
            imagePath: Value(data['imagePath'] as String?),
            isRecurring: Value(data['isRecurring'] as bool?),
            createdAt: Value((data['createdAt'] as Timestamp).toDate()),
            updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
          ),
        );
      }
      print('✅ [DOWNLOAD] Transactions inserted to local DB');

      // Recalculate all wallet balances from transactions
      print('🔍 [DOWNLOAD] Recalculating wallet balances...');
      await _localDb.walletDao.recalculateAllBalances();
      print('✅ [DOWNLOAD] Wallet balances recalculated');

      print('✅ [DOWNLOAD] COMPLETE: ${categoriesSnapshot.docs.length} categories, ${walletsSnapshot.docs.length} wallets, ${transactionsSnapshot.docs.length} transactions');
    } catch (e, stackTrace) {
      print('❌ [DOWNLOAD] ERROR during download: $e');
      print('❌ [DOWNLOAD] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all cloud data
  Future<void> _clearCloudData() async {
    // Delete all wallets
    Log.i('🔍 Fetching cloud wallets to delete...', label: 'sync');
    final walletsSnapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Fetched ${walletsSnapshot.docs.length} wallets to delete', label: 'sync');

    for (final doc in walletsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all transactions
    Log.i('🔍 Fetching cloud transactions to delete...', label: 'sync');
    final transactionsSnapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Fetched ${transactionsSnapshot.docs.length} transactions to delete', label: 'sync');

    for (final doc in transactionsSnapshot.docs) {
      await doc.reference.delete();
    }

    Log.i('✅ Cleared cloud data', label: 'sync');
  }
}
