import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';

/// Generates realistic Vietnamese spending data for hackathon demo.
/// Designed to showcase all Shinhan SB1 features:
/// - Financial Health Score (needs budgets + varied spending)
/// - Spending Forecast (needs 2 months of data)
/// - Product Recommendations (dining >3M triggers cashback card)
/// - Anomaly Detection (one large transaction)
/// - Recurring Optimization (multiple subscriptions)
class DemoDataService {
  final AppDatabase _db;
  final _random = Random(42); // Deterministic for consistent demos

  DemoDataService(this._db);

  /// Seed all demo data. Returns count of transactions created.
  Future<int> seedAll() async {
    Log.i('Starting demo data seed...', label: 'DemoData');

    // Get or create wallet
    final wallet = await _getOrCreateWallet();
    if (wallet == null) {
      Log.e('No wallet available for demo data', label: 'DemoData');
      return 0;
    }

    int txCount = 0;

    // Seed last month + this month transactions
    txCount += await _seedTransactions(wallet);

    // Seed budgets
    await _seedBudgets(wallet);

    // Seed goals
    await _seedGoals();

    // Seed recurring payments
    await _seedRecurrings(wallet);

    Log.i('Demo data seeded: $txCount transactions', label: 'DemoData');
    return txCount;
  }

  Future<WalletModel?> _getOrCreateWallet() async {
    final wallets = await _db.walletDao.getAllWallets();
    if (wallets.isNotEmpty) {
      final w = wallets.first;
      return WalletModel(
        id: w.id,
        name: w.name,
        balance: w.balance,
        currency: w.currency,
        createdAt: w.createdAt,
        updatedAt: w.updatedAt,
      );
    }
    return null;
  }

  CategoryModel _cat(int id, String title, String type) => CategoryModel(
        id: id,
        title: title,
        icon: '',
        iconBackground: '',
        iconTypeValue: 'asset',
        transactionType: type,
      );

  double _rand(double base, double variance) =>
      base + (_random.nextDouble() * variance * 2 - variance);

  Future<int> _seedTransactions(WalletModel wallet) async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    int count = 0;

    // === INCOME ===
    // Salary — last month + this month
    for (final month in [lastMonth, thisMonth]) {
      await _addTx(wallet, 'Salary', 25000000, month.add(const Duration(days: 4)),
          _cat(1101, 'Salary', 'income'), TransactionType.income);
      count++;

      // Freelance income
      if (_random.nextBool()) {
        await _addTx(wallet, 'Freelance project', _rand(5000000, 2000000),
            month.add(Duration(days: 12 + _random.nextInt(5))),
            _cat(1103, 'Freelance', 'income'), TransactionType.income);
        count++;
      }
    }

    // === EXPENSES — Last Month ===
    final lastMonthTx = <_TxDef>[
      // Food & Drinks (high — triggers cashback card recommendation)
      _TxDef('Cơm trưa văn phòng', 55000, 102, 'Restaurants'),
      _TxDef('Grab Food — Phở', 75000, 105, 'Takeout'),
      _TxDef('Bách Hóa Xanh', 350000, 101, 'Groceries'),
      _TxDef('Highland Coffee', 65000, 103, 'Coffee'),
      _TxDef('Nhậu cuối tuần', 450000, 102, 'Restaurants'),
      _TxDef('Cơm tấm Sài Gòn', 45000, 102, 'Restaurants'),
      _TxDef('Lotte Mart groceries', 680000, 101, 'Groceries'),
      _TxDef('Trà sữa Phúc Long', 55000, 103, 'Coffee'),
      _TxDef('Bún bò Huế', 60000, 102, 'Restaurants'),
      _TxDef('Co.op Food', 420000, 101, 'Groceries'),
      _TxDef('Starbucks', 95000, 103, 'Coffee'),
      _TxDef('BBQ đãi bạn', 850000, 102, 'Restaurants'),
      // Transportation
      _TxDef('Grab bike x5', 125000, 203, 'Taxi & Rideshare'),
      _TxDef('Xăng xe máy', 150000, 202, 'Fuel/Gas'),
      _TxDef('Grab car đi họp', 85000, 203, 'Taxi & Rideshare'),
      // Housing
      _TxDef('Tiền điện tháng', 850000, 303, 'Utilities'),
      _TxDef('Tiền nước', 120000, 303, 'Utilities'),
      _TxDef('Internet FPT', 250000, 303, 'Utilities'),
      // Shopping
      _TxDef('Shopee — áo mới', 350000, 601, 'Clothing'),
      _TxDef('Tiki — sách', 180000, 605, 'Online Shopping'),
      // Entertainment
      _TxDef('Netflix', 260000, 402, 'Streaming'),
      _TxDef('Spotify', 59000, 402, 'Streaming'),
      _TxDef('YouTube Premium', 79000, 405, 'Subscriptions'),
      _TxDef('CGV cinema', 150000, 401, 'Movies'),
      // Health
      _TxDef('Gym tháng', 500000, 504, 'Fitness'),
      _TxDef('Thuốc cảm', 85000, 502, 'Pharmacy'),
    ];

