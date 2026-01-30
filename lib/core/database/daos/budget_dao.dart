import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/budgets_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

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
      cloudId: budgetData.cloudId,  // CRITICAL FIX: Include cloudId for sync
      wallet: wallet.toModel(),
      category: category.toModel(),
      amount: budgetData.amount,
      startDate: budgetData.startDate,
      endDate: budgetData.endDate,
      isRoutine: budgetData.isRoutine,
      createdAt: budgetData.createdAt,
      updatedAt: budgetData.updatedAt,
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
          cloudId: budgetData.cloudId,  // CRITICAL FIX: Include cloudId for sync
          wallet: wallet.toModel(),
          category: category.toModel(),
          amount: budgetData.amount,
          startDate: budgetData.startDate,
          endDate: budgetData.endDate,
          isRoutine: budgetData.isRoutine,
          createdAt: budgetData.createdAt,
          updatedAt: budgetData.updatedAt,
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

    // CRITICAL FIX: Generate UUID v7 for cloud sync BEFORE inserting to database
    final cloudId = const Uuid().v7();
    Log.d('Generated cloudId for new budget: $cloudId', label: 'budget');

    // 1. Save to local database with cloudId
    final id = await into(budgets).insert(
      BudgetsCompanion.insert(
        cloudId: Value(cloudId),
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
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          final savedBudget = await getBudgetById(id);
          if (savedBudget != null) {
            // CRITICAL FIX: Sync category dependency BEFORE uploading budget to prevent foreign key errors!
            Log.d('🔍 [BUDGET SYNC] Ensuring category exists on cloud before uploading budget...', label: 'sync');

            // Sync category first if it has a cloudId
            // IMPORTANT: Use forceUpload=true to ensure category exists even if it's unmodified built-in
            if (savedBudget.category.cloudId != null) {
              try {
                Log.d('📤 [CATEGORY SYNC] Force uploading category: ${savedBudget.category.title} (${savedBudget.category.cloudId})', label: 'sync');
                await syncService.uploadCategory(savedBudget.category, forceUpload: true);
                Log.d('✅ [CATEGORY SYNC] Category synced successfully', label: 'sync');
              } catch (e) {
                Log.w('⚠️ [CATEGORY SYNC] Failed to sync category (may already exist): $e', label: 'sync');
                // Continue - category might already exist on cloud
              }
            } else {
              Log.w('⚠️ [CATEGORY SYNC] Category has no cloudId, skipping sync', label: 'sync');
            }

            // Now upload budget (category dependency is guaranteed to exist)
            Log.d('🚀 [BUDGET SYNC] Uploading budget...', label: 'sync');
            await syncService.uploadBudget(savedBudget);
            Log.d('✅ [BUDGET SYNC] Budget uploaded successfully', label: 'sync');
          }
        } catch (e, stack) {
          Log.e('Failed to upload budget to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local save succeeded
        }
      }
    }

    return id;
  }

  /// Insert a budget from cloud data (for sync pull operations)
  /// This method preserves the cloudId and does NOT re-upload to cloud
  Future<int> insertFromCloud(BudgetModel budgetModel) async {
    Log.d('Inserting budget from cloud: ${budgetModel.cloudId}', label: 'budget');

    // Insert directly without generating new cloudId or re-uploading
    return into(budgets).insert(
      BudgetsCompanion.insert(
        cloudId: Value(budgetModel.cloudId),
        walletId: budgetModel.wallet.id!,
        categoryId: budgetModel.category.id!,
        amount: budgetModel.amount,
        startDate: budgetModel.startDate,
        endDate: budgetModel.endDate,
        isRoutine: budgetModel.isRoutine,
        createdAt: Value(budgetModel.createdAt ?? DateTime.now()),
        updatedAt: Value(budgetModel.updatedAt ?? DateTime.now()),
      ),
    );
  }

  /// Update a budget from cloud data (for sync pull operations)
  /// This method does NOT re-upload to cloud
  Future<bool> updateFromCloud(BudgetModel budgetModel) async {
    if (budgetModel.cloudId == null) return false;
    Log.d('Updating budget from cloud: ${budgetModel.cloudId}', label: 'budget');

    // Find local budget by cloudId
    final existingBudget = await getBudgetByCloudId(budgetModel.cloudId!);
    if (existingBudget == null) return false;

    final count = await (update(budgets)..where((b) => b.cloudId.equals(budgetModel.cloudId!)))
        .write(
          BudgetsCompanion(
            walletId: Value(budgetModel.wallet.id!),
            categoryId: Value(budgetModel.category.id!),
            amount: Value(budgetModel.amount),
            startDate: Value(budgetModel.startDate),
            endDate: Value(budgetModel.endDate),
            isRoutine: Value(budgetModel.isRoutine),
            updatedAt: Value(budgetModel.updatedAt ?? DateTime.now()),
          ),
        );
    return count > 0;
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
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          // CRITICAL FIX: Sync category dependency BEFORE uploading budget to prevent foreign key errors!
          Log.d('🔍 [BUDGET UPDATE] Ensuring category exists on cloud before uploading budget...', label: 'sync');

          // Sync category first if it has a cloudId
          if (budgetModel.category.cloudId != null) {
            try {
              Log.d('📤 [CATEGORY SYNC] Force uploading category: ${budgetModel.category.title} (${budgetModel.category.cloudId})', label: 'sync');
              await syncService.uploadCategory(budgetModel.category, forceUpload: true);
              Log.d('✅ [CATEGORY SYNC] Category synced successfully', label: 'sync');
            } catch (e) {
              Log.w('⚠️ [CATEGORY SYNC] Failed to sync category (may already exist): $e', label: 'sync');
              // Continue - category might already exist on cloud
            }
          } else {
            Log.w('⚠️ [CATEGORY SYNC] Category has no cloudId, skipping sync', label: 'sync');
          }

          // Now upload budget update
          Log.d('🚀 [BUDGET UPDATE] Uploading budget update...', label: 'sync');
          await syncService.uploadBudget(budgetModel);
          Log.d('✅ [BUDGET UPDATE] Budget update uploaded successfully', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to upload budget update to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local update succeeded
        }
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
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
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
        Log.w('Sync service not available or not authenticated', label: 'budget');
      }
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
