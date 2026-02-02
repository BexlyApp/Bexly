import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/reports/data/models/monthly_financial_summary_model.dart';
import 'package:bexly/features/reports/data/models/weekly_financial_summary_model.dart';
import 'package:bexly/features/reports/data/repositories/financial_health_repository.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';

// Provider for 6 months summary
final sixMonthSummaryProvider =
    FutureProvider.autoDispose<List<MonthlyFinancialSummary>>((ref) async {
  final repo = ref.watch(financialHealthRepositoryProvider);
  return repo.getLastMonthsSummary(6);
});

// Provider for weekly summary (current month - legacy)
final weeklySummaryProvider =
    FutureProvider.autoDispose<List<WeeklyFinancialSummary>>((ref) async {
  final repo = ref.watch(financialHealthRepositoryProvider);
  return repo.getWeeklySummaryForMonth(DateTime.now());
});

// Provider for weekly summary with specific month
final weeklySummaryForMonthProvider =
    FutureProvider.autoDispose.family<List<WeeklyFinancialSummary>, DateTime>((ref, date) async {
  final repo = ref.watch(financialHealthRepositoryProvider);
  return repo.getWeeklySummaryForMonth(date);
});

// Repository provider
final financialHealthRepositoryProvider =
    Provider<FinancialHealthRepository>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);

  // Only create repository when data is available
  return FinancialHealthRepository(
    transactionsAsync.whenData((data) => data).value ?? [],
    exchangeRateService,
    baseCurrency,
  );
});
