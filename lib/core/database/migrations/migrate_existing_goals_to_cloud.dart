import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/database/tables/checklist_item_table.dart';
import 'package:bexly/core/database/tables/budgets_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/transaction_table.dart';
import 'package:bexly/core/database/tables/recurrings_table.dart';
import 'package:bexly/core/services/sync/supabase_sync_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// One-time migration to add cloudId to existing goals, checklist items, and budgets
/// and sync them to Supabase cloud
class MigrateExistingGoalsToCloud {
  static const _label = 'goal_migration';

  /// Migrate all goals without cloudId
  static Future<void> migrateGoals(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    if (!syncService.isAuthenticated) {
      Log.w('Cannot migrate goals: user not authenticated', label: _label);
      return;
    }

    try {
      // Find all goals without cloudId
      final goalsWithoutCloudId = await (db.select(db.goals)
            ..where((t) => t.cloudId.isNull()))
          .get();

      if (goalsWithoutCloudId.isEmpty) {
        Log.d('No goals to migrate - all have cloudId', label: _label);
        return;
      }

      Log.d(
        'Found ${goalsWithoutCloudId.length} goals without cloudId',
        label: _label,
      );

      int successCount = 0;
      int failCount = 0;

      for (final goal in goalsWithoutCloudId) {
        try {
          // Generate UUID v7 for this goal
          final cloudId = const Uuid().v7();

          // Update local database with cloudId
          await (db.update(db.goals)..where((t) => t.id.equals(goal.id)))
              .write(GoalsCompanion(cloudId: Value(cloudId)));

          // Get updated goal from DAO
          final updatedGoal = await db.goalDao.getGoalById(goal.id);

          if (updatedGoal == null) {
            Log.w('Goal ${goal.id} not found after update', label: _label);
            failCount++;
            continue;
          }

          // Upload to Supabase (convert to GoalModel)
          await syncService.uploadGoal(updatedGoal.toModel());

          successCount++;
          Log.d(
            '✅ Migrated goal: ${goal.title} (cloudId: $cloudId)',
            label: _label,
          );
        } catch (e) {
          failCount++;
          Log.e(
            '❌ Failed to migrate goal ${goal.title}: $e',
            label: _label,
          );
        }
      }

      Log.d(
        '🎉 Goal migration complete: $successCount succeeded, $failCount failed',
        label: _label,
      );
    } catch (e, stack) {
      Log.e('Error during goal migration: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Migrate all checklist items without cloudId
  static Future<void> migrateChecklistItems(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    if (!syncService.isAuthenticated) {
      Log.w(
        'Cannot migrate checklist items: user not authenticated',
        label: _label,
      );
      return;
    }

    try {
      // Find all checklist items without cloudId
      final itemsWithoutCloudId = await (db.select(db.checklistItems)
            ..where((t) => t.cloudId.isNull()))
          .get();

      if (itemsWithoutCloudId.isEmpty) {
        Log.d(
          'No checklist items to migrate - all have cloudId',
          label: _label,
        );
        return;
      }

      Log.d(
        'Found ${itemsWithoutCloudId.length} checklist items without cloudId',
        label: _label,
      );

      int successCount = 0;
      int failCount = 0;

      for (final item in itemsWithoutCloudId) {
        try {
          // Get parent goal to verify it has cloudId
          final goal = await (db.select(db.goals)
                ..where((t) => t.id.equals(item.goalId)))
              .getSingleOrNull();

          if (goal == null || goal.cloudId == null) {
            Log.w(
              '⚠️ Skipping checklist item "${item.title}" - parent goal has no cloudId',
              label: _label,
            );
            failCount++;
            continue;
          }

          // Generate UUID v7 for this checklist item
          final cloudId = const Uuid().v7();

          // Update local database with cloudId
          await (db.update(db.checklistItems)
                ..where((t) => t.id.equals(item.id)))
              .write(ChecklistItemsCompanion(cloudId: Value(cloudId)));

          // Get updated item from table
          final updatedItem = await (db.select(db.checklistItems)
                ..where((t) => t.id.equals(item.id)))
              .getSingleOrNull();

          if (updatedItem == null) {
            Log.w('Checklist item ${item.id} not found after update', label: _label);
            failCount++;
            continue;
          }

          // Upload to Supabase (convert to ChecklistItemModel)
          await syncService.uploadChecklistItem(
            updatedItem.toModel(),
            goal.cloudId!,
          );

          successCount++;
          Log.d(
            '✅ Migrated checklist item: ${item.title} (cloudId: $cloudId)',
            label: _label,
          );
        } catch (e) {
          failCount++;
          Log.e(
            '❌ Failed to migrate checklist item ${item.title}: $e',
            label: _label,
          );
        }
      }

      Log.d(
        '🎉 Checklist item migration complete: $successCount succeeded, $failCount failed',
        label: _label,
      );
    } catch (e, stack) {
      Log.e('Error during checklist item migration: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Migrate all budgets without cloudId
  static Future<void> migrateBudgets(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    if (!syncService.isAuthenticated) {
      Log.w(
        'Cannot migrate budgets: user not authenticated',
        label: _label,
      );
      return;
    }

    try {
      // Find all budgets without cloudId
      final budgetsWithoutCloudId = await (db.select(db.budgets)
            ..where((t) => t.cloudId.isNull()))
          .get();

      if (budgetsWithoutCloudId.isEmpty) {
        Log.d('No budgets to migrate - all have cloudId', label: _label);
        return;
      }

      Log.d(
        'Found ${budgetsWithoutCloudId.length} budgets without cloudId',
        label: _label,
      );

      int successCount = 0;
      int failCount = 0;

      for (final budget in budgetsWithoutCloudId) {
        try {
          // Get wallet and category to create BudgetModel
          final wallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(budget.walletId)))
              .getSingleOrNull();

          final category = await (db.select(db.categories)
                ..where((t) => t.id.equals(budget.categoryId)))
              .getSingleOrNull();

          if (wallet == null || category == null) {
            Log.w(
              '⚠️ Skipping budget - wallet or category not found',
              label: _label,
            );
            failCount++;
            continue;
          }

          // Auto-assign cloudId to wallet if missing
          if (wallet.cloudId == null) {
            final walletCloudId = const Uuid().v7();
            await (db.update(db.wallets)
                  ..where((t) => t.id.equals(wallet.id)))
                .write(WalletsCompanion(cloudId: Value(walletCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to wallet ${wallet.name}: $walletCloudId',
              label: _label,
            );
            // Reload wallet with new cloudId
            final updatedWallet = await (db.select(db.wallets)
                  ..where((t) => t.id.equals(wallet.id)))
                .getSingle();
            // Replace wallet reference
            // We'll use updatedWallet.cloudId below
          }

          // Auto-assign cloudId to category if missing
          if (category.cloudId == null) {
            final categoryCloudId = const Uuid().v7();
            await (db.update(db.categories)
                  ..where((t) => t.id.equals(category.id)))
                .write(CategoriesCompanion(cloudId: Value(categoryCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to category ${category.title}: $categoryCloudId',
              label: _label,
            );
            // Reload category with new cloudId
            final updatedCategory = await (db.select(db.categories)
                  ..where((t) => t.id.equals(category.id)))
                .getSingle();
            // Replace category reference
            // We'll use updatedCategory.cloudId below
          }

          // Re-fetch wallet and category to ensure we have the latest cloudId
          final finalWallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(wallet.id)))
              .getSingle();
          final finalCategory = await (db.select(db.categories)
                ..where((t) => t.id.equals(category.id)))
              .getSingle();

          // Generate UUID v7 for this budget
          final cloudId = const Uuid().v7();

          // Update local database with cloudId
          await (db.update(db.budgets)..where((t) => t.id.equals(budget.id)))
              .write(BudgetsCompanion(cloudId: Value(cloudId)));

          // Get updated budget as BudgetModel using DAO (includes wallet and category)
          final budgetModel = await db.budgetDao.getBudgetById(budget.id);

          if (budgetModel == null) {
            Log.w('Budget ${budget.id} not found after update', label: _label);
            failCount++;
            continue;
          }

          // Upload to Supabase
          await syncService.uploadBudget(budgetModel);

          successCount++;
          Log.d(
            '✅ Migrated budget (cloudId: $cloudId)',
            label: _label,
          );
        } catch (e) {
          failCount++;
          Log.e(
            '❌ Failed to migrate budget: $e',
            label: _label,
          );
        }
      }

      Log.d(
        '🎉 Budget migration complete: $successCount succeeded, $failCount failed',
        label: _label,
      );
    } catch (e, stack) {
      Log.e('Error during budget migration: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Migrate existing transactions without cloudId
  static Future<void> migrateTransactions(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    if (!syncService.isAuthenticated) {
      Log.w(
        'Cannot migrate transactions: user not authenticated',
        label: _label,
      );
      return;
    }

    try {
      // Find all transactions without cloudId
      final transactionsWithoutCloudId = await (db.select(db.transactions)
            ..where((t) => t.cloudId.isNull()))
          .get();

      if (transactionsWithoutCloudId.isEmpty) {
        Log.d('No transactions to migrate - all have cloudId', label: _label);
        return;
      }

      Log.d(
        'Found ${transactionsWithoutCloudId.length} transactions without cloudId',
        label: _label,
      );

      int successCount = 0;
      int failCount = 0;

      for (final transaction in transactionsWithoutCloudId) {
        try {
          // Get wallet and category
          final wallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(transaction.walletId)))
              .getSingleOrNull();

          final category = await (db.select(db.categories)
                ..where((t) => t.id.equals(transaction.categoryId)))
              .getSingleOrNull();

          if (wallet == null || category == null) {
            Log.w(
              '⚠️ Skipping transaction - wallet or category not found',
              label: _label,
            );
            failCount++;
            continue;
          }

          // Auto-assign cloudId to wallet if missing
          if (wallet.cloudId == null) {
            final walletCloudId = const Uuid().v7();
            await (db.update(db.wallets)
                  ..where((t) => t.id.equals(wallet.id)))
                .write(WalletsCompanion(cloudId: Value(walletCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to wallet ${wallet.name}: $walletCloudId',
              label: _label,
            );
          }

          // Auto-assign cloudId to category if missing
          if (category.cloudId == null) {
            final categoryCloudId = const Uuid().v7();
            await (db.update(db.categories)
                  ..where((t) => t.id.equals(category.id)))
                .write(CategoriesCompanion(cloudId: Value(categoryCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to category ${category.title}: $categoryCloudId',
              label: _label,
            );
          }

          // Re-fetch wallet and category to ensure we have the latest cloudId
          final finalWallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(wallet.id)))
              .getSingle();
          final finalCategory = await (db.select(db.categories)
                ..where((t) => t.id.equals(category.id)))
              .getSingle();

          // Generate UUID v7 for this transaction
          final cloudId = const Uuid().v7();

          // Update local database with cloudId
          await (db.update(db.transactions)
                ..where((t) => t.id.equals(transaction.id)))
              .write(TransactionsCompanion(cloudId: Value(cloudId)));

          // Get updated transaction data from tables
          final updatedTransaction = await (db.select(db.transactions)
                ..where((t) => t.id.equals(transaction.id)))
              .getSingleOrNull();

          if (updatedTransaction == null) {
            Log.w('Transaction ${transaction.id} not found after update', label: _label);
            failCount++;
            continue;
          }

          // Create TransactionModel manually (simpler than using DAO)
          final transactionModel = TransactionModel(
            id: updatedTransaction.id,
            cloudId: updatedTransaction.cloudId,
            transactionType: TransactionType.values[updatedTransaction.transactionType],
            amount: updatedTransaction.amount,
            date: updatedTransaction.date,
            title: updatedTransaction.title,
            notes: updatedTransaction.notes,
            imagePath: updatedTransaction.imagePath,
            isRecurring: updatedTransaction.isRecurring,
            recurringId: updatedTransaction.recurringId,
            createdAt: updatedTransaction.createdAt,
            updatedAt: updatedTransaction.updatedAt,
            wallet: finalWallet.toModel(),
            category: finalCategory.toModel(),
          );

          // Upload to Supabase
          await syncService.uploadTransaction(transactionModel);

          successCount++;
          Log.d(
            '✅ Migrated transaction (cloudId: $cloudId)',
            label: _label,
          );
        } catch (e) {
          failCount++;
          Log.e(
            '❌ Failed to migrate transaction: $e',
            label: _label,
          );
        }
      }

      Log.d(
        '🎉 Transaction migration complete: $successCount succeeded, $failCount failed',
        label: _label,
      );
    } catch (e, stack) {
      Log.e('Error during transaction migration: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Migrate existing recurring payments without cloudId
  static Future<void> migrateRecurring(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    if (!syncService.isAuthenticated) {
      Log.w(
        'Cannot migrate recurring payments: user not authenticated',
        label: _label,
      );
      return;
    }

    try {
      // Find all recurring payments without cloudId
      final recurringsWithoutCloudId = await (db.select(db.recurrings)
            ..where((t) => t.cloudId.isNull()))
          .get();

      if (recurringsWithoutCloudId.isEmpty) {
        Log.d('No recurring payments to migrate - all have cloudId', label: _label);
        return;
      }

      Log.d(
        'Found ${recurringsWithoutCloudId.length} recurring payments without cloudId',
        label: _label,
      );

      int successCount = 0;
      int failCount = 0;

      for (final recurring in recurringsWithoutCloudId) {
        try {
          // Get wallet and category
          final wallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(recurring.walletId)))
              .getSingleOrNull();

          final category = await (db.select(db.categories)
                ..where((t) => t.id.equals(recurring.categoryId)))
              .getSingleOrNull();

          if (wallet == null || category == null) {
            Log.w(
              '⚠️ Skipping recurring payment - wallet or category not found',
              label: _label,
            );
            failCount++;
            continue;
          }

          // Auto-assign cloudId to wallet if missing
          if (wallet.cloudId == null) {
            final walletCloudId = const Uuid().v7();
            await (db.update(db.wallets)
                  ..where((t) => t.id.equals(wallet.id)))
                .write(WalletsCompanion(cloudId: Value(walletCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to wallet ${wallet.name}: $walletCloudId',
              label: _label,
            );
          }

          // Auto-assign cloudId to category if missing
          if (category.cloudId == null) {
            final categoryCloudId = const Uuid().v7();
            await (db.update(db.categories)
                  ..where((t) => t.id.equals(category.id)))
                .write(CategoriesCompanion(cloudId: Value(categoryCloudId)));
            Log.d(
              '🔧 Auto-assigned cloudId to category ${category.title}: $categoryCloudId',
              label: _label,
            );
          }

          // Re-fetch wallet and category to ensure we have the latest cloudId
          final finalWallet = await (db.select(db.wallets)
                ..where((t) => t.id.equals(wallet.id)))
              .getSingle();
          final finalCategory = await (db.select(db.categories)
                ..where((t) => t.id.equals(category.id)))
              .getSingle();

          // Generate UUID v7 for this recurring payment
          final cloudId = const Uuid().v7();

          // Update local database with cloudId
          await (db.update(db.recurrings)
                ..where((t) => t.id.equals(recurring.id)))
              .write(RecurringsCompanion(cloudId: Value(cloudId)));

          // Get updated recurring payment using DAO
          final recurringModel = await db.recurringDao.getRecurringById(recurring.id);

          if (recurringModel == null) {
            Log.w('Recurring payment ${recurring.id} not found after update', label: _label);
            failCount++;
            continue;
          }

          // Upload to Supabase
          await syncService.uploadRecurring(recurringModel);

          successCount++;
          Log.d(
            '✅ Migrated recurring payment: ${recurring.name} (cloudId: $cloudId)',
            label: _label,
          );
        } catch (e) {
          failCount++;
          Log.e(
            '❌ Failed to migrate recurring payment ${recurring.name}: $e',
            label: _label,
          );
        }
      }

      Log.d(
        '🎉 Recurring payment migration complete: $successCount succeeded, $failCount failed',
        label: _label,
      );
    } catch (e, stack) {
      Log.e('Error during recurring payment migration: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Run complete migration (goals first, then checklist items, then budgets, then transactions, then recurring)
  static Future<void> runMigration(
    AppDatabase db,
    SupabaseSyncService syncService,
  ) async {
    Log.d('🚀 Starting migration of existing data to cloud...', label: _label);

    // Migrate goals first (checklist items depend on goals having cloudId)
    await migrateGoals(db, syncService);

    // Then migrate checklist items
    await migrateChecklistItems(db, syncService);

    // Then migrate budgets (depends on wallets and categories having cloudId)
    await migrateBudgets(db, syncService);

    // Migrate transactions (depends on wallets and categories having cloudId)
    await migrateTransactions(db, syncService);

    // Finally migrate recurring payments (depends on wallets and categories having cloudId)
    await migrateRecurring(db, syncService);

    Log.d('✅ Migration complete!', label: _label);
  }
}
