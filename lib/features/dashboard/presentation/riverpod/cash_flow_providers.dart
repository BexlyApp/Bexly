import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/selected_month_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';

/// Provider for income amount in selected month
/// Converts all transactions to the target currency (selected wallet or base currency)
final convertedMonthlyIncomeProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  // If stream is loading or has error, return 0
  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return 0.0;
  }

  final transactions = transactionsAsync.value ?? [];
  if (transactions.isEmpty) return 0.0;

  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateCache = ref.read(exchangeRateCacheProvider.notifier);

  // Target currency: selected wallet's currency, or base currency for "All Wallets"
  final targetCurrency = selectedWallet?.currency ?? baseCurrency;

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : transactions;

  final currentMonth = selectedMonth.month;
  final currentYear = selectedMonth.year;

  double totalIncome = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == currentYear &&
        t.date.month == currentMonth &&
        t.transactionType == TransactionType.income) {
      // Convert to target currency if different
      if (t.wallet.currency != targetCurrency) {
        final rate = await exchangeRateCache.getRate(t.wallet.currency, targetCurrency);
        totalIncome += t.amount * rate;
      } else {
        totalIncome += t.amount;
      }
    }
  }

  return totalIncome;
});

/// Provider for expense amount in selected month
/// Converts all transactions to the target currency (selected wallet or base currency)
final convertedMonthlyExpenseProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  // If stream is loading or has error, return 0
  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return 0.0;
  }

  final transactions = transactionsAsync.value ?? [];
  if (transactions.isEmpty) return 0.0;

  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateCache = ref.read(exchangeRateCacheProvider.notifier);

  // Target currency: selected wallet's currency, or base currency for "All Wallets"
  final targetCurrency = selectedWallet?.currency ?? baseCurrency;

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : transactions;

  final currentMonth = selectedMonth.month;
  final currentYear = selectedMonth.year;

  double totalExpense = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == currentYear &&
        t.date.month == currentMonth &&
        t.transactionType == TransactionType.expense) {
      // Convert to target currency if different
      if (t.wallet.currency != targetCurrency) {
        final rate = await exchangeRateCache.getRate(t.wallet.currency, targetCurrency);
        totalExpense += t.amount * rate;
      } else {
        totalExpense += t.amount;
      }
    }
  }

  return totalExpense;
});

/// Provider for last month's income
final convertedLastMonthIncomeProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  // If stream is loading or has error, return 0
  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return 0.0;
  }

  final transactions = transactionsAsync.value ?? [];
  if (transactions.isEmpty) return 0.0;

  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateCache = ref.read(exchangeRateCacheProvider.notifier);

  // Target currency: selected wallet's currency, or base currency for "All Wallets"
  final targetCurrency = selectedWallet?.currency ?? baseCurrency;

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : transactions;

  final lastMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);
  final lastMonth = lastMonthDate.month;
  final lastMonthYear = lastMonthDate.year;

  double totalIncome = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == lastMonthYear &&
        t.date.month == lastMonth &&
        t.transactionType == TransactionType.income) {
      // Convert to target currency if different
      if (t.wallet.currency != targetCurrency) {
        final rate = await exchangeRateCache.getRate(t.wallet.currency, targetCurrency);
        totalIncome += t.amount * rate;
      } else {
        totalIncome += t.amount;
      }
    }
  }

  return totalIncome;
});

/// Provider for last month's expense
final convertedLastMonthExpenseProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  // If stream is loading or has error, return 0
  if (transactionsAsync.isLoading || transactionsAsync.hasError) {
    return 0.0;
  }

  final transactions = transactionsAsync.value ?? [];
  if (transactions.isEmpty) return 0.0;

  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateCache = ref.read(exchangeRateCacheProvider.notifier);

  // Target currency: selected wallet's currency, or base currency for "All Wallets"
  final targetCurrency = selectedWallet?.currency ?? baseCurrency;

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : transactions;

  final lastMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);
  final lastMonth = lastMonthDate.month;
  final lastMonthYear = lastMonthDate.year;

  double totalExpense = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == lastMonthYear &&
        t.date.month == lastMonth &&
        t.transactionType == TransactionType.expense) {
      // Convert to target currency if different
      if (t.wallet.currency != targetCurrency) {
        final rate = await exchangeRateCache.getRate(t.wallet.currency, targetCurrency);
        totalExpense += t.amount * rate;
      } else {
        totalExpense += t.amount;
      }
    }
  }

  return totalExpense;
});
