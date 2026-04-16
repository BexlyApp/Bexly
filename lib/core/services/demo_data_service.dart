import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';

// =============================================================================
// DEMO PERSONAS
// =============================================================================

/// A demo persona with pre-built financial data for hackathon demos.
/// Each persona showcases different Bexly + Shinhan SB1 features.
enum DemoPersona {
  /// Office worker, heavy dining, budget nearly exceeded
  /// Triggers: cashback card recommendation, budget coaching, anomaly alert
  minhTuan,

  /// Freelancer, irregular income, subscription overload
  /// Triggers: recurring optimization, income instability coaching
  thiMai,

  /// Fresh graduate, first job, no financial planning yet
  /// Triggers: full onboarding coaching, budget/goal suggestions
  vanKhoa,

  /// Senior manager, high income, international spending, idle cash
  /// Triggers: FX card, savings account (CASA), insurance recommendation
  thanhHa,

  /// Small business owner, mixed personal/business, needs separation
  /// Triggers: wallet separation coaching, tax planning, loan suggestion
  hoangLong,
}

extension DemoPersonaInfo on DemoPersona {
  String get displayName {
    switch (this) {
      case DemoPersona.minhTuan: return 'Nguyen Minh Tuan';
      case DemoPersona.thiMai: return 'Tran Thi Mai';
      case DemoPersona.vanKhoa: return 'Do Van Khoa';
      case DemoPersona.thanhHa: return 'Pham Thanh Ha';
      case DemoPersona.hoangLong: return 'Le Hoang Long';
    }
  }

  String get subtitle {
    switch (this) {
      case DemoPersona.minhTuan: return 'Office Worker - 20M VND/mo';
      case DemoPersona.thiMai: return 'Freelance Designer - 12-18M VND/mo';
      case DemoPersona.vanKhoa: return 'Fresh Graduate - 10M VND/mo';
      case DemoPersona.thanhHa: return 'Senior Manager - 45M VND/mo';
      case DemoPersona.hoangLong: return 'Business Owner - 35M VND/mo';
    }
  }

  String get description {
    switch (this) {
      case DemoPersona.minhTuan:
        return 'Heavy dining spend, budget nearly exceeded. Showcases cashback card recommendation, budget coaching, spending anomaly alerts.';
      case DemoPersona.thiMai:
        return '5 streaming subscriptions, irregular income. Showcases recurring optimization, income instability coaching.';
      case DemoPersona.vanKhoa:
        return 'First job, no budgets or goals set. Showcases full onboarding coaching, savings suggestions, financial health improvement.';
      case DemoPersona.thanhHa:
        return 'High income with international spending, large idle balance. Showcases FX card, savings account (CASA growth), insurance.';
      case DemoPersona.hoangLong:
        return 'Mixed personal/business expenses. Showcases wallet separation, tax planning, business loan suggestion.';
    }
  }

  String get icon {
    switch (this) {
      case DemoPersona.minhTuan: return '👨‍💼';
      case DemoPersona.thiMai: return '👩‍🎨';
      case DemoPersona.vanKhoa: return '🧑‍🎓';
      case DemoPersona.thanhHa: return '👩‍💻';
      case DemoPersona.hoangLong: return '👨‍🔧';
    }
  }

  /// Features this persona demonstrates
  List<String> get demoFeatures {
    switch (this) {
      case DemoPersona.minhTuan:
        return ['Cashback Card', 'Budget Alert', 'Anomaly Detection', 'Spending Forecast'];
      case DemoPersona.thiMai:
        return ['Recurring Optimization', 'Income Coaching', 'Budget Suggestion', 'Health Score'];
      case DemoPersona.vanKhoa:
        return ['Onboarding Coach', 'Savings Suggestion', 'Goal Setting', 'Daily Digest'];
      case DemoPersona.thanhHa:
        return ['FX Card', 'CASA Growth', 'Insurance', 'High Balance Coaching'];
      case DemoPersona.hoangLong:
        return ['Wallet Separation', 'Business Loan', 'Tax Planning', 'Multi-Wallet'];
    }
  }
}

// =============================================================================
// DEMO DATA SERVICE
// =============================================================================

/// Generates realistic Vietnamese spending data for hackathon demo.
/// Supports 5 distinct personas, each showcasing different Shinhan SB1 features.
class DemoDataService {
  final AppDatabase _db;
  final _random = Random(42); // Deterministic for consistent demos

