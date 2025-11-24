import 'package:bexly/features/reports/data/models/monthly_financial_summary_model.dart';
import 'package:bexly/features/reports/data/models/weekly_financial_summary_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/exchange_rate_service.dart';

class FinancialHealthRepository {
  final List<TransactionModel> _transactions;
  final ExchangeRateService _exchangeRateService;
  final String _baseCurrency;

  FinancialHealthRepository(
    this._transactions,
    this._exchangeRateService,
    this._baseCurrency,
  );

  /// Fetches the last [monthsCount] months of data and aggregates income/expense.
  Future<List<MonthlyFinancialSummary>> getLastMonthsSummary(
    int monthsCount,
  ) async {
    final now = DateTime.now();
    // Calculate start date (e.g., 6 months ago from the 1st of that month)
    final startDate = DateTime(now.year, now.month - (monthsCount - 1), 1);

    final recentTransactions = _transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();

    // Generate the list of months we want to display (even empty ones)
    final List<MonthlyFinancialSummary> summaryList = [];

    for (int i = 0; i < monthsCount; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);

      // Filter transactions for this specific month
      final transactionsInMonth = recentTransactions.where((t) {
        return t.date.year == monthDate.year && t.date.month == monthDate.month;
      }).toList();

      double income = 0;
      double expense = 0;

      for (var t in transactionsInMonth) {
        // Convert to base currency if needed
        double amount = t.amount;
        if (t.wallet.currency != _baseCurrency) {
          try {
            amount = await _exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: _baseCurrency,
            );
          } catch (e) {
            Log.e('Failed to convert ${t.wallet.currency} to $_baseCurrency: $e',
              label: 'FinancialHealth');
            // Use original amount if conversion fails
          }
        }

        if (t.transactionType == TransactionType.income) {
          income += amount;
        } else if (t.transactionType == TransactionType.expense) {
          expense += amount;
        }
      }

      summaryList.add(
        MonthlyFinancialSummary(
          month: monthDate,
          income: income,
          expense: expense,
        ),
      );
    }

    return summaryList;
  }

  /// Fetches data for the CURRENT month and buckets it into 4 weeks.
  Future<List<WeeklyFinancialSummary>> getCurrentMonthWeeklySummary() async {
    final now = DateTime.now();
    // Filter for current month only
    final currentMonthTransactions = _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    List<WeeklyFinancialSummary> weeklyData = [];

    // Define buckets: Week 1 (1-7), Week 2 (8-14), Week 3 (15-21), Week 4 (22-End)
    for (int i = 1; i <= 4; i++) {
      int startDay = (i - 1) * 7 + 1;
      int endDay = (i == 4) ? 31 : i * 7; // Week 4 catches everything else

      // Calculate actual DateTimes for this range
      final weekStart = DateTime(now.year, now.month, startDay);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      final actualEndDay = endDay > lastDayOfMonth ? lastDayOfMonth : endDay;
      final weekEnd = DateTime(now.year, now.month, actualEndDay);

      final transactionsInWeek = currentMonthTransactions.where((t) {
        return t.date.day >= startDay && t.date.day <= endDay;
      });

      double income = 0;
      double expense = 0;

      for (var t in transactionsInWeek) {
        // Convert to base currency if needed
        double amount = t.amount;
        if (t.wallet.currency != _baseCurrency) {
          try {
            amount = await _exchangeRateService.convertAmount(
              amount: t.amount,
              fromCurrency: t.wallet.currency,
              toCurrency: _baseCurrency,
            );
          } catch (e) {
            Log.e('Failed to convert ${t.wallet.currency} to $_baseCurrency: $e',
              label: 'FinancialHealth');
            // Use original amount if conversion fails
          }
        }

        if (t.transactionType == TransactionType.income) {
          income += amount;
        } else if (t.transactionType == TransactionType.expense) {
          expense += amount;
        }
      }

      weeklyData.add(
        WeeklyFinancialSummary(
          weekNumber: i,
          income: income,
          expense: expense,
          startDate: weekStart,
          endDate: weekEnd,
        ),
      );
    }

    return weeklyData;
  }
}
