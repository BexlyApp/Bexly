import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';

/// Real-time sync service using Firestore snapshots
/// Implements bidirectional sync with Last-Write-Wins conflict resolution
class RealtimeSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppDatabase _db;

  // Snapshot listeners subscriptions
  StreamSubscription<QuerySnapshot>? _walletsListener;
  StreamSubscription<QuerySnapshot>? _transactionsListener;
  StreamSubscription<QuerySnapshot>? _categoriesListener;
  StreamSubscription<QuerySnapshot>? _budgetsListener;
  StreamSubscription<QuerySnapshot>? _goalsListener;

  // Sync state
  bool _isInitialSyncComplete = false;
  bool _isSyncing = false;

  RealtimeSyncService({
    required AppDatabase db,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = db,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _userId != null;
  bool get isInitialSyncComplete => _isInitialSyncComplete;
  bool get isSyncing => _isSyncing;

  /// Get user's data collection reference
  CollectionReference _getUserCollection(String collectionName) {
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

  Future<void> _handleWalletChange(DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    Log.d(
      'Wallet change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
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

      case DocumentChangeType.removed:
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
      final wallet = WalletModel(
        cloudId: cloudId,
        name: data['name'] as String? ?? 'Wallet',
        balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
        currency: data['currency'] as String? ?? 'IDR',
        iconName: data['iconName'] as String?,
        colorHex: data['colorHex'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );

      await _db.walletDao.addWallet(wallet);
      Log.i('Inserted wallet from cloud: ${wallet.name}', label: 'sync');
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
      final wallet = WalletModel(
        id: localId,
        cloudId: cloudId,
        name: data['name'] as String? ?? 'Wallet',
        balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
        currency: data['currency'] as String? ?? 'IDR',
        iconName: data['iconName'] as String?,
        colorHex: data['colorHex'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );

      await _db.walletDao.updateWallet(wallet);
      Log.i('Updated wallet from cloud: ${wallet.name}', label: 'sync');
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

  Future<void> _handleCategoryChange(DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    Log.d(
      'Category change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
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

      case DocumentChangeType.removed:
        final localCategory =
            await _db.categoryDao.getCategoryByCloudId(cloudId);
        if (localCategory != null) {
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
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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

      // Create updated category entity
      final updatedCategory = Category(
        id: localId,
        cloudId: cloudId,
        title: data['title'] as String? ?? 'Category',
        icon: data['icon'] as String?,
        iconBackground: data['iconBackground'] as String?,
        iconType: data['iconType'] as String?,
        parentId: data['parentId'] as int?,
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? existingCategory.createdAt,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  Future<void> _handleTransactionChange(DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    Log.d(
      'Transaction change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
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

      case DocumentChangeType.removed:
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
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        title: data['title'] as String? ?? 'Transaction',
        category: category.toModel(),
        wallet: wallet.toModel(),
        notes: data['notes'] as String?,
        imagePath: data['imagePath'] as String?,
        isRecurring: data['isRecurring'] as bool?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        title: data['title'] as String? ?? 'Transaction',
        category: category.toModel(),
        wallet: wallet.toModel(),
        notes: data['notes'] as String?,
        imagePath: data['imagePath'] as String?,
        isRecurring: data['isRecurring'] as bool?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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

  Future<void> _handleBudgetChange(DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    Log.d(
      'Budget change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
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

      case DocumentChangeType.removed:
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

      final budget = BudgetModel(
        cloudId: cloudId,
        wallet: wallet.toModel(),
        category: category.toModel(),
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRoutine: data['isRoutine'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
        startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRoutine: data['isRoutine'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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

  Future<void> _handleGoalChange(DocumentChange change) async {
    final doc = change.doc;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final cloudId = doc.id;
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    Log.d(
      'Goal change: ${change.type.name} - $cloudId',
      label: 'sync',
    );

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
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

      case DocumentChangeType.removed:
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
        startDate: (data['startDate'] as Timestamp?)?.toDate(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        iconName: data['iconName'] as String?,
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
        startDate: (data['startDate'] as Timestamp?)?.toDate(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        iconName: data['iconName'] as String?,
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? existingGoal.createdAt,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
}
