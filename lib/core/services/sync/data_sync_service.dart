import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
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

class DataSyncService extends Notifier<SyncState> {
  late final AppDatabase _localDb;
  late final FirestoreDatabase _cloudDb;
  late final FirebaseAuthService _authService;

  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 5);

  @override
  SyncState build() {
    // Initialize dependencies
    _localDb = ref.watch(databaseProvider);
    _cloudDb = FirestoreDatabase();
    _authService = ref.watch(authServiceProvider.notifier);

    // Start auto-sync if authenticated
    if (_authService.isAuthenticated) {
      startAutoSync();
    }

    // Cleanup when disposed
    ref.onDispose(() {
      stopAutoSync();
    });

    return SyncState();
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
      final localWallets = await _localDb.walletDao.getAllWallets();

      // Get cloud wallets
      final cloudWallets = await _cloudDb.getAllWallets();

      // Create a map for quick lookup by cloudId
      final cloudWalletMap = {
        for (var w in cloudWallets) w['cloudId'] as String: w
      };

      // Upload new or modified local wallets
      for (final wallet in localWallets) {
        // Skip if wallet doesn't have cloudId yet
        if (wallet.cloudId == null) {
          await _uploadWallet(wallet);
          continue;
        }

        final cloudWallet = cloudWalletMap[wallet.cloudId];

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
        final cloudId = cloudWallet['cloudId'] as String;
        final localExists = localWallets.any((w) => w.cloudId == cloudId);
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
      final localCategories = await _localDb.categoryDao.getAllCategories();

      // Get cloud categories
      final cloudCategories = await _cloudDb.getAllCategories();

      // Create a map for quick lookup by cloudId
      final cloudCategoryMap = {
        for (var c in cloudCategories) c['cloudId'] as String: c
      };

      // Upload new or modified local categories
      for (final category in localCategories) {
        // Skip if category doesn't have cloudId yet
        if (category.cloudId == null) {
          await _uploadCategory(category);
          continue;
        }

        final cloudCategory = cloudCategoryMap[category.cloudId];

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
        final cloudId = cloudCategory['cloudId'] as String;
        final localExists = localCategories.any((c) => c.cloudId == cloudId);
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
      // Get all local transactions
      final localTransactions = await _localDb.transactionDao.getAllTransactions();

      // Get all cloud transactions (across all wallets)
      final wallets = await _localDb.walletDao.getAllWallets();
      final allCloudTransactions = <Map<String, dynamic>>[];

      for (final wallet in wallets) {
        if (wallet.cloudId != null) {
          final cloudTransactions = await _cloudDb.getAllTransactions(wallet.cloudId!);
          allCloudTransactions.addAll(cloudTransactions);
        }
      }

      // Create a map for quick lookup by cloudId
      final cloudTransactionMap = {
        for (var t in allCloudTransactions) t['cloudId'] as String: t
      };

      // Upload new or modified local transactions
      for (final transaction in localTransactions) {
        // Skip if transaction doesn't have cloudId yet
        if (transaction.cloudId == null) {
          await _uploadTransaction(transaction);
          continue;
        }

        final cloudTransaction = cloudTransactionMap[transaction.cloudId];

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
      for (final cloudTransaction in allCloudTransactions) {
        final cloudId = cloudTransaction['cloudId'] as String;
        final localExists = localTransactions.any((t) => t.cloudId == cloudId);
        if (!localExists) {
          await _downloadTransaction(cloudTransaction);
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
      // Get all local budgets
      final localBudgets = await _localDb.budgetDao.getAllBudgets();

      // Get all cloud budgets (across all wallets)
      final wallets = await _localDb.walletDao.getAllWallets();
      final allCloudBudgets = <Map<String, dynamic>>[];

      for (final wallet in wallets) {
        if (wallet.cloudId != null) {
          final cloudBudgets = await _cloudDb.getAllBudgets(wallet.cloudId!);
          allCloudBudgets.addAll(cloudBudgets);
        }
      }

      // Create a map for quick lookup by cloudId
      final cloudBudgetMap = {
        for (var b in allCloudBudgets) b['cloudId'] as String: b
      };

      // Upload new or modified local budgets
      for (final budget in localBudgets) {
        // Skip if budget doesn't have cloudId yet
        if (budget.cloudId == null) {
          await _uploadBudget(budget);
          continue;
        }

        final cloudBudget = cloudBudgetMap[budget.cloudId];

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
      for (final cloudBudget in allCloudBudgets) {
        final cloudId = cloudBudget['cloudId'] as String;
        final localExists = localBudgets.any((b) => b.cloudId == cloudId);
        if (!localExists) {
          await _downloadBudget(cloudBudget);
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
    if (wallet.cloudId == null) return;
    await _cloudDb.updateWallet(wallet.cloudId!, wallet.toJson());
  }

  Future<void> _uploadCategory(Category category) async {
    await _cloudDb.createCategory(category.toJson());
  }

  Future<void> _updateCloudCategory(Category category) async {
    if (category.cloudId == null) return;
    await _cloudDb.updateCategory(category.cloudId!, category.toJson());
  }

  Future<void> _uploadTransaction(Transaction transaction) async {
    await _cloudDb.createTransaction(transaction.toJson());
  }

  Future<void> _updateCloudTransaction(Transaction transaction) async {
    if (transaction.cloudId == null) return;
    await _cloudDb.updateTransaction(transaction.cloudId!, transaction.toJson());
  }

  Future<void> _uploadBudget(Budget budget) async {
    await _cloudDb.createBudget(budget.toJson());
  }

  Future<void> _updateCloudBudget(Budget budget) async {
    if (budget.cloudId == null) return;
    await _cloudDb.updateBudget(budget.cloudId!, budget.toJson());
  }

  // Helper methods for downloading
  Future<void> _downloadWallet(Map<String, dynamic> cloudWallet) async {
    final wallet = WalletsCompanion(
      cloudId: drift.Value(cloudWallet['cloudId'] as String?),
      name: drift.Value(cloudWallet['name'] as String),
      currency: drift.Value(cloudWallet['currency'] as String),
      balance: drift.Value((cloudWallet['balance'] as num?)?.toDouble() ?? 0.0),
      iconName: drift.Value(cloudWallet['iconName'] as String?),
      colorHex: drift.Value(cloudWallet['colorHex'] as String?),
      walletType: drift.Value(cloudWallet['walletType'] as String? ?? 'cash'),
      creditLimit: drift.Value((cloudWallet['creditLimit'] as num?)?.toDouble()),
      billingDay: drift.Value(cloudWallet['billingDay'] as int?),
      interestRate: drift.Value((cloudWallet['interestRate'] as num?)?.toDouble()),
      createdAt: drift.Value((cloudWallet['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudWallet['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.into(_localDb.wallets).insert(wallet);
  }

  Future<void> _downloadCategory(Map<String, dynamic> cloudCategory) async {
    final category = CategoriesCompanion(
      cloudId: drift.Value(cloudCategory['cloudId'] as String?),
      title: drift.Value(cloudCategory['title'] as String),
      icon: drift.Value(cloudCategory['icon'] as String?),
      iconBackground: drift.Value(cloudCategory['iconBackground'] as String?),
      iconType: drift.Value(cloudCategory['iconType'] as String?),
      parentId: drift.Value(cloudCategory['parentId'] as int?),
      description: drift.Value(cloudCategory['description'] as String?),
      localizedTitles: drift.Value(cloudCategory['localizedTitles'] as String?),
      isSystemDefault: drift.Value(cloudCategory['isSystemDefault'] as bool? ?? false),
      transactionType: drift.Value(cloudCategory['transactionType'] as String),
      createdAt: drift.Value((cloudCategory['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudCategory['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.into(_localDb.categories).insert(category);
  }

  Future<void> _downloadTransaction(Map<String, dynamic> cloudTransaction) async {
    // Need to map cloudId references to local IDs
    // Get wallet by cloudId
    final walletCloudId = cloudTransaction['walletId'] as String;
    final wallet = await (_localDb.select(_localDb.wallets)
      ..where((w) => w.cloudId.equals(walletCloudId)))
      .getSingleOrNull();

    if (wallet == null) {
      Log.w('Cannot download transaction: wallet with cloudId=$walletCloudId not found', label: 'sync');
      return;
    }

    // Get category by cloudId (if exists)
    int? categoryId;
    final categoryCloudId = cloudTransaction['categoryId'] as String?;
    if (categoryCloudId != null) {
      final category = await (_localDb.select(_localDb.categories)
        ..where((c) => c.cloudId.equals(categoryCloudId)))
        .getSingleOrNull();
      categoryId = category?.id;

      if (categoryId == null) {
        Log.w('Cannot download transaction: category with cloudId=$categoryCloudId not found', label: 'sync');
        return;
      }
    }

    final transaction = TransactionsCompanion(
      cloudId: drift.Value(cloudTransaction['cloudId'] as String?),
      transactionType: drift.Value(cloudTransaction['transactionType'] as int),
      amount: drift.Value((cloudTransaction['amount'] as num).toDouble()),
      date: drift.Value((cloudTransaction['date'] as Timestamp).toDate()),
      title: drift.Value(cloudTransaction['title'] as String),
      categoryId: drift.Value(categoryId!),
      walletId: drift.Value(wallet.id),
      notes: drift.Value(cloudTransaction['notes'] as String?),
      imagePath: drift.Value(cloudTransaction['imagePath'] as String?),
      isRecurring: drift.Value(cloudTransaction['isRecurring'] as bool?),
      recurringId: drift.Value(cloudTransaction['recurringId'] as int?),
      createdAt: drift.Value((cloudTransaction['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudTransaction['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.into(_localDb.transactions).insert(transaction);
  }

  Future<void> _downloadBudget(Map<String, dynamic> cloudBudget) async {
    // Need to map cloudId references to local IDs
    // Get wallet by cloudId
    final walletCloudId = cloudBudget['walletId'] as String;
    final wallet = await (_localDb.select(_localDb.wallets)
      ..where((w) => w.cloudId.equals(walletCloudId)))
      .getSingleOrNull();

    if (wallet == null) {
      Log.w('Cannot download budget: wallet with cloudId=$walletCloudId not found', label: 'sync');
      return;
    }

    // Get category by cloudId
    final categoryCloudId = cloudBudget['categoryId'] as String;
    final category = await (_localDb.select(_localDb.categories)
      ..where((c) => c.cloudId.equals(categoryCloudId)))
      .getSingleOrNull();

    if (category == null) {
      Log.w('Cannot download budget: category with cloudId=$categoryCloudId not found', label: 'sync');
      return;
    }

    final budget = BudgetsCompanion(
      cloudId: drift.Value(cloudBudget['cloudId'] as String?),
      walletId: drift.Value(wallet.id),
      categoryId: drift.Value(category.id),
      amount: drift.Value((cloudBudget['amount'] as num).toDouble()),
      startDate: drift.Value((cloudBudget['startDate'] as Timestamp).toDate()),
      endDate: drift.Value((cloudBudget['endDate'] as Timestamp).toDate()),
      isRoutine: drift.Value(cloudBudget['isRoutine'] as bool? ?? false),
      createdAt: drift.Value((cloudBudget['createdAt'] as Timestamp).toDate()),
      updatedAt: drift.Value((cloudBudget['updatedAt'] as Timestamp).toDate()),
    );
    await _localDb.into(_localDb.budgets).insert(budget);
  }

}

// Providers
final dataSyncServiceProvider = NotifierProvider<DataSyncService, SyncState>(() {
  return DataSyncService();
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(dataSyncServiceProvider).lastSyncTime;
});

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(dataSyncServiceProvider).status == SyncStatus.syncing;
});