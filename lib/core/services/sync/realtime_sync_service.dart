import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';

/// Real-time sync service using Firestore snapshots
/// Implements bidirectional sync with Last-Write-Wins conflict resolution
class RealtimeSyncService {
  final firestore.FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppDatabase _db;

  // Snapshot listeners subscriptions
  StreamSubscription<firestore.QuerySnapshot>? _walletsListener;
  StreamSubscription<firestore.QuerySnapshot>? _transactionsListener;
  StreamSubscription<firestore.QuerySnapshot>? _categoriesListener;
  StreamSubscription<firestore.QuerySnapshot>? _budgetsListener;
  StreamSubscription<firestore.QuerySnapshot>? _goalsListener;

  // Sync state
  bool _isInitialSyncComplete = false;
  bool _isSyncing = false;

  RealtimeSyncService({
    required AppDatabase db,
    firestore.FirebaseFirestore? firestoreInstance,
    FirebaseAuth? auth,
  })  : _db = db,
        _firestore = firestoreInstance ?? firestore.FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly"),
        _auth = auth ?? FirebaseAuth.instanceFor(app: FirebaseInitService.bexlyApp);

  String? get _userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _userId != null;
  bool get isInitialSyncComplete => _isInitialSyncComplete;
  bool get isSyncing => _isSyncing;

  /// Get user's data collection reference
  firestore.CollectionReference _getUserCollection(String collectionName) {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc(collectionName)
        .collection('items');
  }

  /// Start real-time sync listeners
  Future<void> startSync() async {
    if (!isAuthenticated) {
      Log.w('Cannot start sync: User not authenticated', label: 'sync');
      return;
    }

    if (_isSyncing) {
      Log.w('Sync already running', label: 'sync');
      return;
    }

    _isSyncing = true;
    Log.i('Starting real-time sync for user: $_userId', label: 'sync');

    try {
      // Start listeners for all collections
      await _startWalletsListener();
      await _startCategoriesListener(); // Categories before transactions/budgets
      await _startTransactionsListener();
      await _startBudgetsListener();
      await _startGoalsListener();

      _isInitialSyncComplete = true;
      Log.i('Real-time sync started successfully', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to start sync: $e', label: 'sync');
      Log.e('Stack trace: $stack', label: 'sync');
      _isSyncing = false;
      rethrow;
    }
  }

  /// Stop all sync listeners
  Future<void> stopSync() async {
    Log.i('Stopping real-time sync', label: 'sync');

    await _walletsListener?.cancel();
    await _transactionsListener?.cancel();
    await _categoriesListener?.cancel();
    await _budgetsListener?.cancel();
    await _goalsListener?.cancel();

    _walletsListener = null;
    _transactionsListener = null;
    _categoriesListener = null;
    _budgetsListener = null;
    _goalsListener = null;

    _isSyncing = false;
    _isInitialSyncComplete = false;

    Log.i('Real-time sync stopped', label: 'sync');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WALLETS SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startWalletsListener() async {
    final collection = _getUserCollection('wallets');

    _walletsListener = collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        Log.d(
          'Wallets snapshot: ${snapshot.docChanges.length} changes',
          label: 'sync',
        );

        for (final change in snapshot.docChanges) {
          try {
            await _handleWalletChange(change);
          } catch (e, stack) {
            Log.e('Error handling wallet change: $e', label: 'sync');
            Log.e('Stack: $stack', label: 'sync');
          }
        }
      },
      onError: (error) {
        Log.e('Wallets listener error: $error', label: 'sync');
      },
    );
  }

  Future<void> _handleWalletChange(firestore.DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as firestore.Timestamp?)?.toDate();

