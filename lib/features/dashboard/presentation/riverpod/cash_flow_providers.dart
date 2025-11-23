import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/selected_month_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';

/// Provider for converted income amount in selected month
/// Converts all transactions to base currency if "All Wallets" mode
final convertedMonthlyIncomeProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : (transactions ?? []);

  final currentMonth = selectedMonth.month;
  final currentYear = selectedMonth.year;

  double totalIncome = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == currentYear &&
        t.date.month == currentMonth &&
        t.transactionType == TransactionType.income) {
      // Convert to base currency if "All Wallets" mode
      if (selectedWallet == null) {
        if (t.wallet.currency == baseCurrency) {
          totalIncome += t.amount;
        } else {
          try {
            final converted = await exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: baseCurrency,
            );
            totalIncome += converted;
          } catch (e) {
            // Fallback: use original amount
            totalIncome += t.amount;
          }
        }
      } else {
        // Single wallet mode - no conversion needed
        totalIncome += t.amount;
      }
    }
  }

  return totalIncome;
});

/// Provider for converted expense amount in selected month
/// Converts all transactions to base currency if "All Wallets" mode
final convertedMonthlyExpenseProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : (transactions ?? []);

  final currentMonth = selectedMonth.month;
  final currentYear = selectedMonth.year;

  double totalExpense = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == currentYear &&
        t.date.month == currentMonth &&
        t.transactionType == TransactionType.expense) {
      // Convert to base currency if "All Wallets" mode
      if (selectedWallet == null) {
        if (t.wallet.currency == baseCurrency) {
          totalExpense += t.amount;
        } else {
          try {
            final converted = await exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: baseCurrency,
            );
            totalExpense += converted;
          } catch (e) {
            // Fallback: use original amount
            totalExpense += t.amount;
          }
        }
      } else {
        // Single wallet mode - no conversion needed
        totalExpense += t.amount;
      }
    }
  }

  return totalExpense;
});

/// Provider for last month's converted income
final convertedLastMonthIncomeProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : (transactions ?? []);

  final lastMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);
  final lastMonth = lastMonthDate.month;
  final lastMonthYear = lastMonthDate.year;

  double totalIncome = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == lastMonthYear &&
        t.date.month == lastMonth &&
        t.transactionType == TransactionType.income) {
      // Convert to base currency if "All Wallets" mode
      if (selectedWallet == null) {
        if (t.wallet.currency == baseCurrency) {
          totalIncome += t.amount;
        } else {
          try {
            final converted = await exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: baseCurrency,
            );
            totalIncome += converted;
          } catch (e) {
            totalIncome += t.amount;
          }
        }
      } else {
        totalIncome += t.amount;
      }
    }
  }

  return totalIncome;
});

/// Provider for last month's converted expense
final convertedLastMonthExpenseProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  // Filter by wallet if selected
  final filteredTransactions = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : (transactions ?? []);

  final lastMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);
  final lastMonth = lastMonthDate.month;
  final lastMonthYear = lastMonthDate.year;

  double totalExpense = 0;

  for (var t in filteredTransactions) {
    if (t.date.year == lastMonthYear &&
        t.date.month == lastMonth &&
        t.transactionType == TransactionType.expense) {
      // Convert to base currency if "All Wallets" mode
      if (selectedWallet == null) {
        if (t.wallet.currency == baseCurrency) {
          totalExpense += t.amount;
        } else {
          try {
            final converted = await exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: baseCurrency,
            );
            totalExpense += converted;
          } catch (e) {
            totalExpense += t.amount;
          }
        }
      } else {
        totalExpense += t.amount;
      }
    }
  }

  return totalExpense;
});
