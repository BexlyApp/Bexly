import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Spending forecast data
class SpendingForecast {
  final double projectedExpense; // End-of-month projected expense
  final double projectedIncome; // End-of-month projected income
  final double projectedBalance; // End-of-month projected wallet balance
  final double dailyBurnRate; // Average daily spending
  final double dailyEarnRate; // Average daily income
  final int daysRemaining; // Days left in month
  final double currentBalance; // Current wallet balance
  final String summary; // Human-readable summary

  const SpendingForecast({
    required this.projectedExpense,
    required this.projectedIncome,
    required this.projectedBalance,
    required this.dailyBurnRate,
    required this.dailyEarnRate,
    required this.daysRemaining,
    required this.currentBalance,
    required this.summary,
  });

  static const empty = SpendingForecast(
    projectedExpense: 0,
    projectedIncome: 0,
    projectedBalance: 0,
    dailyBurnRate: 0,
    dailyEarnRate: 0,
    daysRemaining: 0,
    currentBalance: 0,
    summary: '',
  );

  bool get isEmpty => projectedExpense == 0 && projectedIncome == 0;
}

/// Computes end-of-month spending forecast based on current velocity
final spendingForecastProvider =
    FutureProvider.autoDispose<SpendingForecast>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final walletsAsync = ref.watch(allWalletsStreamProvider);

  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return SpendingForecast.empty;
  }

  final transactions = transactionsAsync.value ?? [];
  final wallets = walletsAsync.value ?? [];

  if (transactions.isEmpty) return SpendingForecast.empty;

  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysElapsed = now.day;
  final daysRemaining = daysInMonth - daysElapsed;

  if (daysElapsed == 0) return SpendingForecast.empty;

  final monthStart = DateTime(now.year, now.month, 1);

  // Current month transactions
  final mtdTx = transactions.where((t) =>
      !t.date.isBefore(monthStart) &&
      t.date.isBefore(now.add(const Duration(days: 1)))).toList();

  final mtdExpense = mtdTx
      .where((t) => t.transactionType == TransactionType.expense)
      .fold<double>(0, (s, t) => s + t.amount);
  final mtdIncome = mtdTx
      .where((t) => t.transactionType == TransactionType.income)
      .fold<double>(0, (s, t) => s + t.amount);

  // Daily rates
  final dailyBurnRate = mtdExpense / daysElapsed;
  final dailyEarnRate = mtdIncome / daysElapsed;

  // Projections
  final projectedExpense = mtdExpense + (dailyBurnRate * daysRemaining);
  final projectedIncome = mtdIncome + (dailyEarnRate * daysRemaining);

  // Current total balance across all wallets
  final totalBalance = wallets.fold<double>(0, (s, w) => s + w.balance);

  // Projected balance = current balance - remaining projected net outflow
  final remainingNet = (dailyEarnRate - dailyBurnRate) * daysRemaining;
  final projectedBalance = totalBalance + remainingNet;

  // Build summary
  String fmt(num v) => v.toInt().abs().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String summary;
  if (projectedIncome > projectedExpense) {
    final surplus = projectedIncome - projectedExpense;
    summary = 'On track to save ${fmt(surplus)} this month';
  } else {
    final deficit = projectedExpense - projectedIncome;
    summary = 'Projected to overspend by ${fmt(deficit)} this month';
  }

  return SpendingForecast(
    projectedExpense: projectedExpense,
    projectedIncome: projectedIncome,
    projectedBalance: projectedBalance,
    dailyBurnRate: dailyBurnRate,
    dailyEarnRate: dailyEarnRate,
    daysRemaining: daysRemaining,
    currentBalance: totalBalance,
    summary: summary,
  );
});