    Log.d(
      'Wallet change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case firestore.DocumentChangeType.added:
      case firestore.DocumentChangeType.modified:
        // Check if we already have this wallet locally
        final localWallet = await _db.walletDao.getWalletByCloudId(cloudId);

        if (localWallet == null) {
          // New wallet from cloud - insert locally
          await _insertWalletFromCloud(cloudId, data);
        } else {
          // Wallet exists - check for conflicts
          final localUpdatedAt = localWallet.updatedAt;

          // Last-Write-Wins: Compare timestamps
          if (remoteUpdatedAt != null &&
              localUpdatedAt != null &&
              remoteUpdatedAt.isAfter(localUpdatedAt)) {
            // Remote is newer - update local
            await _updateWalletFromCloud(localWallet.id, cloudId, data);
          } else {
            Log.d(
              'Local wallet is newer, skipping remote update',
              label: 'sync',
            );
          }
        }
        break;

      case firestore.DocumentChangeType.removed:
        // Wallet deleted from cloud - delete locally
        final localWallet = await _db.walletDao.getWalletByCloudId(cloudId);
        if (localWallet != null) {
          await _db.walletDao.deleteWallet(localWallet.id);
          Log.d('Deleted local wallet: ${localWallet.id}', label: 'sync');
        }
        break;
    }
  }

  Future<void> _insertWalletFromCloud(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      // IMPORTANT: Check if wallet already exists with this cloudId
      final existingWallet = await _db.walletDao.getWalletByCloudId(cloudId);
      if (existingWallet != null) {
        Log.i('Wallet with cloudId $cloudId already exists locally, skipping insert', label: 'sync');
        return;
      }

      // CRITICAL FIX: Check if there's a local wallet with same name/currency but no cloudId
      // This handles the race condition where uploadWallet generates cloudId but hasn't updated local DB yet
      final walletName = data['name'] as String? ?? 'Wallet';
      final walletCurrency = data['currency'] as String? ?? 'IDR';
      final allWallets = await _db.walletDao.getAllWallets();
      final matchingWallet = allWallets.where((w) =>
        w.cloudId == null &&
        w.name == walletName &&
        w.currency == walletCurrency
      ).firstOrNull;

      if (matchingWallet != null) {
        // Found matching wallet without cloudId - update it instead of inserting duplicate
        Log.i('Found matching local wallet without cloudId, updating instead of inserting: ${matchingWallet.name}', label: 'sync');
        await (_db.update(_db.wallets)..where((w) => w.id.equals(matchingWallet.id)))
            .write(WalletsCompanion(cloudId: Value(cloudId)));
        return;
      }

      // CRITICAL: Insert directly to database WITHOUT triggering upload
      // Using walletDao.addWallet would trigger uploadWallet again, creating infinite loop
      // Use insertOnConflictUpdate to prevent duplicate cloudId (UNIQUE constraint)
      final companion = WalletsCompanion(
        cloudId: Value(cloudId),
        name: Value(walletName),
        balance: Value((data['balance'] as num?)?.toDouble() ?? 0.0),
        currency: Value(walletCurrency),
        walletType: Value(data['walletType'] as String? ?? 'cash'), // FIXED: Add walletType
        iconName: Value(data['iconName'] as String?),
        colorHex: Value(data['colorHex'] as String?),
        createdAt: Value((data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now()),
        updatedAt: Value((data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now()),
      );

      // Use insertOnConflictUpdate: if cloudId exists, update; else insert
      await _db.into(_db.wallets).insertOnConflictUpdate(companion);
      Log.i('Inserted/updated wallet from cloud: $walletName (cloudId: $cloudId)', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to insert wallet from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  Future<void> _updateWalletFromCloud(
    int localId,
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      // CRITICAL: Update directly to database WITHOUT triggering upload
      // Using walletDao.updateWallet would trigger uploadWallet again, creating infinite loop
      final companion = WalletsCompanion(
        id: Value(localId),
        cloudId: Value(cloudId),
        name: Value(data['name'] as String? ?? 'Wallet'),
        balance: Value((data['balance'] as num?)?.toDouble() ?? 0.0),
        currency: Value(data['currency'] as String? ?? 'IDR'),
        walletType: Value(data['walletType'] as String? ?? 'cash'), // FIXED: Add walletType
        iconName: Value(data['iconName'] as String?),
        colorHex: Value(data['colorHex'] as String?),
        createdAt: Value((data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now()),
        updatedAt: Value((data['updatedAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now()),
      );

      await (_db.update(_db.wallets)..where((w) => w.id.equals(localId))).write(companion);
      Log.i('Updated wallet from cloud: ${data['name']} (id: $localId, cloudId: $cloudId)', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to update wallet from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CATEGORIES SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startCategoriesListener() async {
    final collection = _getUserCollection('categories');

    _categoriesListener = collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        Log.d(
          'Categories snapshot: ${snapshot.docChanges.length} changes',
          label: 'sync',
        );

        for (final change in snapshot.docChanges) {
          try {
            await _handleCategoryChange(change);
          } catch (e, stack) {
            Log.e('Error handling category change: $e', label: 'sync');
            Log.e('Stack: $stack', label: 'sync');
          }
        }
      },
      onError: (error) {
        Log.e('Categories listener error: $error', label: 'sync');
      },
    );
  }

  Future<void> _handleCategoryChange(firestore.DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as firestore.Timestamp?)?.toDate();

    Log.d(
      'Category change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case firestore.DocumentChangeType.added:
      case firestore.DocumentChangeType.modified:
        final localCategory =
            await _db.categoryDao.getCategoryByCloudId(cloudId);

        if (localCategory == null) {
          await _insertCategoryFromCloud(cloudId, data);
        } else {
          final localUpdatedAt = localCategory.updatedAt;

          if (remoteUpdatedAt != null &&
              localUpdatedAt != null &&
              remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _updateCategoryFromCloud(localCategory.id, cloudId, data);
          }
        }
        break;

      case firestore.DocumentChangeType.removed:
        final localCategory =
            await _db.categoryDao.getCategoryByCloudId(cloudId);
        if (localCategory != null) {
          // CRITICAL: Never delete system default categories
          // These are protected to prevent data loss during sync conflicts
          if (localCategory.isSystemDefault) {
            Log.w(
              'Ignoring cloud delete request for system default category: ${localCategory.title}',
              label: 'sync',
            );
            return;
          }

          await _db.categoryDao.deleteCategoryById(localCategory.id);
          Log.d('Deleted local category: ${localCategory.id}', label: 'sync');
        }
        break;
    }
  }

  Future<void> _insertCategoryFromCloud(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      final category = CategoryModel(
        cloudId: cloudId,
        title: data['title'] as String? ?? 'Category',
        icon: data['icon'] as String? ?? '',
        iconBackground: data['iconBackground'] as String? ?? '',
        iconTypeValue: data['iconType'] as String? ?? '',
        parentId: data['parentId'] as int?,
        description: data['description'] as String? ?? '',
        isSystemDefault: data['isSystemDefault'] as bool? ?? false,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
      );

      final companion = category.toCompanion(isInsert: true);
      await _db.categoryDao.addCategory(companion);
      Log.i('Inserted category from cloud: ${category.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to insert category from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  Future<void> _updateCategoryFromCloud(
    int localId,
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Fetch existing category to get all fields
      final existingCategory = await _db.categoryDao.getCategoryById(localId);
      if (existingCategory == null) {
        Log.w('Category $localId not found for update', label: 'sync');
        return;
      }

      // CRITICAL: Protect system default categories from being modified by cloud sync
      // Built-in categories (Music, Food, etc.) should NEVER be modified via sync
      if (existingCategory.isSystemDefault) {
        Log.w(
          'Ignoring cloud update for system default category: ${existingCategory.title}. '
          'Only cloudId can be updated.',
          label: 'sync',
        );

        // Only update cloudId if it's missing locally
        if (existingCategory.cloudId == null || existingCategory.cloudId!.isEmpty) {
          final updatedCategory = Category(
            id: existingCategory.id,
            cloudId: cloudId,
            title: existingCategory.title,
            icon: existingCategory.icon,
            iconBackground: existingCategory.iconBackground,
            iconType: existingCategory.iconType,
            parentId: existingCategory.parentId,
            description: existingCategory.description,
            isSystemDefault: existingCategory.isSystemDefault,
            transactionType: existingCategory.transactionType,
            createdAt: existingCategory.createdAt,
            updatedAt: DateTime.now(),
          );
          await _db.categoryDao.updateCategory(updatedCategory);
          Log.i('Updated cloudId for system default category: ${existingCategory.title}', label: 'sync');
        }
        return;
      }

      // Create updated category entity for non-system categories
      final updatedCategory = Category(
        id: localId,
        cloudId: cloudId,
        title: data['title'] as String? ?? 'Category',
        icon: data['icon'] as String?,
        iconBackground: data['iconBackground'] as String?,
        iconType: data['iconType'] as String?,
        parentId: data['parentId'] as int?,
        description: data['description'] as String?,
        isSystemDefault: false, // Non-system category
        transactionType: data['transactionType'] as String? ?? 'expense', // Default to expense if not specified
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? existingCategory.createdAt,
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
      );

      await _db.categoryDao.updateCategory(updatedCategory);
      Log.i('Updated category from cloud: ${updatedCategory.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to update category from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TRANSACTIONS SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startTransactionsListener() async {
    final collection = _getUserCollection('transactions');

    _transactionsListener = collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        Log.d(
          'Transactions snapshot: ${snapshot.docChanges.length} changes',
          label: 'sync',
        );

        for (final change in snapshot.docChanges) {
          try {
            await _handleTransactionChange(change);
          } catch (e, stack) {
            Log.e('Error handling transaction change: $e', label: 'sync');
            Log.e('Stack: $stack', label: 'sync');
          }
        }
      },
      onError: (error) {
        Log.e('Transactions listener error: $error', label: 'sync');
      },
    );
  }

  Future<void> _handleTransactionChange(firestore.DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as firestore.Timestamp?)?.toDate();

    Log.d(
      'Transaction change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case firestore.DocumentChangeType.added:
      case firestore.DocumentChangeType.modified:
        final localTransaction =
            await _db.transactionDao.getTransactionByCloudId(cloudId);

        if (localTransaction == null) {
          await _insertTransactionFromCloud(cloudId, data);
        } else {
          final localUpdatedAt = localTransaction.updatedAt;

          if (remoteUpdatedAt != null &&
              remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _updateTransactionFromCloud(
              localTransaction.id,
              cloudId,
              data,
            );
          }
        }
        break;

      case firestore.DocumentChangeType.removed:
        final localTransaction =
            await _db.transactionDao.getTransactionByCloudId(cloudId);
        if (localTransaction != null) {
          await _db.transactionDao.deleteTransaction(localTransaction.id);
          Log.d(
            'Deleted local transaction: ${localTransaction.id}',
            label: 'sync',
          );
        }
        break;
    }
  }

  Future<void> _insertTransactionFromCloud(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Need to fetch category and wallet by their cloudIds
      final categoryCloudId = data['categoryCloudId'] as String?;
      final walletCloudId = data['walletCloudId'] as String?;

      if (categoryCloudId == null || walletCloudId == null) {
        Log.w(
          'Transaction missing category or wallet cloudId, skipping',
          label: 'sync',
        );
        return;
      }

      final category =
          await _db.categoryDao.getCategoryByCloudId(categoryCloudId);
      final wallet = await _db.walletDao.getWalletByCloudId(walletCloudId);

      if (category == null || wallet == null) {
        Log.w(
          'Category or wallet not found locally for transaction, skipping',
          label: 'sync',
        );
        return;
      }

      final transaction = TransactionModel(
        cloudId: cloudId,
        transactionType: TransactionType.values[
            data['transactionType'] as int? ?? TransactionType.expense.index],
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        date: (data['date'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        title: data['title'] as String? ?? 'Transaction',
        category: category.toModel(),
        wallet: wallet.toModel(),
        notes: data['notes'] as String?,
        imagePath: data['imagePath'] as String?,
        isRecurring: data['isRecurring'] as bool?,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
      );

      await _db.transactionDao.addTransaction(transaction);
      Log.i(
        'Inserted transaction from cloud: ${transaction.title}',
        label: 'sync',
      );
    } catch (e, stack) {
      Log.e('Failed to insert transaction from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  Future<void> _updateTransactionFromCloud(
    int localId,
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      final categoryCloudId = data['categoryCloudId'] as String?;
      final walletCloudId = data['walletCloudId'] as String?;

      if (categoryCloudId == null || walletCloudId == null) {
        Log.w(
          'Transaction missing category or wallet cloudId, skipping',
          label: 'sync',
        );
        return;
      }

      final category =
          await _db.categoryDao.getCategoryByCloudId(categoryCloudId);
      final wallet = await _db.walletDao.getWalletByCloudId(walletCloudId);

      if (category == null || wallet == null) {
        Log.w(
          'Category or wallet not found locally for transaction, skipping',
          label: 'sync',
        );
        return;
      }

      final transaction = TransactionModel(
        id: localId,
        cloudId: cloudId,
        transactionType: TransactionType.values[
            data['transactionType'] as int? ?? TransactionType.expense.index],
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        date: (data['date'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        title: data['title'] as String? ?? 'Transaction',
        category: category.toModel(),
        wallet: wallet.toModel(),
        notes: data['notes'] as String?,
        imagePath: data['imagePath'] as String?,
        isRecurring: data['isRecurring'] as bool?,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
      );

      await _db.transactionDao.updateTransaction(transaction);
      Log.i(
        'Updated transaction from cloud: ${transaction.title}',
        label: 'sync',
      );
    } catch (e, stack) {
      Log.e('Failed to update transaction from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUDGETS SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startBudgetsListener() async {
    final collection = _getUserCollection('budgets');

    _budgetsListener = collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        Log.d(
          'Budgets snapshot: ${snapshot.docChanges.length} changes',
          label: 'sync',
        );

        for (final change in snapshot.docChanges) {
          try {
            await _handleBudgetChange(change);
          } catch (e, stack) {
            Log.e('Error handling budget change: $e', label: 'sync');
            Log.e('Stack: $stack', label: 'sync');
          }
        }
      },
      onError: (error) {
        Log.e('Budgets listener error: $error', label: 'sync');
      },
    );
  }

  Future<void> _handleBudgetChange(firestore.DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as firestore.Timestamp?)?.toDate();

    Log.d(
      'Budget change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case firestore.DocumentChangeType.added:
      case firestore.DocumentChangeType.modified:
        final localBudget = await _db.budgetDao.getBudgetByCloudId(cloudId);

        if (localBudget == null) {
          await _insertBudgetFromCloud(cloudId, data);
        } else {
          final localUpdatedAt = localBudget.updatedAt;

          if (remoteUpdatedAt != null &&
              remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _updateBudgetFromCloud(localBudget.id, cloudId, data);
          }
        }
        break;

      case firestore.DocumentChangeType.removed:
        final localBudget = await _db.budgetDao.getBudgetByCloudId(cloudId);
        if (localBudget != null) {
          await _db.budgetDao.deleteBudget(localBudget.id);
          Log.d('Deleted local budget: ${localBudget.id}', label: 'sync');
        }
        break;
    }
  }

  Future<void> _insertBudgetFromCloud(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      final categoryCloudId = data['categoryCloudId'] as String?;
      final walletCloudId = data['walletCloudId'] as String?;

      if (categoryCloudId == null || walletCloudId == null) {
        Log.w('Budget missing category or wallet cloudId, skipping',
            label: 'sync');
        return;
      }

      final category =
          await _db.categoryDao.getCategoryByCloudId(categoryCloudId);
      final wallet = await _db.walletDao.getWalletByCloudId(walletCloudId);

      if (category == null || wallet == null) {
        Log.w(
          'Category or wallet not found locally for budget, skipping',
          label: 'sync',
        );
        return;
      }

      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final startDate = (data['startDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now();
      final endDate = (data['endDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now();

      // Check for duplicate budget before inserting
      final existingBudgets = await _db.budgetDao.getAllBudgets();
      final isDuplicate = existingBudgets.any((b) =>
          b.categoryId == category.id &&
          b.walletId == wallet.id &&
          b.amount == amount &&
          b.startDate.year == startDate.year &&
          b.startDate.month == startDate.month);

      if (isDuplicate) {
        Log.d('Skipping duplicate budget from cloud: category=${category.title}, amount=$amount', label: 'sync');
        return;
      }

      final budget = BudgetModel(
        cloudId: cloudId,
        wallet: wallet.toModel(),
        category: category.toModel(),
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        isRoutine: data['isRoutine'] as bool? ?? false,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
      );

      await _db.budgetDao.addBudget(budget);
      Log.i('Inserted budget from cloud', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to insert budget from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  Future<void> _updateBudgetFromCloud(
    int localId,
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      final categoryCloudId = data['categoryCloudId'] as String?;
      final walletCloudId = data['walletCloudId'] as String?;

      if (categoryCloudId == null || walletCloudId == null) {
        Log.w('Budget missing category or wallet cloudId, skipping',
            label: 'sync');
        return;
      }

      final category =
          await _db.categoryDao.getCategoryByCloudId(categoryCloudId);
      final wallet = await _db.walletDao.getWalletByCloudId(walletCloudId);

      if (category == null || wallet == null) {
        Log.w(
          'Category or wallet not found locally for budget, skipping',
          label: 'sync',
        );
        return;
      }

      final budget = BudgetModel(
        id: localId,
        cloudId: cloudId,
        wallet: wallet.toModel(),
        category: category.toModel(),
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        startDate: (data['startDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        isRoutine: data['isRoutine'] as bool? ?? false,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
      );

      await _db.budgetDao.updateBudget(budget);
      Log.i('Updated budget from cloud', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to update budget from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GOALS SYNC
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startGoalsListener() async {
    final collection = _getUserCollection('goals');

    _goalsListener = collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        Log.d(
          'Goals snapshot: ${snapshot.docChanges.length} changes',
          label: 'sync',
        );

        for (final change in snapshot.docChanges) {
          try {
            await _handleGoalChange(change);
          } catch (e, stack) {
            Log.e('Error handling goal change: $e', label: 'sync');
            Log.e('Stack: $stack', label: 'sync');
          }
        }
      },
      onError: (error) {
        Log.e('Goals listener error: $error', label: 'sync');
      },
    );
  }

  Future<void> _handleGoalChange(firestore.DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as firestore.Timestamp?)?.toDate();

    Log.d(
      'Goal change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case firestore.DocumentChangeType.added:
      case firestore.DocumentChangeType.modified:
        final localGoal = await _db.goalDao.getGoalByCloudId(cloudId);

        if (localGoal == null) {
          await _insertGoalFromCloud(cloudId, data);
        } else {
          final localUpdatedAt = localGoal.updatedAt;

          if (remoteUpdatedAt != null && remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _updateGoalFromCloud(localGoal.id, cloudId, data);
          }
        }
        break;

      case firestore.DocumentChangeType.removed:
        final localGoal = await _db.goalDao.getGoalByCloudId(cloudId);
        if (localGoal != null) {
          await _db.goalDao.deleteGoal(localGoal.id);
          Log.d('Deleted local goal: ${localGoal.id}', label: 'sync');
        }
        break;
    }
  }

  Future<void> _insertGoalFromCloud(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      final goal = GoalModel(
        cloudId: cloudId,
        title: data['title'] as String? ?? 'Goal',
        targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
        startDate: (data['startDate'] as firestore.Timestamp?)?.toDate(),
        endDate: (data['endDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        iconName: data['iconName'] as String?,
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate(),
        associatedAccountId: data['associatedAccountId'] as int?,
        pinned: data['pinned'] as bool? ?? false,
      );

      final companion = goal.toCompanion(isInsert: true);
      await _db.goalDao.addGoal(companion);
      Log.i('Inserted goal from cloud: ${goal.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to insert goal from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  Future<void> _updateGoalFromCloud(
    int localId,
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Fetch existing goal to preserve fields
      final existingGoal = await _db.goalDao.getGoalById(localId);
      if (existingGoal == null) {
        Log.w('Goal $localId not found for update', label: 'sync');
        return;
      }

      // Create updated goal entity
      final updatedGoal = Goal(
        id: localId,
        cloudId: cloudId,
        title: data['title'] as String? ?? 'Goal',
        targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
        startDate: (data['startDate'] as firestore.Timestamp?)?.toDate(),
        endDate: (data['endDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        iconName: data['iconName'] as String?,
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? existingGoal.createdAt,
        updatedAt: (data['updatedAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        associatedAccountId: data['associatedAccountId'] as int?,
        pinned: data['pinned'] as bool?,
      );

      await _db.goalDao.updateGoal(updatedGoal);
      Log.i('Updated goal from cloud: ${updatedGoal.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to update goal from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPLOAD METHODS (Local → Cloud)
  // ──────────────────────────────────────────────────────────────────────────

  /// Upload a wallet to Firestore (create or update)
  Future<void> uploadWallet(WalletModel wallet) async {
    if (!isAuthenticated) {
      Log.w('Cannot upload wallet: User not authenticated', label: 'sync');
      return;
    }

    try {
      final collection = _getUserCollection('wallets');

      // CRITICAL FIX: Read cloudId from database FIRST before generating new one
      // This prevents race condition where upload happens with new cloudId before local DB is updated
      String cloudId;
      if (wallet.cloudId != null) {
        cloudId = wallet.cloudId!;
      } else if (wallet.id != null) {
        // Wallet doesn't have cloudId in memory, but might have it in database
        // Read from database first to avoid generating duplicate cloudId
        final currentWallet = await (_db.select(_db.wallets)
          ..where((w) => w.id.equals(wallet.id!)))
          .getSingleOrNull();

        if (currentWallet?.cloudId != null) {
          // Use existing cloudId from database
          cloudId = currentWallet!.cloudId!;
          print('[UPLOAD_DEBUG] Using existing cloudId from database: ${wallet.name} -> $cloudId');
        } else {
          // Generate new cloudId
          cloudId = const Uuid().v7();
          print('[UPLOAD_DEBUG] Generated new cloudId: ${wallet.name} -> $cloudId');
        }
      } else {
        // No wallet ID, generate new cloudId
        cloudId = const Uuid().v7();
        print('[UPLOAD_DEBUG] Generated new cloudId (no wallet ID): ${wallet.name} -> $cloudId');
      }

      final data = {
        'name': wallet.name,
        'balance': wallet.balance,
        'currency': wallet.currency,
        'walletType': wallet.walletType.name, // FIXED: Add walletType to cloud upload
        'iconName': wallet.iconName,
        'colorHex': wallet.colorHex,
        'createdAt': wallet.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await collection.doc(cloudId).set(data, firestore.SetOptions(merge: true));

      // Update local wallet with cloudId if it was newly generated
      if (wallet.cloudId == null && wallet.id != null) {
        try {
          await (_db.update(_db.wallets)..where((w) => w.id.equals(wallet.id!)))
              .write(WalletsCompanion(cloudId: Value(cloudId)));
          Log.d('Updated wallet cloudId in local database: ${wallet.name} -> $cloudId', label: 'sync');
        } catch (e) {
          // If UNIQUE constraint error, the cloudId already exists - skip silently
          if (e.toString().contains('UNIQUE constraint')) {
            Log.w('CloudId $cloudId already exists (UNIQUE constraint). Skipping update for ${wallet.name}', label: 'sync');
          } else {
            rethrow;
          }
        }
      }

      Log.i('Uploaded wallet to cloud: ${wallet.name}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload wallet: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a wallet from Firestore
  Future<void> deleteWalletFromCloud(String cloudId) async {
    if (!isAuthenticated) return;

    try {
      final collection = _getUserCollection('wallets');
      await collection.doc(cloudId).delete();
      Log.i('Deleted wallet from cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to delete wallet from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Upload a category to Firestore
  Future<void> uploadCategory(CategoryModel category) async {
    if (!isAuthenticated) {
      Log.w('Cannot upload category: User not authenticated', label: 'sync');
      return;
    }

    try {
      print('[UPLOAD_DEBUG] uploadCategory called for: ${category.title} (id=${category.id}, cloudId=${category.cloudId})');
      final collection = _getUserCollection('categories');

      final cloudId = category.cloudId ?? const Uuid().v7();
      print('[UPLOAD_DEBUG] Using cloudId: $cloudId (was null: ${category.cloudId == null})');

      final data = {
        'title': category.title,
        'icon': category.icon,
        'iconBackground': category.iconBackground,
        'iconType': category.iconTypeValue,
        'parentId': category.parentId,
        'description': category.description,
        'isSystemDefault': category.isSystemDefault,
        'createdAt': category.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await collection.doc(cloudId).set(data, firestore.SetOptions(merge: true));

      // Update local category with cloudId if it was generated
      if (category.cloudId == null && category.id != null) {
        // Re-read category first to check current cloudId in database
        final currentCategory = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(category.id!)))
          .getSingleOrNull();

        if (currentCategory?.cloudId == null) {
          try {
            // Check if cloudId already exists in database for a DIFFERENT category
            final existingCategory = await (_db.select(_db.categories)
              ..where((c) => c.cloudId.equals(cloudId)))
              .getSingleOrNull();

            if (existingCategory != null && existingCategory.id != category.id) {
              // CloudId exists for a DIFFERENT category - this shouldn't happen!
              // This means there's a duplicate category or stale data
              print('[UPLOAD_DEBUG] ⚠️ CloudId $cloudId already exists for DIFFERENT category: ${existingCategory.title} (id=${existingCategory.id}). Current: ${category.title} (id=${category.id})');
            } else {
              // CloudId doesn't exist or exists for SAME category - safe to update
              await (_db.update(_db.categories)..where((c) => c.id.equals(category.id!)))
                  .write(CategoriesCompanion(cloudId: Value(cloudId)));
              print('[UPLOAD_DEBUG] Updated category cloudId in local database: ${category.title} -> $cloudId');
            }
          } catch (e) {
            // If UNIQUE constraint error, the cloudId already exists - skip silently
            if (e.toString().contains('UNIQUE constraint')) {
              print('[UPLOAD_DEBUG] ⚠️ CloudId $cloudId already exists (UNIQUE constraint). Skipping update for ${category.title}');
            } else {
              rethrow;
            }
          }
        } else {
          print('[UPLOAD_DEBUG] Category already has cloudId in database: ${category.title} -> ${currentCategory?.cloudId}');
        }
      }

      Log.i('Uploaded category to cloud: ${category.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload category: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a category from Firestore
  Future<void> deleteCategoryFromCloud(String cloudId) async {
    if (!isAuthenticated) return;

    try {
      final collection = _getUserCollection('categories');
      await collection.doc(cloudId).delete();
      Log.i('Deleted category from cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to delete category from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Upload a transaction to Firestore
  Future<void> uploadTransaction(TransactionModel transaction) async {
    if (!isAuthenticated) {
      Log.w('Cannot upload transaction: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Ensure category and wallet have cloudIds
      String? categoryCloudId = transaction.category.cloudId;
      String? walletCloudId = transaction.wallet.cloudId;

      if (categoryCloudId == null) {
        Log.w('Transaction category missing cloudId, uploading category first', label: 'sync');
        await uploadCategory(transaction.category);
        // Re-read category from database to get cloudId
        final updatedCategory = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(transaction.category.id!)))
          .getSingleOrNull();
        categoryCloudId = updatedCategory?.cloudId;
        print('[UPLOAD_DEBUG] Re-read category cloudId: $categoryCloudId');
      }

      if (walletCloudId == null) {
        Log.w('Transaction wallet missing cloudId, uploading wallet first', label: 'sync');
        await uploadWallet(transaction.wallet);
        // Re-read wallet from database to get cloudId
        final updatedWallet = await (_db.select(_db.wallets)
          ..where((w) => w.id.equals(transaction.wallet.id!)))
          .getSingleOrNull();
        walletCloudId = updatedWallet?.cloudId;
        print('[UPLOAD_DEBUG] Re-read wallet cloudId: $walletCloudId');
      }

      if (categoryCloudId == null || walletCloudId == null) {
        throw Exception('Failed to get cloudIds for category or wallet after upload');
      }

      final collection = _getUserCollection('transactions');

      final cloudId = transaction.cloudId ?? const Uuid().v7();

      final data = {
        'transactionType': transaction.transactionType.index,
        'amount': transaction.amount,
        'date': transaction.date,
        'title': transaction.title,
        'categoryCloudId': categoryCloudId,
        'walletCloudId': walletCloudId,
        'notes': transaction.notes,
        'imagePath': transaction.imagePath,
        'isRecurring': transaction.isRecurring,
        'createdAt': transaction.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await collection.doc(cloudId).set(data, firestore.SetOptions(merge: true));

      // CRITICAL FIX: Update local transaction with cloudId to prevent duplicates
      // If transaction was created without cloudId, update it now
      if (transaction.cloudId == null && transaction.id != null) {
        print('🔄 [CLOUDID_UPDATE] Transaction ${transaction.id} has no cloudId, updating now...');
        await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(transaction.id!)))
          .write(TransactionsCompanion(
            cloudId: Value(cloudId),
            updatedAt: Value(DateTime.now()),
          ));
        print('✅ [CLOUDID_UPDATE] Updated local transaction ${transaction.id} with cloudId: $cloudId');
        Log.d('Updated local transaction ${transaction.id} with cloudId: $cloudId', label: 'sync');
      } else {
        print('ℹ️ [CLOUDID_UPDATE] Transaction ${transaction.id} already has cloudId: ${transaction.cloudId}');
      }

      Log.i('Uploaded transaction to cloud: ${transaction.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload transaction: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a transaction from Firestore
  Future<void> deleteTransactionFromCloud(String cloudId) async {
    if (!isAuthenticated) return;

    try {
      final collection = _getUserCollection('transactions');
      await collection.doc(cloudId).delete();
      Log.i('Deleted transaction from cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to delete transaction from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Upload a budget to Firestore
  Future<void> uploadBudget(BudgetModel budget) async {
    if (!isAuthenticated) {
      Log.w('Cannot upload budget: User not authenticated', label: 'sync');
      return;
    }

    try {
      // Ensure category and wallet have cloudIds
      if (budget.category.cloudId == null) {
        await uploadCategory(budget.category);
      }

      if (budget.wallet.cloudId == null) {
        await uploadWallet(budget.wallet);
      }

      final collection = _getUserCollection('budgets');

      // Generate new cloudId if budget doesn't have one
      final isNewCloudId = budget.cloudId == null;
      final cloudId = budget.cloudId ?? const Uuid().v7();

      final data = {
        'categoryCloudId': budget.category.cloudId!,
        'walletCloudId': budget.wallet.cloudId!,
        'amount': budget.amount,
        'startDate': budget.startDate,
        'endDate': budget.endDate,
        'isRoutine': budget.isRoutine,
        'createdAt': budget.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await collection.doc(cloudId).set(data, firestore.SetOptions(merge: true));

      // If we generated a new cloudId, save it to local database
      if (isNewCloudId && budget.id != null) {
        await (_db.update(_db.budgets)..where((b) => b.id.equals(budget.id!)))
            .write(BudgetsCompanion(cloudId: Value(cloudId)));
        Log.i('Saved cloudId $cloudId to local budget ${budget.id}', label: 'sync');
      }

      Log.i('Uploaded budget to cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload budget: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a budget from Firestore
  Future<void> deleteBudgetFromCloud(String cloudId) async {
    if (!isAuthenticated) return;

    try {
      final collection = _getUserCollection('budgets');
      await collection.doc(cloudId).delete();
      Log.i('Deleted budget from cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to delete budget from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a budget from Firestore by matching fields (when cloudId is not available)
  Future<bool> deleteBudgetFromCloudByMatch({
    required String categoryCloudId,
    required String walletCloudId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final collection = _getUserCollection('budgets');

      // Query for matching budget
      final query = await collection
          .where('categoryCloudId', isEqualTo: categoryCloudId)
          .where('walletCloudId', isEqualTo: walletCloudId)
          .where('amount', isEqualTo: amount)
          .get();

      if (query.docs.isEmpty) {
        Log.w('No matching budget found in cloud for deletion', label: 'sync');
        return false;
      }

      // Delete all matching documents (should be just one)
      int deletedCount = 0;
      for (final doc in query.docs) {
        await doc.reference.delete();
        deletedCount++;
        Log.i('Deleted budget from cloud by match: ${doc.id}', label: 'sync');
      }

      return deletedCount > 0;
    } catch (e, stack) {
      Log.e('Failed to delete budget from cloud by match: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      return false;
    }
  }

  /// Upload a goal to Firestore
  Future<void> uploadGoal(GoalModel goal) async {
    if (!isAuthenticated) {
      Log.w('Cannot upload goal: User not authenticated', label: 'sync');
      return;
    }

    try {
      final collection = _getUserCollection('goals');

      final cloudId = goal.cloudId ?? const Uuid().v7();

      final data = {
        'title': goal.title,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'startDate': goal.startDate,
        'endDate': goal.endDate,
        'iconName': goal.iconName,
        'description': goal.description,
        'associatedAccountId': goal.associatedAccountId,
        'pinned': goal.pinned,
        'createdAt': goal.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await collection.doc(cloudId).set(data, firestore.SetOptions(merge: true));

      Log.i('Uploaded goal to cloud: ${goal.title}', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload goal: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }

  /// Delete a goal from Firestore
  Future<void> deleteGoalFromCloud(String cloudId) async {
    if (!isAuthenticated) return;

    try {
      final collection = _getUserCollection('goals');
      await collection.doc(cloudId).delete();
      Log.i('Deleted goal from cloud: $cloudId', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to delete goal from cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }
}
