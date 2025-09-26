import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/firestore_database.dart';
import 'package:bexly/core/services/auth/firebase_auth_service.dart';
import 'package:bexly/core/utils/logger.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}

class SyncState {
  final SyncStatus status;
  final String? message;
  final double progress;
  final DateTime? lastSyncTime;

  SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.progress = 0.0,
    this.lastSyncTime,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    double? progress,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class DataSyncService extends StateNotifier<SyncState> {
  final AppDatabase _localDb;
  final FirestoreDatabase _cloudDb;
  final FirebaseAuthService _authService;

  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 5);

  DataSyncService({
    required AppDatabase localDb,
    required FirestoreDatabase cloudDb,
    required FirebaseAuthService authService,
  })  : _localDb = localDb,
        _cloudDb = cloudDb,
        _authService = authService,
        super(SyncState()) {
    _init();
  }

  void _init() {
    // Start auto-sync if authenticated
    if (_authService.isAuthenticated) {
      startAutoSync();
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      syncAll();
    });
    Log.i('Auto-sync started', label: 'sync');
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    Log.i('Auto-sync stopped', label: 'sync');
  }

  Future<void> syncAll() async {
    if (!_authService.isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'sync');
      return;
    }

    try {
      state = state.copyWith(
        status: SyncStatus.syncing,
        message: 'Starting sync...',
        progress: 0.0,
      );

      // Sync in order of dependencies
      await _syncWallets();
      state = state.copyWith(progress: 0.25, message: 'Syncing categories...');

      await _syncCategories();
      state = state.copyWith(progress: 0.50, message: 'Syncing transactions...');

      await _syncTransactions();
      state = state.copyWith(progress: 0.75, message: 'Syncing budgets...');

      await _syncBudgets();
      state = state.copyWith(progress: 1.0, message: 'Sync completed');

      state = state.copyWith(
        status: SyncStatus.completed,
        message: 'Sync completed successfully',
        lastSyncTime: DateTime.now(),
      );

      Log.i('Sync completed successfully', label: 'sync');
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed: ${e.toString()}',
      );
      Log.e('Sync failed: $e', label: 'sync');
    }
  }

  Future<void> _syncWallets() async {
    try {
      // Get local wallets
      final localWallets = await _localDb.walletsDao.getAllWallets();

      // Get cloud wallets
      final cloudWallets = await _cloudDb.getAllWallets();

      // Create a map for quick lookup
      final cloudWalletMap = {
        for (var w in cloudWallets) w['id'] as String: w
      };

      // Upload new or modified local wallets
      for (final wallet in localWallets) {
        final cloudWallet = cloudWalletMap[wallet.id];

        if (cloudWallet == null) {
          // New wallet, upload to cloud
          await _uploadWallet(wallet);
        } else {
          // Check if local is newer
          final localUpdated = wallet.updatedAt;
          final cloudUpdated = (cloudWallet['updatedAt'] as Timestamp?)?.toDate();

          if (cloudUpdated == null || localUpdated.isAfter(cloudUpdated)) {
            await _updateCloudWallet(wallet);
          }
        }
      }

      // Download new cloud wallets
      for (final cloudWallet in cloudWallets) {
        final localExists = localWallets.any((w) => w.id == cloudWallet['id']);
        if (!localExists) {
          await _downloadWallet(cloudWallet);
        }
      }

      Log.i('Wallets synced', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync wallets: $e', label: 'sync');
      rethrow;
    }
  }

  Future<void> _syncCategories() async {
    try {
      // Get local categories
      final localCategories = await _localDb.categoriesDao.getAllCategories();

      // Get cloud categories
      final cloudCategories = await _cloudDb.getAllCategories();

      // Create a map for quick lookup
      final cloudCategoryMap = {
        for (var c in cloudCategories) c['id'] as String: c
      };

      // Upload new or modified local categories
      for (final category in localCategories) {
        final cloudCategory = cloudCategoryMap[category.id];

        if (cloudCategory == null) {
          await _uploadCategory(category);
        } else {
          final localUpdated = category.updatedAt;
          final cloudUpdated = (cloudCategory['updatedAt'] as Timestamp?)?.toDate();

          if (cloudUpdated == null || localUpdated.isAfter(cloudUpdated)) {
            await _updateCloudCategory(category);
          }
        }
      }

      // Download new cloud categories
      for (final cloudCategory in cloudCategories) {
        final localExists = localCategories.any((c) => c.id == cloudCategory['id']);
        if (!localExists) {
          await _downloadCategory(cloudCategory);
        }
      }

      Log.i('Categories synced', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync categories: $e', label: 'sync');
      rethrow;
    }
  }

  Future<void> _syncTransactions() async {
    try {
      // Get all wallet IDs
      final wallets = await _localDb.walletsDao.getAllWallets();

      for (final wallet in wallets) {
        // Get local transactions for this wallet
        final localTransactions = await _localDb.transactionsDao
            .getTransactionsByWalletId(wallet.id);

        // Get cloud transactions for this wallet
        final cloudTransactions = await _cloudDb.getAllTransactions(wallet.id);

        // Create a map for quick lookup
        final cloudTransactionMap = {
          for (var t in cloudTransactions) t['id'] as String: t
        };

        // Upload new or modified local transactions
        for (final transaction in localTransactions) {
          final cloudTransaction = cloudTransactionMap[transaction.id];

          if (cloudTransaction == null) {
            await _uploadTransaction(transaction);
          } else {
            final localUpdated = transaction.updatedAt;
            final cloudUpdated = (cloudTransaction['updatedAt'] as Timestamp?)?.toDate();

            if (cloudUpdated == null || localUpdated.isAfter(cloudUpdated)) {
              await _updateCloudTransaction(transaction);
            }
          }
        }

        // Download new cloud transactions
        for (final cloudTransaction in cloudTransactions) {
          final localExists = localTransactions.any((t) => t.id == cloudTransaction['id']);
          if (!localExists) {
            await _downloadTransaction(cloudTransaction);
          }
        }
      }

      Log.i('Transactions synced', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync transactions: $e', label: 'sync');
      rethrow;
    }
  }

  Future<void> _syncBudgets() async {
    try {
      // Get all wallet IDs
      final wallets = await _localDb.walletsDao.getAllWallets();

      for (final wallet in wallets) {
        // Get local budgets for this wallet
        final localBudgets = await _localDb.budgetsDao
            .getBudgetsByWalletId(wallet.id);

        // Get cloud budgets for this wallet
        final cloudBudgets = await _cloudDb.getAllBudgets(wallet.id);

        // Create a map for quick lookup
        final cloudBudgetMap = {
          for (var b in cloudBudgets) b['id'] as String: b
        };

        // Upload new or modified local budgets
        for (final budget in localBudgets) {
          final cloudBudget = cloudBudgetMap[budget.id];

          if (cloudBudget == null) {
            await _uploadBudget(budget);
          } else {
            final localUpdated = budget.updatedAt;
            final cloudUpdated = (cloudBudget['updatedAt'] as Timestamp?)?.toDate();

            if (cloudUpdated == null || localUpdated.isAfter(cloudUpdated)) {
              await _updateCloudBudget(budget);
            }
          }
        }

        // Download new cloud budgets
        for (final cloudBudget in cloudBudgets) {
          final localExists = localBudgets.any((b) => b.id == cloudBudget['id']);
          if (!localExists) {
            await _downloadBudget(cloudBudget);
          }
        }
      }

      Log.i('Budgets synced', label: 'sync');
    } catch (e) {
      Log.e('Failed to sync budgets: $e', label: 'sync');
      rethrow;
    }
  }

  // Helper methods for uploading
  Future<void> _uploadWallet(Wallet wallet) async {
    await _cloudDb.createWallet(wallet.toJson());
  }

  Future<void> _updateCloudWallet(Wallet wallet) async {
    await _cloudDb.updateWallet(wallet.id, wallet.toJson());
  }

  Future<void> _uploadCategory(Category category) async {
    await _cloudDb.createCategory(category.toJson());
  }

  Future<void> _updateCloudCategory(Category category) async {
    await _cloudDb.updateCategory(category.id, category.toJson());
  }

  Future<void> _uploadTransaction(Transaction transaction) async {
    await _cloudDb.createTransaction(transaction.toJson());
  }

  Future<void> _updateCloudTransaction(Transaction transaction) async {
    await _cloudDb.updateTransaction(transaction.id, transaction.toJson());
  }

  Future<void> _uploadBudget(Budget budget) async {
    await _cloudDb.createBudget(budget.toJson());
  }

  Future<void> _updateCloudBudget(Budget budget) async {
    await _cloudDb.updateBudget(budget.id, budget.toJson());
  }

  // Helper methods for downloading
  Future<void> _downloadWallet(Map<String, dynamic> cloudWallet) async {
    final wallet = WalletsCompanion(
      id: drift.Value(cloudWallet['id'] as String),
      name: drift.Value(cloudWallet['name'] as String),
      currency: drift.Value(cloudWallet['currency'] as String),
      balance: drift.Value((cloudWallet['balance'] as num).toDouble()),
      icon: drift.Value(cloudWallet['icon'] as String?),
      color: drift.Value(cloudWallet['color'] as String?),
      createdAt: drift.Value((cloudWallet['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudWallet['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.walletsDao.insertWallet(wallet);
  }

  Future<void> _downloadCategory(Map<String, dynamic> cloudCategory) async {
    final category = CategoriesCompanion(
      id: drift.Value(cloudCategory['id'] as String),
      name: drift.Value(cloudCategory['name'] as String),
      icon: drift.Value(cloudCategory['icon'] as String),
      color: drift.Value(cloudCategory['color'] as String),
      type: drift.Value(cloudCategory['type'] as String),
      createdAt: drift.Value((cloudCategory['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudCategory['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.categoriesDao.insertCategory(category);
  }

  Future<void> _downloadTransaction(Map<String, dynamic> cloudTransaction) async {
    final transaction = TransactionsCompanion(
      id: drift.Value(cloudTransaction['id'] as String),
      walletId: drift.Value(cloudTransaction['walletId'] as String),
      categoryId: drift.Value(cloudTransaction['categoryId'] as String?),
      amount: drift.Value((cloudTransaction['amount'] as num).toDouble()),
      type: drift.Value(cloudTransaction['type'] as String),
      note: drift.Value(cloudTransaction['note'] as String?),
      date: drift.Value((cloudTransaction['date'] as Timestamp).toDate()),
      receiptUrl: drift.Value(cloudTransaction['receiptUrl'] as String?),
      createdAt: drift.Value((cloudTransaction['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudTransaction['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.transactionsDao.insertTransaction(transaction);
  }

  Future<void> _downloadBudget(Map<String, dynamic> cloudBudget) async {
    final budget = BudgetsCompanion(
      id: drift.Value(cloudBudget['id'] as String),
      walletId: drift.Value(cloudBudget['walletId'] as String),
      categoryId: drift.Value(cloudBudget['categoryId'] as String?),
      amount: drift.Value((cloudBudget['amount'] as num).toDouble()),
      period: drift.Value(cloudBudget['period'] as String),
      startDate: drift.Value((cloudBudget['startDate'] as Timestamp).toDate()),
      endDate: drift.Value((cloudBudget['endDate'] as Timestamp?)?.toDate()),
      createdAt: drift.Value((cloudBudget['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudBudget['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.budgetsDao.insertBudget(budget);
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}

// Providers
final dataSyncServiceProvider = StateNotifierProvider<DataSyncService, SyncState>((ref) {
  final localDb = ref.watch(appDatabaseProvider);
  final cloudDb = FirestoreDatabase();
  final authService = ref.watch(authServiceProvider.notifier);

  return DataSyncService(
    localDb: localDb,
    cloudDb: cloudDb,
    authService: authService,
  );
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(dataSyncServiceProvider).lastSyncTime;
});

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(dataSyncServiceProvider).status == SyncStatus.syncing;
});