  DemoDataService(this._db);

  // ---- Category helper ----
  CategoryModel _cat(int id, String title, String type) => CategoryModel(
        id: id,
        title: title,
        icon: '',
        iconBackground: '',
        iconTypeValue: 'asset',
        transactionType: type,
      );


  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Clear all demo data (transactions, budgets, goals, recurring, wallets with 'Demo' notes).
  /// Preserves user-created data.
  Future<void> clearDemoData() async {
    Log.i('Clearing demo data...', label: 'DemoData');

    // Delete transactions with 'Demo data' notes
    await _db.customStatement(
      "DELETE FROM transactions WHERE notes = 'Demo data'",
    );

    // Delete budgets in Shinhan wallets (demo wallets)
    await _db.customStatement(
      "DELETE FROM budgets WHERE wallet_id IN (SELECT id FROM wallets WHERE name LIKE 'Shinhan%')",
    );

    // Delete goals with demo description
    await _db.customStatement(
      "DELETE FROM goals WHERE description LIKE '%Demo data%'",
    );

    // Delete recurring with demo notes
    await _db.customStatement(
      "DELETE FROM recurrings WHERE notes = 'Demo data'",
    );

    // Delete wallets created by demo (name starts with 'Shinhan')
    await _db.customStatement(
      "DELETE FROM wallets WHERE name LIKE 'Shinhan%'",
    );

    // Delete chat messages to start fresh
    await _db.customStatement("DELETE FROM chat_messages");

    Log.i('Demo data cleared', label: 'DemoData');
  }

  /// Seed demo data for a specific persona. Clears previous demo data first.
  Future<int> seedPersona(DemoPersona persona) async {
    Log.i('Seeding persona: ${persona.displayName}', label: 'DemoData');

    await clearDemoData();

    switch (persona) {
      case DemoPersona.minhTuan:
        return _seedMinhTuan();
      case DemoPersona.thiMai:
        return _seedThiMai();
      case DemoPersona.vanKhoa:
        return _seedVanKhoa();
      case DemoPersona.thanhHa:
        return _seedThanhHa();
      case DemoPersona.hoangLong:
        return _seedHoangLong();
    }
  }

  /// Legacy method - seeds default persona (Minh Tuan)
  Future<int> seedAll() async => seedPersona(DemoPersona.minhTuan);

  // =========================================================================
  // SHARED HELPERS
  // =========================================================================

  Future<WalletModel> _createWallet({
    required String name,
    required double balance,
    String currency = 'VND',
    WalletType walletType = WalletType.bankAccount,
    String colorHex = '005BA1',
  }) async {
    final wallet = WalletModel(
      name: name,
      balance: balance,
      currency: currency,
      iconName: 'bank',
      colorHex: colorHex,
      walletType: walletType,
    );
    final id = await _db.walletDao.addWallet(wallet);
    return wallet.copyWith(id: id);
  }

  Future<WalletModel?> _getOrCreateCashWallet() async {
    final wallets = await _db.walletDao.getAllWallets();
    final cash = wallets.where((w) =>
        w.walletType == WalletType.cash.name ||
        w.name.toLowerCase().contains('cash') ||
        w.name.toLowerCase().contains('tien mat')).toList();
    if (cash.isNotEmpty) {
      final w = cash.first;
      return WalletModel(
        id: w.id,
        name: w.name,
        balance: w.balance,
        currency: w.currency,
        walletType: WalletType.cash,
      );
    }
    // Create one
    return _createWallet(
      name: 'Cash',
      balance: 2500000,
      walletType: WalletType.cash,
      colorHex: '22C55E',
    );
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

  Future<void> _addBudget(WalletModel wallet, CategoryModel cat, double amount) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    try {
      await _db.budgetDao.addBudget(BudgetModel(
        wallet: wallet,
        category: cat,
        amount: amount,
        startDate: monthStart,
        endDate: monthEnd,
        isRoutine: true,
        routinePeriod: 'monthly',
      ));
    } catch (e) {
      Log.w('Budget already exists or error: $e', label: 'DemoData');
    }
  }

  Future<void> _addGoal(String title, double target, double current,
      {int daysAgo = 60, int daysUntil = 120, bool pinned = false}) async {
    final now = DateTime.now();
    try {
      await _db.goalDao.addGoal(GoalsCompanion(
        title: Value(title),
        targetAmount: Value(target),
        currentAmount: Value(current),
        startDate: Value(now.subtract(Duration(days: daysAgo))),
        endDate: Value(now.add(Duration(days: daysUntil))),
        description: const Value('Demo data'),
        pinned: Value(pinned),
      ));
    } catch (e) {
      Log.w('Goal error: $e', label: 'DemoData');
    }
  }

