import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart';
import 'package:bexly/core/database/daos/category_dao.dart';
import 'package:bexly/core/database/daos/transaction_dao.dart';
import 'package:bexly/core/database/daos/budget_dao.dart';
import 'package:bexly/core/database/daos/goal_dao.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/category_integrity_service.dart';

/// A singleton AppDatabase for the whole app
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  Log.d(db.schemaVersion, label: 'database schema version');
  ref.onDispose(() => db.close());
  return db;
});

/// Category integrity validation provider
/// Validates and auto-repairs category database on first access
final categoryIntegrityProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await CategoryIntegrityService.validateAndRepair(db);
});

/// Wallet DAO provider with sync support
/// Use this instead of db.walletDao when you need sync functionality
final walletDaoProvider = Provider<WalletDao>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletDao(db, ref);
});

/// Category DAO provider with sync support
/// Use this instead of db.categoryDao when you need sync functionality
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryDao(db, ref);
});

/// Transaction DAO provider with sync support
/// Use this instead of db.transactionDao when you need sync functionality
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionDao(db, ref);
});

/// Budget DAO provider with sync support
/// Use this instead of db.budgetDao when you need sync functionality
final budgetDaoProvider = Provider<BudgetDao>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetDao(db, ref);
});

/// Goal DAO provider with sync support
/// Use this instead of db.goalDao when you need sync functionality
final goalDaoProvider = Provider<GoalDao>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalDao(db, ref);
});
