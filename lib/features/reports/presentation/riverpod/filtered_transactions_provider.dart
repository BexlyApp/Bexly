import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/reports/presentation/screens/basic_monthly_report_screen.dart';

/// Provider for monthly transactions with optional wallet filter (for reports)
final monthlyTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, DateTime>((ref, date) {
      final db = ref.watch(databaseProvider);
      final selectedWalletId = ref.watch(reportWalletFilterProvider);

      // Watch ALL transactions from ALL wallets with category & wallet details
      return db.transactionDao.watchAllTransactionsWithDetails().map((transactions) {
        // Filter by month
        var filtered = transactions.where((t) {
          return t.date.year == date.year && t.date.month == date.month;
        });

        // Filter by wallet if selected
        if (selectedWalletId != null) {
          filtered = filtered.where((t) => t.wallet.id == selectedWalletId);
        }

        return filtered.toList();
      });
    });

/// Data class for chart segments
class ChartSegmentData {
  final String category;
  final double amount;
  final Color color;

  const ChartSegmentData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

/// Color palette for chart segments
const _chartColorPalette = [
  AppColors.primary600,
  AppColors.secondary600,
  AppColors.tertiary600,
  AppColors.red600,
  AppColors.purple600,
  AppColors.green200,
  AppColors.primary400,
  AppColors.secondary400,
  AppColors.tertiary400,
  AppColors.red400,
  AppColors.purple400,
  AppColors.primary800,
  AppColors.secondary800,
  AppColors.tertiary800,
  AppColors.red800,
  AppColors.purple800,
];

/// Provider for spending by category chart data (cached, no FutureBuilder jitter)
final spendingByCategoryChartProvider =
    FutureProvider.family.autoDispose<List<ChartSegmentData>, DateTime>((ref, date) async {
      final transactionsAsync = ref.watch(monthlyTransactionsProvider(date));
      final baseCurrency = ref.watch(baseCurrencyProvider);
      final exchangeRateService = ref.watch(exchangeRateServiceProvider);

      final transactions = transactionsAsync.value ?? [];
      final Map<String, double> categoryExpenses = {};

      // Process ONLY expense transactions
      for (var transaction in transactions) {
        if (transaction.transactionType == TransactionType.income) {
          continue;
        }

        final categoryTitle = transaction.category.title;
        double amountInBaseCurrency;

        if (transaction.wallet.currency == baseCurrency) {
          amountInBaseCurrency = transaction.amount;
        } else {
          try {
            amountInBaseCurrency = await exchangeRateService.convertAmount(
              amount: transaction.amount,
              fromCurrency: transaction.wallet.currency,
              toCurrency: baseCurrency,
            );
          } catch (e) {
            Log.e('Failed to convert: $e', label: 'SpendingChart');
            amountInBaseCurrency = transaction.amount;
          }
        }

        categoryExpenses.update(
          categoryTitle,
          (value) => value + amountInBaseCurrency,
          ifAbsent: () => amountInBaseCurrency,
        );
      }

      var colorIndex = 0;
      return categoryExpenses.entries
          .map((entry) => ChartSegmentData(
                category: entry.key,
                amount: entry.value,
                color: _chartColorPalette[colorIndex++ % _chartColorPalette.length],
              ))
          .toList();
    });

/// Provider for income by category chart data (cached, no FutureBuilder jitter)
final incomeByCategoryChartProvider =
    FutureProvider.family.autoDispose<List<ChartSegmentData>, DateTime>((ref, date) async {
      final transactionsAsync = ref.watch(monthlyTransactionsProvider(date));
      final baseCurrency = ref.watch(baseCurrencyProvider);
      final exchangeRateService = ref.watch(exchangeRateServiceProvider);

      final transactions = transactionsAsync.value ?? [];
      final Map<String, double> categoryIncome = {};

      // Process ONLY income transactions
      for (var transaction in transactions) {
        if (transaction.transactionType == TransactionType.expense) {
          continue;
        }

        final categoryTitle = transaction.category.title;
        double amountInBaseCurrency;

        if (transaction.wallet.currency == baseCurrency) {
          amountInBaseCurrency = transaction.amount;
        } else {
          try {
            amountInBaseCurrency = await exchangeRateService.convertAmount(
              amount: transaction.amount,
              fromCurrency: transaction.wallet.currency,
              toCurrency: baseCurrency,
            );
          } catch (e) {
            Log.e('Failed to convert: $e', label: 'IncomeChart');
            amountInBaseCurrency = transaction.amount;
          }
        }

        categoryIncome.update(
          categoryTitle,
          (value) => value + amountInBaseCurrency,
          ifAbsent: () => amountInBaseCurrency,
        );
      }

      var colorIndex = 0;
      final result = categoryIncome.entries
          .map((entry) => ChartSegmentData(
                category: entry.key,
                amount: entry.value,
                color: _chartColorPalette[colorIndex++ % _chartColorPalette.length],
              ))
          .toList();

      // Sort by amount descending
      result.sort((a, b) => b.amount.compareTo(a.amount));
      return result;
    });