  Future<void> _addRecurring(WalletModel wallet, String name, double amount,
      int catId, String catTitle, RecurringFrequency freq,
      {int dayOfMonth = 1}) async {
    final now = DateTime.now();
    try {
      await _db.recurringDao.addRecurring(RecurringModel(
        name: name,
        amount: amount,
        currency: wallet.currency,
        wallet: wallet,
        category: _cat(catId, catTitle, 'expense'),
        frequency: freq,
        status: RecurringStatus.active,
        startDate: now.subtract(const Duration(days: 180)),
        nextDueDate: DateTime(now.year, now.month + 1, dayOfMonth),
        autoCreate: true,
        notes: 'Demo data',
      ));
    } catch (e) {
      Log.w('Recurring error: $e', label: 'DemoData');
    }
  }

  /// Generate transactions for a wallet spread across last month and this month
  Future<int> _seedMonthlyTransactions(
    WalletModel wallet,
    List<_TxDef> lastMonthTx,
    List<_TxDef> thisMonthTx,
    List<_TxDef> incomes,
  ) async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    int count = 0;

    // Income - both months
    for (final inc in incomes) {
      for (final month in [lastMonth, thisMonth]) {
        await _addTx(wallet, inc.title, inc.amount,
            month.add(Duration(days: inc.day)),
            _cat(inc.catId, inc.catTitle, 'income'), TransactionType.income);
        count++;
      }
    }

    // Last month expenses - spread across 28 days
    for (int i = 0; i < lastMonthTx.length; i++) {
      final tx = lastMonthTx[i];
      final day = tx.day > 0 ? tx.day : 1 + (i * 28 ~/ lastMonthTx.length);
      await _addTx(wallet, tx.title, tx.amount,
          lastMonth.add(Duration(days: day.clamp(0, 27))),
          _cat(tx.catId, tx.catTitle, 'expense'), TransactionType.expense);
      count++;
    }

    // This month expenses - only up to today
    final daysSoFar = min(now.day, 28);
    final txToSeed = (thisMonthTx.length * daysSoFar / 28).ceil();
    for (int i = 0; i < min(txToSeed, thisMonthTx.length); i++) {
      final tx = thisMonthTx[i];
      final day = tx.day > 0 ? tx.day : 1 + (i * daysSoFar ~/ txToSeed);
      await _addTx(wallet, tx.title, tx.amount,
          thisMonth.add(Duration(days: day.clamp(0, daysSoFar - 1))),
          _cat(tx.catId, tx.catTitle, 'expense'), TransactionType.expense);
      count++;
    }

