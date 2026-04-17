import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';
import 'package:bexly/features/goal/presentation/riverpod/goals_list_provider.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Financial Health Score breakdown
class FinancialHealthScore {
  final int score; // 0-100
  final double savingsRate; // % of income saved
  final double budgetAdherence; // % of budgets within limit
  final double expenseTrend; // MoM change (-1.0 = 100% decrease, +1.0 = 100% increase)
  final double goalProgress; // avg % of goals completed
  final String grade; // A+, A, B+, B, C+, C, D, F
  final List<String> tips; // Actionable tips

  const FinancialHealthScore({
    required this.score,
    required this.savingsRate,
    required this.budgetAdherence,
    required this.expenseTrend,
    required this.goalProgress,
    required this.grade,
    required this.tips,
  });

  static const empty = FinancialHealthScore(
    score: 0,
    savingsRate: 0,
    budgetAdherence: 0,
    expenseTrend: 0,
    goalProgress: 0,
    grade: '-',
    tips: [],
  );
}

/// Computes a Financial Health Score (0-100) from spending, budgets, goals
final financialHealthProvider =
    FutureProvider.autoDispose<FinancialHealthScore>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final budgetsAsync = ref.watch(budgetListProvider);
  final goalsAsync = ref.watch(goalsListProvider);
  final walletsAsync = ref.watch(allWalletsStreamProvider);

  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return FinancialHealthScore.empty;
  }

  final transactions = transactionsAsync.value ?? [];
  final budgets = budgetsAsync.value ?? [];
  final goals = goalsAsync.value ?? [];
  final wallets = walletsAsync.value ?? [];

  if (transactions.isEmpty) return FinancialHealthScore.empty;

  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final lastMonth = DateTime(now.year, now.month - 1);

  // --- 1. Savings Rate (30 points) ---
  double thisMonthIncome = 0;
  double thisMonthExpense = 0;
  double lastMonthExpense = 0;

  for (final t in transactions) {
    final tMonth = DateTime(t.date.year, t.date.month);
    if (tMonth == thisMonth) {
      if (t.transactionType == TransactionType.income) {
        thisMonthIncome += t.amount;
      } else if (t.transactionType == TransactionType.expense) {
        thisMonthExpense += t.amount;
      }
    } else if (tMonth == lastMonth) {
      if (t.transactionType == TransactionType.expense) {
        lastMonthExpense += t.amount;
      }
    }
  }

  double savingsRate = 0;
  if (thisMonthIncome > 0) {
    savingsRate = ((thisMonthIncome - thisMonthExpense) / thisMonthIncome)
        .clamp(-1.0, 1.0);
  }
  // 20%+ savings = full 30 points, 0% = 10 points, negative = 0
  final savingsScore = savingsRate >= 0.2
      ? 30.0
      : savingsRate >= 0
          ? 10.0 + (savingsRate / 0.2) * 20.0
          : 0.0;

  // --- 2. Budget Adherence (25 points) ---
  double budgetAdherence = 1.0; // default perfect if no budgets
  if (budgets.isNotEmpty) {
    final activeBudgets = budgets.where((b) {
      return b.endDate.isAfter(now) || b.endDate.isAtSameMomentAs(now);
    }).toList();

    if (activeBudgets.isNotEmpty) {
      // Compute spent from transactions matching budget's category + date range
      int withinBudget = 0;
      for (final b in activeBudgets) {
        final spent = transactions
            .where((t) =>
                t.transactionType == TransactionType.expense &&
                t.category.id == b.category.id &&
                !t.date.isBefore(b.startDate) &&
                !t.date.isAfter(b.endDate))
            .fold<double>(0, (sum, t) => sum + t.amount);
        if (spent <= b.amount) withinBudget++;
      }
      budgetAdherence = withinBudget / activeBudgets.length;
    }
  }
  final budgetScore = budgetAdherence * 25.0;

  // --- 3. Expense Trend (20 points) ---
  // Decrease in spending = good, increase = bad
  double expenseTrend = 0;
  if (lastMonthExpense > 0) {
    expenseTrend =
        ((thisMonthExpense - lastMonthExpense) / lastMonthExpense).clamp(-1.0, 1.0);
  }
  // -10% or more decrease = 20 points, 0% = 10 points, +20%+ = 0
  final trendScore = expenseTrend <= -0.1
      ? 20.0
      : expenseTrend <= 0
          ? 10.0 + (expenseTrend.abs() / 0.1) * 10.0
          : max(0.0, 10.0 - (expenseTrend / 0.2) * 10.0);

  // --- 4. Goal Progress (15 points) ---
  double goalProgress = 0;
  if (goals.isNotEmpty) {
    final activeGoals = goals.where((g) => g.targetAmount > 0).toList();
    if (activeGoals.isNotEmpty) {
      final totalProgress = activeGoals.fold<double>(
        0,
        (sum, g) => sum + min(1.0, g.currentAmount / g.targetAmount),
      );
      goalProgress = totalProgress / activeGoals.length;
    }
  }
  final goalScore = goalProgress * 15.0;

  // --- 5. Account Activity (10 points) ---
  // Having wallets, recent transactions, and diverse categories = healthy
  final recentTxCount = transactions
      .where((t) => t.date.isAfter(now.subtract(const Duration(days: 30))))
      .length;
  final hasMultipleWallets = wallets.length >= 2;
  final activityScore = min(10.0,
      (recentTxCount >= 10 ? 5.0 : recentTxCount * 0.5) +
          (hasMultipleWallets ? 3.0 : 0.0) +
          (goals.isNotEmpty ? 2.0 : 0.0));

  // --- Total Score ---
  final totalScore =
      (savingsScore + budgetScore + trendScore + goalScore + activityScore)
          .round()
          .clamp(0, 100);

  // Grade
  String grade;
  if (totalScore >= 90) {
    grade = 'A+';
  } else if (totalScore >= 80) {
    grade = 'A';
  } else if (totalScore >= 70) {
    grade = 'B+';
  } else if (totalScore >= 60) {
    grade = 'B';
  } else if (totalScore >= 50) {
    grade = 'C+';
  } else if (totalScore >= 40) {
    grade = 'C';
  } else if (totalScore >= 30) {
    grade = 'D';
  } else {
    grade = 'F';
  }

  // Tips
  final tips = <String>[];
  if (savingsRate < 0.1) {
    tips.add('Try to save at least 10% of your income each month');
  }
  if (budgetAdherence < 0.8) {
    tips.add('${((1 - budgetAdherence) * 100).round()}% of budgets exceeded — review spending');
  }
  if (expenseTrend > 0.1) {
    tips.add('Spending increased ${(expenseTrend * 100).round()}% vs last month');
  }
  if (goals.isEmpty) {
    tips.add('Set a savings goal to improve your score');
  } else if (goalProgress < 0.3) {
    tips.add('Your goals are behind — consider increasing contributions');
  }

  return FinancialHealthScore(
    score: totalScore,
    savingsRate: savingsRate,
    budgetAdherence: budgetAdherence,
    expenseTrend: expenseTrend,
    goalProgress: goalProgress,
    grade: grade,
    tips: tips,
  );
});
