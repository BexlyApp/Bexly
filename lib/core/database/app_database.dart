import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:bexly/core/database/database_connection.dart';
import 'package:bexly/core/database/daos/budget_dao.dart';
import 'package:bexly/core/database/daos/category_dao.dart';
import 'package:bexly/core/database/daos/transaction_dao.dart';
import 'package:bexly/core/database/daos/checklist_item_dao.dart';
import 'package:bexly/core/database/daos/goal_dao.dart';
import 'package:bexly/core/database/daos/user_dao.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart'; // Import new DAO
import 'package:bexly/core/database/daos/chat_message_dao.dart';
import 'package:bexly/core/database/daos/recurring_dao.dart';
import 'package:bexly/core/database/daos/notification_dao.dart';
import 'package:bexly/core/database/daos/family_dao.dart';
import 'package:bexly/core/database/tables/budgets_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/transaction_table.dart';
import 'package:bexly/core/database/tables/checklist_item_table.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/database/tables/users.dart';
import 'package:bexly/core/database/tables/wallet_table.dart'; // Import new table
import 'package:bexly/core/database/tables/chat_messages_table.dart';
import 'package:bexly/core/database/tables/recurrings_table.dart';
import 'package:bexly/core/database/tables/notifications_table.dart';
import 'package:bexly/core/database/tables/family_group_table.dart';
import 'package:bexly/core/database/tables/family_member_table.dart';
import 'package:bexly/core/database/tables/family_invitation_table.dart';
import 'package:bexly/core/database/tables/shared_wallet_table.dart';
import 'package:bexly/core/database/tables/parsed_email_transaction_table.dart';
import 'package:bexly/core/database/daos/parsed_email_transaction_dao.dart';
import 'package:bexly/core/database/tables/pending_transaction_table.dart';
import 'package:bexly/core/database/daos/pending_transaction_dao.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/data_population_service/wallet_population_service.dart'; // Import new population service
import 'package:bexly/core/utils/logger.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Categories,
    Goals,
    ChecklistItems,
    Transactions,
    Wallets,
    Budgets,
    ChatMessages,
    Recurrings,
    Notifications,
    FamilyGroups,
    FamilyMembers,
    FamilyInvitations,
    SharedWallets,
    ParsedEmailTransactions,
    PendingTransactions,
  ],
  daos: [
    UserDao,
    CategoryDao,
    GoalDao,
    ChecklistItemDao,
    TransactionDao,
    WalletDao,
    BudgetDao,
    ChatMessageDao,
    RecurringDao,
    NotificationDao,
    FamilyDao,
    ParsedEmailTransactionDao,
    PendingTransactionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 22; // Add unified pending_transactions table

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        Log.i(
          'Creating new database and populating tables...',
          label: 'database',
        );
        await m.createAll();

        // Only populate categories on database creation
        // Wallets will be created by sync service after initial sync completes
        Log.i('Populating default categories...', label: 'database');
        await CategoryPopulationService.populate(this);
        Log.i('✅ Default categories populated', label: 'database');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        Log.i('Running migration from $from to $to', label: 'database');

        if (from < 8) {
          resetCategories();
          return;
        }

        // For version 9 or 10, create the chat_messages table if it doesn't exist
        if (from < 10) {
          try {
            await m.createTable(chatMessages);
            Log.i('Created chat_messages table', label: 'database');
          } catch (e) {
            Log.d('Chat messages table might already exist: $e', label: 'database');
          }
          return;
        }

        // For version 11, add cloudId column to sync tables
        if (from < 11) {
          try {
            await m.addColumn(wallets, wallets.cloudId);
            await m.addColumn(transactions, transactions.cloudId);
            await m.addColumn(categories, categories.cloudId);
            await m.addColumn(budgets, budgets.cloudId);
            await m.addColumn(goals, goals.cloudId);
            await m.addColumn(checklistItems, checklistItems.cloudId);
            Log.i('Added cloudId columns for cloud sync', label: 'database');
          } catch (e) {
            Log.e('Failed to add cloudId columns: $e', label: 'database');
          }
        }

        // For version 12, add recurrings table
        if (from < 12) {
          try {
            await m.createTable(recurrings);
            Log.i('Created recurrings table for recurring payments', label: 'database');
          } catch (e) {
            Log.e('Failed to create recurrings table: $e', label: 'database');
          }
        }

        // For version 13, add isSystemDefault column to categories
        if (from < 13) {
          try {
            await m.addColumn(categories, categories.isSystemDefault);
            Log.i('Added isSystemDefault column to categories table', label: 'database');

            // Mark all existing categories as system defaults to protect them
            await customUpdate(
              'UPDATE categories SET is_system_default = 1',
            );
            Log.i('Marked all existing categories as system defaults', label: 'database');
          } catch (e) {
            Log.e('Failed to add isSystemDefault column: $e', label: 'database');
          }
        }

        // For version 14, add wallet type and credit card fields
        if (from < 14) {
          try {
            await m.addColumn(wallets, wallets.walletType);
            await m.addColumn(wallets, wallets.creditLimit);
            await m.addColumn(wallets, wallets.billingDay);
            await m.addColumn(wallets, wallets.interestRate);
            Log.i('Added wallet type and credit card fields to wallets table', label: 'database');

            // Set default wallet type to 'cash' for existing wallets
            await customUpdate(
              "UPDATE wallets SET wallet_type = 'cash' WHERE wallet_type IS NULL",
            );
            Log.i('Set default wallet type for existing wallets', label: 'database');
          } catch (e) {
            Log.e('Failed to add wallet type fields: $e', label: 'database');
          }
        }

        // For version 15, add UNIQUE constraint to wallet name
        if (from < 15) {
          try {
            Log.i('Adding UNIQUE constraint to wallet name...', label: 'database');

            // Step 1: Check for duplicate wallet names and rename them
            final duplicates = await customSelect(
              '''
              SELECT name, COUNT(*) as count
              FROM wallets
              GROUP BY name
              HAVING count > 1
              ''',
            ).get();

            for (final row in duplicates) {
              final duplicateName = row.read<String>('name');
              Log.w('Found duplicate wallet name: $duplicateName', label: 'database');

              // Get all wallets with this name
              final walletsWithName = await customSelect(
                'SELECT id FROM wallets WHERE name = ? ORDER BY id',
                variables: [Variable.withString(duplicateName)],
              ).get();

              // Rename duplicates (keep first one, rename others)
              for (int i = 1; i < walletsWithName.length; i++) {
                final walletId = walletsWithName[i].read<int>('id');
                final newName = '$duplicateName ${i + 1}';
                await customUpdate(
                  'UPDATE wallets SET name = ? WHERE id = ?',
                  variables: [Variable.withString(newName), Variable.withInt(walletId)],
                );
                Log.i('Renamed duplicate wallet $walletId to: $newName', label: 'database');
              }
            }

            // Step 2: Recreate table with UNIQUE constraint
            // SQLite doesn't support ALTER TABLE ADD CONSTRAINT, so we need to recreate
            await customStatement('CREATE TABLE wallets_new AS SELECT * FROM wallets');
            await customStatement('DROP TABLE wallets');
            await m.createTable(wallets);
            await customStatement('INSERT INTO wallets SELECT * FROM wallets_new');
            await customStatement('DROP TABLE wallets_new');

            Log.i('✅ Added UNIQUE constraint to wallet name', label: 'database');
          } catch (e) {
            Log.e('Failed to add UNIQUE constraint to wallet name: $e', label: 'database');
          }
        }

        // For version 16, add recurringId to transactions for payment history tracking
        if (from < 16) {
          try {
            await m.addColumn(transactions, transactions.recurringId);
            Log.i('Added recurringId column to transactions table for payment history', label: 'database');
          } catch (e) {
            Log.e('Failed to add recurringId column: $e', label: 'database');
          }
        }

        // For version 17, add notifications table
        if (from < 17) {
          try {
            await m.createTable(notifications);
            Log.i('Created notifications table for notification history', label: 'database');
          } catch (e) {
            Log.e('Failed to create notifications table: $e', label: 'database');
          }
        }

        // For version 18, add localizedTitles column to categories for multi-language support
        if (from < 18) {
          try {
            await m.addColumn(categories, categories.localizedTitles);
            Log.i('Added localizedTitles column to categories table', label: 'database');
          } catch (e) {
            Log.e('Failed to add localizedTitles column: $e', label: 'database');
          }
        }

        // For version 19, add family sharing tables and columns
        if (from < 19) {
          try {
            // Create new family sharing tables
            await m.createTable(familyGroups);
            await m.createTable(familyMembers);
            await m.createTable(familyInvitations);
            await m.createTable(sharedWallets);
            Log.i('Created family sharing tables', label: 'database');

            // Add user tracking columns to transactions
            await m.addColumn(transactions, transactions.createdByUserId);
            await m.addColumn(transactions, transactions.lastModifiedByUserId);
            Log.i('Added user tracking columns to transactions', label: 'database');

            // Add sharing columns to wallets
            await m.addColumn(wallets, wallets.ownerUserId);
            await m.addColumn(wallets, wallets.isShared);
            Log.i('Added sharing columns to wallets', label: 'database');
          } catch (e) {
            Log.e('Failed to add family sharing schema: $e', label: 'database');
          }
        }

        // For version 20, add parsed email transactions table for email sync
        if (from < 20) {
          try {
            await m.createTable(parsedEmailTransactions);
            Log.i('Created parsed_email_transactions table for email sync', label: 'database');
          } catch (e) {
            Log.e('Failed to create parsed_email_transactions table: $e', label: 'database');
          }
        }

        // For version 21, add initialBalance column to wallets for tracking
        if (from < 21) {
          try {
            await m.addColumn(wallets, wallets.initialBalance);
            Log.i('Added initialBalance column to wallets', label: 'database');
          } catch (e) {
            Log.e('Failed to add initialBalance column: $e', label: 'database');
          }
        }

        // For version 22, add unified pending_transactions table
        if (from < 22) {
          try {
            await m.createTable(pendingTransactions);
            Log.i('Created pending_transactions table for unified pending review', label: 'database');
          } catch (e) {
            Log.e('Failed to create pending_transactions table: $e', label: 'database');
          }
        }

        // Don't reset database if already at current version
        if (from == to) {
          Log.i('Database already at version $to, no migration needed', label: 'database');
          return;
        }

        if (kDebugMode && from < 9) {
          // In debug mode, clear and recreate everything for old migrations
          // But not for version 9 or later to preserve chat history
          Log.i(
            'Debug mode: Wiping and recreating all tables for upgrade from $from to $to.',
            label: 'database',
          );
          await clearAllDataAndReset();
          await populateData();
          Log.i('All tables recreated after debug upgrade.', label: 'database');

          return; // exit
        }
      },
    );
  }

  /* static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'bexly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  } */

  /// Clears all data from all tables, recreates them, and populates initial data.
  /// This is useful for a full reset of the application's data.
  Future<void> clearAllDataAndReset() async {
    Log.i(
      'Starting database reset: clearing all data and re-initializing tables.',
      label: 'database',
    );
    final migrator = createMigrator();

    // Delete all tables
    for (final table in allTables) {
      try {
        await migrator.deleteTable(table.actualTableName);
        Log.i(
          'Successfully deleted table: ${table.actualTableName} during reset.',
          label: 'database',
        );
      } catch (e) {
        Log.d(
          'Could not delete table ${table.actualTableName} during reset (it might not exist): $e',
          label: 'database',
        );
      }
    }

    // Recreate all tables
    await migrator.createAll();
    Log.i('All tables have been recreated during reset.', label: 'database');

    // Note: Categories will be populated during onboarding when user creates first wallet

    Log.i('Database reset complete.', label: 'database');
  }

  Future<void> populateData() async {
    // Only populate categories - user must create their own wallet
    Log.i('Populating default categories during reset...', label: 'database');
    await CategoryPopulationService.populate(this);
    // Note: Do NOT populate default wallets - user should create their own
  }

  // --- Data Management Methods ---

  Future<void> _deleteAllChecklistItems() => delete(checklistItems).go();
  Future<void> _deleteAllBudgets() => delete(budgets).go();
  Future<void> _deleteAllTransactions() => delete(transactions).go();
  Future<void> _deleteAllGoals() => delete(goals).go();
  Future<void> _deleteAllUsers() => delete(users).go();
  Future<void> _deleteAllWallets() => delete(wallets).go();
  Future<void> _deleteAllCategories() => delete(categories).go();

  /// Clears all data from all tables in the correct order to respect foreign key constraints.
  Future<void> clearAllTables() async {
    Log.i('Clearing all database tables...', label: 'database');
    await transaction(() async {
      // Delete in reverse dependency order
      await _deleteAllChecklistItems();
      await _deleteAllBudgets();
      await _deleteAllTransactions();
      await _deleteAllGoals();
      await _deleteAllUsers(); // Users table has no incoming FKs from other tables
      await _deleteAllWallets();
      await _deleteAllCategories();
    });
    Log.i('All database tables cleared.', label: 'database');
  }

  /// Inserts data into tables in the correct order to respect foreign key constraints.
  /// This method is designed to be used during a restore operation.
  Future<void> insertAllData(
    List<Map<String, dynamic>> usersData,
    List<Map<String, dynamic>> categoriesData,
    List<Map<String, dynamic>> walletsData,
    List<Map<String, dynamic>> budgetsData,
    List<Map<String, dynamic>> goalsData,
    List<Map<String, dynamic>> checklistItemsData,
    List<Map<String, dynamic>> transactionsData,
  ) async {
    Log.i('Inserting all data into database...', label: 'database');
    await transaction(() async {
      // Insert in dependency order
      await batch(
        (b) =>
            b.insertAll(users, usersData.map((e) => User.fromJson(e)).toList()),
      );
      await batch(
        (b) => b.insertAll(
          categories,
          categoriesData.map((e) => Category.fromJson(e)).toList(),
        ),
      );
      await batch(
        (b) => b.insertAll(
          wallets,
          walletsData.map((e) => Wallet.fromJson(e)).toList(),
        ),
      );
      await batch(
        (b) =>
            b.insertAll(goals, goalsData.map((e) => Goal.fromJson(e)).toList()),
      );
      await batch(
        (b) => b.insertAll(
          budgets,
          budgetsData.map((e) => Budget.fromJson(e)).toList(),
        ),
      );
      await batch(
        (b) => b.insertAll(
          transactions,
          transactionsData.map((e) => Transaction.fromJson(e)).toList(),
        ),
      );
      await batch(
        (b) => b.insertAll(
          checklistItems,
          checklistItemsData.map((e) => ChecklistItem.fromJson(e)).toList(),
        ),
      );
    });
    Log.i('All data inserted successfully.', label: 'database');
  }

  Future<void> resetCategories() async {
    Log.i('Deleting and recreating category table...', label: 'database');
    final migrator = createMigrator();
    await migrator.drop(categories);
    await migrator.createTable(categories);

    Log.i('Populating default categories...', label: 'database');
    await CategoryPopulationService.populate(this);
  }

  Future<void> resetWallets() async {
    Log.i('Deleting and recreating wallet table...', label: 'database');
    final migrator = createMigrator();
    await migrator.drop(wallets);
    await migrator.createTable(wallets);

    Log.i('Populating default wallets...', label: 'database');
    await WalletPopulationService.populate(this);
  }
}

