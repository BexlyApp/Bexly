import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/reports/data/models/monthly_financial_summary_model.dart';
import 'package:bexly/features/reports/data/models/weekly_financial_summary_model.dart';
import 'package:bexly/features/reports/data/repositories/financial_health_repository.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';

// Provider for 6 months summary
final sixMonthSummaryProvider =
    FutureProvider.autoDispose<List<MonthlyFinancialSummary>>((ref) async {
  final repo = ref.watch(financialHealthRepositoryProvider);
  return repo.getLastMonthsSummary(6);
});

// Provider for weekly summary
final weeklySummaryProvider =
    FutureProvider.autoDispose<List<WeeklyFinancialSummary>>((ref) async {
  final repo = ref.watch(financialHealthRepositoryProvider);
  return repo.getCurrentMonthWeeklySummary();
});

// Repository provider
final financialHealthRepositoryProvider =
    Provider<FinancialHealthRepository>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  return FinancialHealthRepository(
    transactionsAsync.value ?? [],
  );
});