    for (int i = 0; i < lastMonthTx.length; i++) {
      final tx = lastMonthTx[i];
      final day = 1 + (i * 28 ~/ lastMonthTx.length);
      await _addTx(
        wallet,
        tx.title,
        tx.amount,
        lastMonth.add(Duration(days: day.clamp(0, 27))),
        _cat(tx.catId, tx.catTitle, 'expense'),
        TransactionType.expense,
      );
      count++;
    }

    // === EXPENSES — This Month (partial, realistic pace) ===
    final daysSoFar = min(now.day, 28);
    final thisMonthTx = <_TxDef>[
      // Food — even higher this month (to show MoM increase)
      _TxDef('Cơm trưa VP', 55000, 102, 'Restaurants'),
      _TxDef('Grab Food — Bún chả', 82000, 105, 'Takeout'),
      _TxDef('WinMart groceries', 520000, 101, 'Groceries'),
      _TxDef('Highland Coffee x2', 130000, 103, 'Coffee'),
      _TxDef('Tiệc sinh nhật bạn', 1200000, 102, 'Restaurants'),
      _TxDef('Cơm gà Hải Nam', 65000, 102, 'Restaurants'),
      _TxDef('Bách Hóa Xanh', 380000, 101, 'Groceries'),
      _TxDef('Trà sữa Gong Cha', 75000, 103, 'Coffee'),
      _TxDef('Sushi buffet', 550000, 102, 'Restaurants'),
      // Transport
      _TxDef('Grab bike x3', 95000, 203, 'Taxi & Rideshare'),
      _TxDef('Xăng xe', 160000, 202, 'Fuel/Gas'),
      // Housing
      _TxDef('Tiền điện', 920000, 303, 'Utilities'),
      _TxDef('Tiền nước', 130000, 303, 'Utilities'),
      // Shopping — anomaly: big electronics purchase
      _TxDef('Shopee — tai nghe Sony', 2500000, 602, 'Electronics'),
      _TxDef('Lazada — ốp lưng', 150000, 605, 'Online Shopping'),
      // Entertainment
      _TxDef('Netflix', 260000, 402, 'Streaming'),
      _TxDef('Spotify', 59000, 402, 'Streaming'),
      _TxDef('YouTube Premium', 79000, 405, 'Subscriptions'),
      // Health
      _TxDef('Gym', 500000, 504, 'Fitness'),
    ];

    // Only seed transactions up to today proportionally
    final txToSeed = (thisMonthTx.length * daysSoFar / 28).ceil();
    for (int i = 0; i < min(txToSeed, thisMonthTx.length); i++) {
      final tx = thisMonthTx[i];
      final day = 1 + (i * daysSoFar ~/ txToSeed);
      await _addTx(
        wallet,
        tx.title,
        tx.amount,
        thisMonth.add(Duration(days: day.clamp(0, daysSoFar - 1))),
        _cat(tx.catId, tx.catTitle, 'expense'),
        TransactionType.expense,
      );
      count++;
    }

