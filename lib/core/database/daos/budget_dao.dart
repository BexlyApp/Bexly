import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/budgets_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories, Wallets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  final Ref? _ref;

  BudgetDao(super.db, [this._ref]);

  Future<BudgetModel> _mapBudget(Budget budgetData) async {
    final wallet = await db.walletDao.getWalletById(budgetData.walletId);
    final category = await db.categoryDao.getCategoryById(
      budgetData.categoryId,
    );

    if (wallet == null || category == null) {
      throw Exception(
        'Failed to map budget: Wallet or Category not found for budget ID ${budgetData.id}',
      );
    }

    return BudgetModel(
      id: budgetData.id,
      wallet: wallet.toModel(),
      category: category.toModel(),
      amount: budgetData.amount,
      startDate: budgetData.startDate,
      endDate: budgetData.endDate,
      isRoutine: budgetData.isRoutine,
    );
  }

  Future<List<BudgetModel>> _mapBudgets(List<Budget> budgetDataList) async {
    // Fetch all required wallets and categories in batches to be more efficient
    final walletIds = budgetDataList.map((b) => b.walletId).toSet().toList();
    final categoryIds = budgetDataList
        .map((b) => b.categoryId)
        .toSet()
        .toList();

    final walletsMap = {
      for (var w in await db.walletDao.getWalletsByIds(walletIds)) w.id: w,
    };
    final categoriesMap = {
      for (var c in await db.categoryDao.getCategoriesByIds(categoryIds))
        c.id: c,
    };

    List<BudgetModel> result = [];
    for (var budgetData in budgetDataList) {
      final wallet = walletsMap[budgetData.walletId];
      final category = categoriesMap[budgetData.categoryId];
      if (wallet == null || category == null) {
        // Log this issue or handle it more gracefully
        Log.e(
          'Warning: Could not find wallet or category for budget ${budgetData.id}',
          label: 'budget',
        );
        continue; // Skip this budget if essential data is missing
      }
      result.add(
        BudgetModel(
          id: budgetData.id,
          wallet: wallet.toModel(),
          category: category.toModel(),
          amount: budgetData.amount,
          startDate: budgetData.startDate,
          endDate: budgetData.endDate,
          isRoutine: budgetData.isRoutine,
        ),
      );
    }
    return result;
  }

  // Watch all budgets
  Stream<List<BudgetModel>> watchAllBudgets() {
    return (select(budgets)..orderBy([
          (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
        ]))
        .watch()
        .asyncMap(_mapBudgets);
  }

  // Get a single budget by ID
  Future<BudgetModel?> getBudgetById(int id) async {
    final budgetData = await (select(
      budgets,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    return budgetData != null ? _mapBudget(budgetData) : null;
  }

  /// Get budget by cloud ID (for sync operations)
  Future<Budget?> getBudgetByCloudId(String cloudId) {
    return (select(budgets)..where((b) => b.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  // Watch a single budget by ID
  Stream<BudgetModel?> watchBudgetById(int id) {
    return (select(
      budgets,
    )..where((b) => b.id.equals(id))).watchSingleOrNull().asyncMap(
      (budgetData) => budgetData != null ? _mapBudget(budgetData) : null,
    );
  }

  // Add a new budget
  Future<int> addBudget(BudgetModel budgetModel) async {
    Log.d('Adding new budget', label: 'budget');

    // 1. Save to local database
    final id = await into(budgets).insert(
      BudgetsCompanion.insert(
        walletId: budgetModel.wallet.id!,
        categoryId: budgetModel.category.id!,
        amount: budgetModel.amount,
        startDate: budgetModel.startDate,
        endDate: budgetModel.endDate,
        isRoutine: budgetModel.isRoutine,
      ),
    );

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        final savedBudget = await getBudgetById(id);
        if (savedBudget != null) {
          await syncService.uploadBudget(savedBudget);
        }
      } catch (e, stack) {
        Log.e('Failed to upload budget to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local save succeeded
      }
    }

    return id;
  }

  // Get all budgets (for backup)
  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

  // Update an existing budget
  Future<bool> updateBudget(BudgetModel budgetModel) async {
    if (budgetModel.id == null) return false;
    Log.d('Updating budget: ${budgetModel.id}', label: 'budget');

    // 1. Update local database
    final count = await (update(budgets)..where((b) => b.id.equals(budgetModel.id!)))
        .write(
          BudgetsCompanion(
            walletId: Value(budgetModel.wallet.id!),
            categoryId: Value(budgetModel.category.id!),
            amount: Value(budgetModel.amount),
            startDate: Value(budgetModel.startDate),
            endDate: Value(budgetModel.endDate),
            isRoutine: Value(budgetModel.isRoutine),
            updatedAt: Value(DateTime.now()),
          ),
        );
    final success = count > 0;

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadBudget(budgetModel);
      } catch (e, stack) {
        Log.e('Failed to upload budget update to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local update succeeded
      }
    }

    return success;
  }

  // Delete a budget
  Future<int> deleteBudget(int id) async {
    Log.d('Deleting budget with ID: $id', label: 'budget');

    // 1. Get budget with full details for cloud deletion
    final budgetModel = await getBudgetById(id);
    final budget = await (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
    Log.d('Budget found: ${budget != null}, cloudId: ${budget?.cloudId}', label: 'budget');

    // 2. Delete from local database
    final count = await (delete(budgets)..where((b) => b.id.equals(id))).go();
    Log.d('Deleted $count rows from local database', label: 'budget');

    // 3. Delete from cloud
    if (count > 0 && _ref != null && budget != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);

        if (budget.cloudId != null) {
          // Method 1: Delete by cloudId (preferred)
          Log.d('Deleting from cloud with cloudId: ${budget.cloudId}', label: 'budget');
          await syncService.deleteBudgetFromCloud(budget.cloudId!);
          Log.d('Successfully deleted from cloud by cloudId', label: 'budget');
        } else if (budgetModel != null &&
                   budgetModel.category.cloudId != null &&
                   budgetModel.wallet.cloudId != null) {
          // Method 2: Delete by matching fields (for budgets without cloudId)
          Log.d('No cloudId, trying to delete from cloud by matching fields', label: 'budget');
          final deleted = await syncService.deleteBudgetFromCloudByMatch(
            categoryCloudId: budgetModel.category.cloudId!,
            walletCloudId: budgetModel.wallet.cloudId!,
            amount: budgetModel.amount,
            startDate: budgetModel.startDate,
            endDate: budgetModel.endDate,
          );
          if (deleted) {
            Log.d('Successfully deleted from cloud by matching', label: 'budget');
          } else {
            Log.w('Could not find matching budget in cloud to delete', label: 'budget');
          }
        } else {
          Log.w('Cannot delete from cloud: missing cloudId and category/wallet cloudIds', label: 'budget');
        }
      } catch (e, stack) {
        Log.e('Failed to delete budget from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    } else {
      Log.w('Skipping cloud delete: count=$count, ref=${_ref != null}, budget=${budget != null}', label: 'budget');
    }

    return count;
  }

  // Helper method to get spent amount for a budget
  // This requires access to TransactionDao
  Future<double> getSpentAmountForBudget(BudgetModel budget) async {
    final categories = await db.categoryDao.getSubCategories(
      budget.category.id!,
    );
    final categoryIds = [...categories.map((c) => c.id), budget.category.id!];

    if (categoryIds.isEmpty) {
      return 0;
    }

    final transactions = await db.transactionDao.getTransactionsForBudget(
      categoryIds: categoryIds,
      startDate: budget.startDate,
      endDate: budget.endDate,
      walletId: budget.wallet.id!, // Filter by budget's wallet
    );

    return transactions.fold(0.0, (sum, item) async => await sum + item.amount);
  }
}
