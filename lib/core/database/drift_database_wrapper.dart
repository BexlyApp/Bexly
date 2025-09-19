import 'database_interface.dart';
import 'package:drift/drift.dart' as drift;
import 'database.dart';

class DriftDatabaseWrapper implements DatabaseInterface {
  late AppDatabase _database;

  @override
  Future<void> initialize() async {
    _database = AppDatabase();
  }

  AppDatabase get database => _database;

  @override
  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final wallets = await _database.walletDao.getWallets();
    return wallets.map((w) => w.toJson()).toList();
  }

  @override
  Future<Map<String, dynamic>?> getWallet(String id) async {
    final wallet = await _database.walletDao.getWallet(id);
    return wallet?.toJson();
  }

  @override
  Future<String> createWallet(Map<String, dynamic> wallet) async {
    final companion = WalletsCompanion(
      id: drift.Value(wallet['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      name: drift.Value(wallet['name']),
      currencyCode: drift.Value(wallet['currencyCode']),
      createdAt: drift.Value(wallet['createdAt'] ?? DateTime.now()),
      openingBalance: drift.Value(wallet['openingBalance'] ?? 0.0),
    );

    await _database.walletDao.insertWallet(companion);
    return companion.id.value;
  }

  @override
  Future<void> updateWallet(String id, Map<String, dynamic> wallet) async {
    final companion = WalletsCompanion(
      name: wallet.containsKey('name') ? drift.Value(wallet['name']) : const drift.Value.absent(),
      currencyCode: wallet.containsKey('currencyCode') ? drift.Value(wallet['currencyCode']) : const drift.Value.absent(),
      openingBalance: wallet.containsKey('openingBalance') ? drift.Value(wallet['openingBalance']) : const drift.Value.absent(),
    );

    await _database.walletDao.updateWallet(id, companion);
  }

  @override
  Future<void> deleteWallet(String id) async {
    await _database.walletDao.deleteWallet(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTransactions(String walletId) async {
    final transactions = await _database.transactionDao.getTransactions(walletId);
    return transactions.map((t) => t.toJson()).toList();
  }

  @override
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    final transaction = await _database.transactionDao.getTransaction(id);
    return transaction?.toJson();
  }

  @override
  Future<String> createTransaction(Map<String, dynamic> transaction) async {
    final companion = TransactionsCompanion(
      id: drift.Value(transaction['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      walletId: drift.Value(transaction['walletId']),
      categoryId: drift.Value(transaction['categoryId']),
      amount: drift.Value(transaction['amount']),
      type: drift.Value(TransactionType.values.firstWhere(
        (t) => t.name == transaction['type'],
        orElse: () => TransactionType.expense,
      )),
      date: drift.Value(transaction['date'] ?? DateTime.now()),
      description: drift.Value(transaction['description']),
    );

    await _database.transactionDao.insertTransaction(companion);
    return companion.id.value;
  }

  @override
  Future<void> updateTransaction(String id, Map<String, dynamic> transaction) async {
    final companion = TransactionsCompanion(
      walletId: transaction.containsKey('walletId') ? drift.Value(transaction['walletId']) : const drift.Value.absent(),
      categoryId: transaction.containsKey('categoryId') ? drift.Value(transaction['categoryId']) : const drift.Value.absent(),
      amount: transaction.containsKey('amount') ? drift.Value(transaction['amount']) : const drift.Value.absent(),
      type: transaction.containsKey('type') ? drift.Value(TransactionType.values.firstWhere(
        (t) => t.name == transaction['type'],
        orElse: () => TransactionType.expense,
      )) : const drift.Value.absent(),
      date: transaction.containsKey('date') ? drift.Value(transaction['date']) : const drift.Value.absent(),
      description: transaction.containsKey('description') ? drift.Value(transaction['description']) : const drift.Value.absent(),
    );

    await _database.transactionDao.updateTransaction(id, companion);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _database.transactionDao.deleteTransaction(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final categories = await _database.categoryDao.getCategories();
    return categories.map((c) => c.toJson()).toList();
  }

  @override
  Future<Map<String, dynamic>?> getCategory(String id) async {
    final category = await _database.categoryDao.getCategory(id);
    return category?.toJson();
  }

  @override
  Future<String> createCategory(Map<String, dynamic> category) async {
    final companion = CategoriesCompanion(
      id: drift.Value(category['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      name: drift.Value(category['name']),
      icon: drift.Value(category['icon']),
      color: drift.Value(category['color']),
    );

    await _database.categoryDao.insertCategory(companion);
    return companion.id.value;
  }

  @override
  Future<void> updateCategory(String id, Map<String, dynamic> category) async {
    final companion = CategoriesCompanion(
      name: category.containsKey('name') ? drift.Value(category['name']) : const drift.Value.absent(),
      icon: category.containsKey('icon') ? drift.Value(category['icon']) : const drift.Value.absent(),
      color: category.containsKey('color') ? drift.Value(category['color']) : const drift.Value.absent(),
    );

    await _database.categoryDao.updateCategory(id, companion);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _database.categoryDao.deleteCategory(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllBudgets(String walletId) async {
    final budgets = await _database.budgetDao.getBudgets(walletId);
    return budgets.map((b) => b.toJson()).toList();
  }

  @override
  Future<Map<String, dynamic>?> getBudget(String id) async {
    final budget = await _database.budgetDao.getBudget(id);
    return budget?.toJson();
  }

  @override
  Future<String> createBudget(Map<String, dynamic> budget) async {
    final companion = BudgetsCompanion(
      id: drift.Value(budget['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      walletId: drift.Value(budget['walletId']),
      categoryId: drift.Value(budget['categoryId']),
      amount: drift.Value(budget['amount']),
      period: drift.Value(budget['period']),
      startDate: drift.Value(budget['startDate']),
      endDate: drift.Value(budget['endDate']),
    );

    await _database.budgetDao.insertBudget(companion);
    return companion.id.value;
  }

  @override
  Future<void> updateBudget(String id, Map<String, dynamic> budget) async {
    final companion = BudgetsCompanion(
      walletId: budget.containsKey('walletId') ? drift.Value(budget['walletId']) : const drift.Value.absent(),
      categoryId: budget.containsKey('categoryId') ? drift.Value(budget['categoryId']) : const drift.Value.absent(),
      amount: budget.containsKey('amount') ? drift.Value(budget['amount']) : const drift.Value.absent(),
      period: budget.containsKey('period') ? drift.Value(budget['period']) : const drift.Value.absent(),
      startDate: budget.containsKey('startDate') ? drift.Value(budget['startDate']) : const drift.Value.absent(),
      endDate: budget.containsKey('endDate') ? drift.Value(budget['endDate']) : const drift.Value.absent(),
    );

    await _database.budgetDao.updateBudget(id, companion);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _database.budgetDao.deleteBudget(id);
  }
}