    return count;
  }

  // =========================================================================
  // PERSONA 1: NGUYEN MINH TUAN - Office Worker
  // Showcases: Cashback Card, Budget Alert, Anomaly Detection, Forecast
  // =========================================================================
  Future<int> _seedMinhTuan() async {
    // Wallets
    final shinhanChecking = await _createWallet(
      name: 'Shinhan Checking',
      balance: 18500000,
      colorHex: '0066B3',
    );
    await _createWallet(
      name: 'Shinhan Savings',
      balance: 30000000,
      walletType: WalletType.savings,
      colorHex: '00A651',
    );
    final cash = await _getOrCreateCashWallet();

    int count = 0;

    // -- Shinhan Checking: salary + main spending --
    count += await _seedMonthlyTransactions(shinhanChecking,
      // Last month expenses
      [
        _TxDef('Com trua van phong', 55000, 102, 'Restaurants'),
        _TxDef('Grab Food - Pho', 75000, 105, 'Takeout'),
        _TxDef('Bach Hoa Xanh', 350000, 101, 'Groceries'),
        _TxDef('Highland Coffee', 65000, 103, 'Coffee'),
        _TxDef('Nhau cuoi tuan', 450000, 102, 'Restaurants'),
        _TxDef('Com tam Sai Gon', 45000, 102, 'Restaurants'),
        _TxDef('Lotte Mart', 680000, 101, 'Groceries'),
        _TxDef('Tra sua Phuc Long', 55000, 103, 'Coffee'),
        _TxDef('Bun bo Hue', 60000, 102, 'Restaurants'),
        _TxDef('Co.op Food', 420000, 101, 'Groceries'),
        _TxDef('Starbucks', 95000, 103, 'Coffee'),
        _TxDef('BBQ dai ban', 850000, 102, 'Restaurants'),
        _TxDef('Grab bike x5', 125000, 203, 'Taxi & Rideshare'),
        _TxDef('Xang xe may', 150000, 202, 'Fuel/Gas'),
        _TxDef('Grab car di hop', 85000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien dien', 850000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 120000, 303, 'Utilities'),
        _TxDef('Internet FPT', 250000, 303, 'Utilities'),
        _TxDef('Shopee - ao moi', 350000, 601, 'Clothing'),
        _TxDef('CGV cinema', 150000, 401, 'Movies'),
        _TxDef('Gym thang', 500000, 504, 'Fitness'),
        _TxDef('Thuoc cam', 85000, 502, 'Pharmacy'),
      ],
      // This month expenses (higher dining - triggers coaching)
      [
        _TxDef('Com trua VP', 55000, 102, 'Restaurants'),
        _TxDef('Grab Food - Bun cha', 82000, 105, 'Takeout'),
        _TxDef('WinMart', 520000, 101, 'Groceries'),
        _TxDef('Highland Coffee x2', 130000, 103, 'Coffee'),
        _TxDef('Tiec sinh nhat ban', 1200000, 102, 'Restaurants'),
        _TxDef('Com ga Hai Nam', 65000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 380000, 101, 'Groceries'),
        _TxDef('Tra sua Gong Cha', 75000, 103, 'Coffee'),
        _TxDef('Sushi buffet', 550000, 102, 'Restaurants'),
        _TxDef('Grab bike x3', 95000, 203, 'Taxi & Rideshare'),
        _TxDef('Xang xe', 160000, 202, 'Fuel/Gas'),
        _TxDef('Tien dien', 920000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 130000, 303, 'Utilities'),
        // Anomaly: big electronics purchase
        _TxDef('Shopee - tai nghe Sony', 2500000, 602, 'Electronics'),
        _TxDef('Lazada - op lung', 150000, 605, 'Online Shopping'),
        _TxDef('Gym', 500000, 504, 'Fitness'),
      ],
      // Income
      [
        _TxDef.income('Luong thang', 20000000, 1101, 'Salary', day: 5),
      ],
    );

    // Cash wallet small transactions
    for (final tx in [
      _TxDef('Banh mi sang', 25000, 105, 'Takeout'),
      _TxDef('Nuoc suoi', 10000, 104, 'Snacks'),
      _TxDef('Gui xe', 5000, 205, 'Parking'),
    ]) {
      if (cash != null) {
        await _addTx(cash, tx.title, tx.amount,
            DateTime.now().subtract(Duration(days: _random.nextInt(5))),
            _cat(tx.catId, tx.catTitle, 'expense'), TransactionType.expense);
        count++;
      }
    }

    // Budgets (Food 3M will be close to exceeded)
    await _addBudget(shinhanChecking, _cat(1, 'Food & Drinks', 'expense'), 3000000);
    await _addBudget(shinhanChecking, _cat(6, 'Shopping', 'expense'), 2000000);
    await _addBudget(shinhanChecking, _cat(4, 'Entertainment', 'expense'), 1000000);

    // Goals
    await _addGoal('MacBook Pro M4', 40000000, 15000000, pinned: true);
    await _addGoal('Japan Trip 2027', 30000000, 8000000, daysUntil: 300);
    await _addGoal('Emergency Fund', 50000000, 22000000, daysUntil: 270);

    // Recurring
    await _addRecurring(shinhanChecking, 'Netflix Premium', 260000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 5);
    await _addRecurring(shinhanChecking, 'Spotify Family', 59000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 10);
    await _addRecurring(shinhanChecking, 'YouTube Premium', 79000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'Gym membership', 500000, 504, 'Fitness', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'FPT Internet', 250000, 303, 'Utilities', RecurringFrequency.monthly, dayOfMonth: 15);

    Log.i('Minh Tuan seeded: $count transactions', label: 'DemoData');
    return count;
  }

  // =========================================================================
  // PERSONA 2: TRAN THI MAI - Freelance Designer
  // Showcases: Recurring Optimization, Income Coaching, Budget Suggestion
  // =========================================================================
  Future<int> _seedThiMai() async {
    final shinhanChecking = await _createWallet(
      name: 'Shinhan Checking',
      balance: 8200000,
      colorHex: '0066B3',
    );
    await _getOrCreateCashWallet();

    int count = 0;

    count += await _seedMonthlyTransactions(shinhanChecking,
      // Last month (good month - 18M income)
      [
        _TxDef('Grab Food', 85000, 105, 'Takeout'),
        _TxDef('Co.op Mart', 450000, 101, 'Groceries'),
        _TxDef('The Coffee House', 75000, 103, 'Coffee'),
        _TxDef('Com trua', 50000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 280000, 101, 'Groceries'),
        _TxDef('Bubble tea', 55000, 103, 'Coffee'),
        _TxDef('Grab bike', 65000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien dien', 650000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 100000, 303, 'Utilities'),
        _TxDef('Viettel internet', 200000, 303, 'Utilities'),
        _TxDef('Shopee - vat dung', 180000, 605, 'Online Shopping'),
        _TxDef('Figma Pro', 350000, 405, 'Subscriptions'),
        _TxDef('Adobe CC', 680000, 405, 'Subscriptions'),
        _TxDef('Canva Pro', 200000, 405, 'Subscriptions'),
        _TxDef('iCloud 200GB', 69000, 405, 'Subscriptions'),
        _TxDef('Notion Plus', 120000, 405, 'Subscriptions'),
        _TxDef('Yoga class', 300000, 504, 'Fitness'),
      ],
      // This month (lean month - only 12M income, same spending)
      [
        _TxDef('Grab Food', 95000, 105, 'Takeout'),
        _TxDef('WinMart', 380000, 101, 'Groceries'),
        _TxDef('Highland Coffee', 65000, 103, 'Coffee'),
        _TxDef('Com trua', 55000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 320000, 101, 'Groceries'),
        _TxDef('Grab bike', 75000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien dien', 700000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 110000, 303, 'Utilities'),
        _TxDef('Shopee - giay dep', 450000, 603, 'Shoes'),
        _TxDef('Figma Pro', 350000, 405, 'Subscriptions'),
        _TxDef('Adobe CC', 680000, 405, 'Subscriptions'),
        _TxDef('Canva Pro', 200000, 405, 'Subscriptions'),
        _TxDef('iCloud 200GB', 69000, 405, 'Subscriptions'),
        _TxDef('Notion Plus', 120000, 405, 'Subscriptions'),
        _TxDef('Yoga class', 300000, 504, 'Fitness'),
      ],
      // Income (irregular)
      [
        _TxDef.income('Freelance - Logo design', 8000000, 1103, 'Freelance', day: 8),
        _TxDef.income('Freelance - UI project', 4000000, 1103, 'Freelance', day: 20),
      ],
    );

    // 5 streaming subscriptions (triggers recurring optimization)
    await _addRecurring(shinhanChecking, 'Netflix', 180000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 5);
    await _addRecurring(shinhanChecking, 'Spotify', 59000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 10);
    await _addRecurring(shinhanChecking, 'YouTube Premium', 79000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'Apple Music', 49000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 15);
    await _addRecurring(shinhanChecking, 'Disney+ Hotstar', 99000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 20);
    // Work tools
    await _addRecurring(shinhanChecking, 'Figma Pro', 350000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'Adobe CC', 680000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'Canva Pro', 200000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);

    // No budgets set (AI should suggest)
    // One goal
    await _addGoal('New iPad Pro', 25000000, 5000000, pinned: true);

    Log.i('Thi Mai seeded: $count transactions', label: 'DemoData');
    return count;
  }

  // =========================================================================
  // PERSONA 3: DO VAN KHOA - Fresh Graduate
  // Showcases: Onboarding Coach, Savings Suggestion, Goal Setting
  // =========================================================================
  Future<int> _seedVanKhoa() async {
    final shinhanChecking = await _createWallet(
      name: 'Shinhan Checking',
      balance: 3200000,
      colorHex: '0066B3',
    );
    await _getOrCreateCashWallet();

    int count = 0;

    count += await _seedMonthlyTransactions(shinhanChecking,
      // Last month (first month working - spending everything)
      [
        _TxDef('Com trua', 45000, 102, 'Restaurants'),
        _TxDef('Tra da', 15000, 103, 'Coffee'),
        _TxDef('Grab Food', 65000, 105, 'Takeout'),
        _TxDef('Com trua VP', 50000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 250000, 101, 'Groceries'),
        _TxDef('Nhau voi ban', 350000, 102, 'Restaurants'),
        _TxDef('Grab bike', 45000, 203, 'Taxi & Rideshare'),
        _TxDef('Xang xe', 100000, 202, 'Fuel/Gas'),
        _TxDef('Tien tro', 3500000, 301, 'Rent'),
        _TxDef('Tien dien nuoc', 500000, 303, 'Utilities'),
        _TxDef('Shopee - quan ao', 650000, 601, 'Clothing'),
        _TxDef('Shopee - phu kien', 280000, 605, 'Online Shopping'),
        _TxDef('Game mobile', 150000, 403, 'Gaming'),
        _TxDef('Di choi cuoi tuan', 500000, 404, 'Events'),
        _TxDef('Sua chua xe', 350000, 204, 'Vehicle Maintenance'),
      ],
      // This month (same pattern - no improvement, low savings)
      [
        _TxDef('Com trua', 50000, 102, 'Restaurants'),
        _TxDef('Tra da', 15000, 103, 'Coffee'),
        _TxDef('Grab Food', 72000, 105, 'Takeout'),
        _TxDef('Com VP', 45000, 102, 'Restaurants'),
        _TxDef('Co.op Mart', 280000, 101, 'Groceries'),
        _TxDef('Karaoke', 400000, 404, 'Events'),
        _TxDef('Grab bike', 55000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien tro', 3500000, 301, 'Rent', day: 1),
        _TxDef('Tien dien nuoc', 520000, 303, 'Utilities', day: 5),
        _TxDef('Shopee - giay Nike', 1800000, 603, 'Shoes'),
        _TxDef('Game top-up', 200000, 403, 'Gaming'),
      ],
      // Income
      [
        _TxDef.income('Luong thang', 10000000, 1101, 'Salary', day: 5),
      ],
    );

    // Only Netflix recurring
    await _addRecurring(shinhanChecking, 'Netflix Basic', 108000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 15);

    // No budgets, no goals (AI should onboard)

    Log.i('Van Khoa seeded: $count transactions', label: 'DemoData');
    return count;
  }

  // =========================================================================
  // PERSONA 4: PHAM THANH HA - Senior Manager
  // Showcases: FX Card, CASA Growth, Insurance, High Balance Coaching
  // =========================================================================
  Future<int> _seedThanhHa() async {
    final shinhanChecking = await _createWallet(
      name: 'Shinhan Checking',
      balance: 85000000,
      colorHex: '0066B3',
    );
    await _createWallet(
      name: 'Shinhan Savings 6M',
      balance: 200000000,
      walletType: WalletType.savings,
      colorHex: '00A651',
    );
    final shinhanCredit = await _createWallet(
      name: 'Shinhan Credit Card',
      balance: -12500000,
      walletType: WalletType.creditCard,
      colorHex: 'E31837',
    );
    await _getOrCreateCashWallet();

    int count = 0;

    // Checking account - main transactions
    count += await _seedMonthlyTransactions(shinhanChecking,
      // Last month
      [
        _TxDef('Grab Premium', 250000, 203, 'Taxi & Rideshare'),
        _TxDef('Lunch meeting - Park Hyatt', 1500000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 800000, 101, 'Groceries'),
        _TxDef('Highland Coffee', 85000, 103, 'Coffee'),
        _TxDef('Dinner - Japanese', 1200000, 102, 'Restaurants'),
        _TxDef('Tien dien', 1200000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 180000, 303, 'Utilities'),
        _TxDef('Internet VNPT', 350000, 303, 'Utilities'),
        _TxDef('Grab car x10', 450000, 203, 'Taxi & Rideshare'),
        _TxDef('Gym California', 1500000, 504, 'Fitness'),
        _TxDef('Shopee - skincare', 850000, 605, 'Online Shopping'),
        _TxDef('CGV IMAX', 250000, 401, 'Movies'),
        // International spending (triggers FX card suggestion)
        _TxDef('Amazon.com - books', 1200000, 605, 'Online Shopping'),
        _TxDef('Udemy course (USD)', 350000, 703, 'Online Courses'),
        _TxDef('App Store (USD)', 250000, 405, 'Subscriptions'),
      ],
      // This month
      [
        _TxDef('Grab Premium', 280000, 203, 'Taxi & Rideshare'),
        _TxDef('Business lunch - Sofitel', 2000000, 102, 'Restaurants'),
        _TxDef('WinMart Premium', 950000, 101, 'Groceries'),
        _TxDef('Starbucks Reserve', 120000, 103, 'Coffee'),
        _TxDef('Family dinner - Korean BBQ', 1800000, 102, 'Restaurants'),
        _TxDef('Tien dien', 1300000, 303, 'Utilities'),
        _TxDef('Grab car x8', 380000, 203, 'Taxi & Rideshare'),
        _TxDef('Gym California', 1500000, 504, 'Fitness'),
        // More international (FX card trigger)
        _TxDef('AWS services (USD)', 800000, 405, 'Subscriptions'),
        _TxDef('Coursera Plus (USD)', 650000, 703, 'Online Courses'),
        _TxDef('Amazon - gadget (USD)', 2500000, 602, 'Electronics'),
      ],
      // Income (high)
      [
        _TxDef.income('Luong thang', 45000000, 1101, 'Salary', day: 1),
        _TxDef.income('Thuong KPI', 5000000, 1102, 'Bonus', day: 10),
      ],
    );

    // Credit card transactions
    for (final tx in [
      _TxDef('Zara - ao khoac', 1800000, 601, 'Clothing'),
      _TxDef('Uniqlo', 950000, 601, 'Clothing'),
      _TxDef('Booking.com - Da Lat', 3500000, 802, 'Hotels'),
      _TxDef('VietJet Air', 1200000, 801, 'Flights'),
      _TxDef('Lazada - may hut bui', 5050000, 602, 'Electronics'),
    ]) {
      await _addTx(shinhanCredit, tx.title, tx.amount,
          DateTime.now().subtract(Duration(days: _random.nextInt(25))),
          _cat(tx.catId, tx.catTitle, 'expense'), TransactionType.expense);
      count++;
    }

    // Budgets
    await _addBudget(shinhanChecking, _cat(1, 'Food & Drinks', 'expense'), 8000000);
    await _addBudget(shinhanChecking, _cat(6, 'Shopping', 'expense'), 5000000);
    await _addBudget(shinhanChecking, _cat(8, 'Travel', 'expense'), 10000000);

    // Goals
    await _addGoal('Apartment Down Payment', 500000000, 180000000, pinned: true, daysUntil: 365);
    await _addGoal('Europe Trip', 80000000, 25000000, daysUntil: 200);

    // Recurring
    await _addRecurring(shinhanChecking, 'Netflix Premium', 260000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 5);
    await _addRecurring(shinhanChecking, 'Spotify Premium', 59000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 10);
    await _addRecurring(shinhanChecking, 'Gym California', 1500000, 504, 'Fitness', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanChecking, 'VNPT Internet', 350000, 303, 'Utilities', RecurringFrequency.monthly, dayOfMonth: 15);

    // No insurance (triggers insurance recommendation)

    Log.i('Thanh Ha seeded: $count transactions', label: 'DemoData');
    return count;
  }

  // =========================================================================
  // PERSONA 5: LE HOANG LONG - Business Owner
  // Showcases: Wallet Separation, Business Loan, Tax Planning, Multi-Wallet
  // =========================================================================
  Future<int> _seedHoangLong() async {
    final shinhanBusiness = await _createWallet(
      name: 'Shinhan Business',
      balance: 45000000,
      colorHex: '0066B3',
    );
    final shinhanPersonal = await _createWallet(
      name: 'Shinhan Personal',
      balance: 12000000,
      colorHex: '5B2D8E',
    );
    await _getOrCreateCashWallet();

    int count = 0;

    // Business account
    count += await _seedMonthlyTransactions(shinhanBusiness,
      // Last month business expenses
      [
        _TxDef('Van phong pham', 350000, 705, 'School Supplies'),
        _TxDef('Hosting DigitalOcean', 800000, 405, 'Subscriptions'),
        _TxDef('Google Workspace', 350000, 405, 'Subscriptions'),
        _TxDef('Tien thue mat bang', 8000000, 301, 'Rent'),
        _TxDef('Tien dien cua hang', 1500000, 303, 'Utilities'),
        _TxDef('Mua hang nhap', 12000000, 605, 'Online Shopping'),
        _TxDef('Grab delivery', 250000, 203, 'Taxi & Rideshare'),
        _TxDef('Facebook Ads', 3000000, 405, 'Subscriptions'),
        _TxDef('Luong nhan vien 1', 7000000, 1101, 'Salary'),
        _TxDef('Luong nhan vien 2', 6000000, 1101, 'Salary'),
      ],
      // This month business expenses
      [
        _TxDef('Van phong pham', 280000, 705, 'School Supplies'),
        _TxDef('Hosting DigitalOcean', 800000, 405, 'Subscriptions'),
        _TxDef('Google Workspace', 350000, 405, 'Subscriptions'),
        _TxDef('Tien thue mat bang', 8000000, 301, 'Rent', day: 1),
        _TxDef('Tien dien cua hang', 1600000, 303, 'Utilities', day: 5),
        _TxDef('Mua hang nhap', 15000000, 605, 'Online Shopping'),
        _TxDef('Facebook Ads', 4000000, 405, 'Subscriptions'),
        _TxDef('Luong NV 1', 7000000, 1101, 'Salary'),
        _TxDef('Luong NV 2', 6000000, 1101, 'Salary'),
        // Big equipment purchase (triggers loan suggestion)
        _TxDef('May in cong nghiep', 25000000, 602, 'Electronics'),
      ],
      // Business income
      [
        _TxDef.income('Doanh thu ban hang', 35000000, 1104, 'Business Income', day: 15),
        _TxDef.income('Doanh thu online', 12000000, 1104, 'Business Income', day: 25),
      ],
    );

    // Personal account - mixed with some business (triggers separation coaching)
    count += await _seedMonthlyTransactions(shinhanPersonal,
      // Last month personal
      [
        _TxDef('Com trua', 55000, 102, 'Restaurants'),
        _TxDef('Bach Hoa Xanh', 350000, 101, 'Groceries'),
        _TxDef('Grab bike', 65000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien dien nha', 750000, 303, 'Utilities'),
        _TxDef('Tien nuoc', 120000, 303, 'Utilities'),
        // Business expense in personal account (bad practice)
        _TxDef('Mua hang cho shop', 3500000, 605, 'Online Shopping'),
        _TxDef('Tiep khach', 1200000, 102, 'Restaurants'),
      ],
      // This month personal
      [
        _TxDef('Com trua', 50000, 102, 'Restaurants'),
        _TxDef('WinMart', 400000, 101, 'Groceries'),
        _TxDef('Grab bike', 70000, 203, 'Taxi & Rideshare'),
        _TxDef('Tien dien nha', 800000, 303, 'Utilities'),
        // Again mixed business/personal
        _TxDef('Ship hang cho khach', 150000, 203, 'Taxi & Rideshare'),
        _TxDef('Mua sample san pham', 2000000, 605, 'Online Shopping'),
      ],
      // Personal income (transfer from business)
      [
        _TxDef.income('Chuyen tu TK kinh doanh', 15000000, 1104, 'Business Income', day: 5),
      ],
    );

    // Budgets
    await _addBudget(shinhanBusiness, _cat(1, 'Food & Drinks', 'expense'), 2000000);
    await _addBudget(shinhanPersonal, _cat(1, 'Food & Drinks', 'expense'), 3000000);

    // Goals
    await _addGoal('Mo rong cua hang', 100000000, 30000000, pinned: true, daysUntil: 180);
    await _addGoal('Mua xe tai', 250000000, 50000000, daysUntil: 365);

    // Recurring
    await _addRecurring(shinhanBusiness, 'Tien thue mat bang', 8000000, 301, 'Rent', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanBusiness, 'DigitalOcean', 800000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanBusiness, 'Google Workspace', 350000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanBusiness, 'Facebook Ads', 3000000, 405, 'Subscriptions', RecurringFrequency.monthly, dayOfMonth: 1);
    await _addRecurring(shinhanPersonal, 'Netflix', 180000, 402, 'Streaming', RecurringFrequency.monthly, dayOfMonth: 10);

    Log.i('Hoang Long seeded: $count transactions', label: 'DemoData');
    return count;
  }
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _TxDef {
  final String title;
  final double amount;
  final int catId;
  final String catTitle;
  final int day; // 0 = auto-distribute

  const _TxDef(this.title, this.amount, this.catId, this.catTitle, {this.day = 0});

  const _TxDef.income(this.title, this.amount, this.catId, this.catTitle, {this.day = 5});
}

/// Provider for DemoDataService
final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  final db = ref.watch(databaseProvider);
  return DemoDataService(db);
});