    return count;
  }

  Future<void> _addTx(WalletModel wallet, String title, double amount,
      DateTime date, CategoryModel cat, TransactionType type) async {
    final tx = TransactionModel(
      title: title,
      amount: amount,
      date: date,
      category: cat,
      wallet: wallet,
      transactionType: type,
      notes: 'Demo data',
    );
    await _db.transactionDao.addTransaction(tx);
  }

  Future<void> _seedBudgets(WalletModel wallet) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final budgets = [
      // Food & Drinks budget — 3M (will be close to limit to trigger coaching)
      BudgetModel(
        wallet: wallet,
        category: _cat(1, 'Food & Drinks', 'expense'),
        amount: 3000000,
        startDate: monthStart,
        endDate: monthEnd,
        isRoutine: true,
        routinePeriod: 'monthly',
      ),
      // Shopping budget — 2M
      BudgetModel(
        wallet: wallet,
        category: _cat(6, 'Shopping', 'expense'),
        amount: 2000000,
        startDate: monthStart,
        endDate: monthEnd,
        isRoutine: true,
        routinePeriod: 'monthly',
      ),
      // Entertainment budget — 1M
      BudgetModel(
        wallet: wallet,
        category: _cat(4, 'Entertainment', 'expense'),
        amount: 1000000,
        startDate: monthStart,
        endDate: monthEnd,
        isRoutine: true,
        routinePeriod: 'monthly',
      ),
    ];

    for (final b in budgets) {
      try {
        await _db.budgetDao.addBudget(b);
      } catch (e) {
        Log.e('Failed to add budget: $e', label: 'DemoData');
      }
    }
  }

  Future<void> _seedGoals() async {
    final now = DateTime.now();

    final goals = [
      GoalsCompanion(
        title: const Value('MacBook Pro M4'),
        targetAmount: const Value(40000000),
        currentAmount: const Value(15000000),
        startDate: Value(now.subtract(const Duration(days: 60))),
        endDate: Value(now.add(const Duration(days: 120))),
        description: const Value('Save for new laptop'),
        pinned: const Value(true),
      ),
      GoalsCompanion(
        title: const Value('Japan Trip 2027'),
        targetAmount: const Value(30000000),
        currentAmount: const Value(8000000),
        startDate: Value(now.subtract(const Duration(days: 30))),
        endDate: Value(DateTime(2027, 3, 1)),
        description: const Value('Cherry blossom season trip'),
        pinned: const Value(false),
      ),
      GoalsCompanion(
        title: const Value('Emergency Fund'),
        targetAmount: const Value(50000000),
        currentAmount: const Value(22000000),
        startDate: Value(now.subtract(const Duration(days: 90))),
        endDate: Value(now.add(const Duration(days: 270))),
        description: const Value('3 months living expenses'),
        pinned: const Value(false),
      ),
    ];

    for (final g in goals) {
      try {
        await _db.goalDao.addGoal(g);
      } catch (e) {
        Log.e('Failed to add goal: $e', label: 'DemoData');
      }
    }
  }

  Future<void> _seedRecurrings(WalletModel wallet) async {
    final now = DateTime.now();

    final recurrings = [
      RecurringModel(
        name: 'Netflix Premium',
        amount: 260000,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(402, 'Streaming', 'expense'),
        frequency: RecurringFrequency.monthly,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 180)),
        nextDueDate: DateTime(now.year, now.month + 1, 5),
        autoCreate: true,
      ),
      RecurringModel(
        name: 'Spotify Family',
        amount: 59000,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(402, 'Streaming', 'expense'),
        frequency: RecurringFrequency.monthly,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 120)),
        nextDueDate: DateTime(now.year, now.month + 1, 10),
        autoCreate: true,
      ),
      RecurringModel(
        name: 'YouTube Premium',
        amount: 79000,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(405, 'Subscriptions', 'expense'),
        frequency: RecurringFrequency.monthly,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 90)),
        nextDueDate: DateTime(now.year, now.month + 1, 1),
        autoCreate: true,
      ),
      RecurringModel(
        name: 'Gym membership',
        amount: 500000,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(504, 'Fitness', 'expense'),
        frequency: RecurringFrequency.monthly,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 365)),
        nextDueDate: DateTime(now.year, now.month + 1, 1),
        autoCreate: true,
      ),
      RecurringModel(
        name: 'FPT Internet',
        amount: 250000,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(303, 'Utilities', 'expense'),
        frequency: RecurringFrequency.monthly,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 365)),
        nextDueDate: DateTime(now.year, now.month + 1, 15),
        autoCreate: true,
      ),
    ];

    for (final r in recurrings) {
      try {
        await _db.recurringDao.addRecurring(r);
      } catch (e) {
        Log.e('Failed to add recurring: $e', label: 'DemoData');
      }
    }
  }
}

class _TxDef {
  final String title;
  final double amount;
  final int catId;
  final String catTitle;

  const _TxDef(this.title, this.amount, this.catId, this.catTitle);
}

/// Provider for DemoDataService
final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  final db = ref.watch(databaseProvider);
  return DemoDataService(db);
});
