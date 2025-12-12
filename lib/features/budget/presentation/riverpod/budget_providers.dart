import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

// BudgetDao provider is now imported from database_provider.dart with sync support

// Provider to stream a list of all budgets
final budgetListProvider = StreamProvider.autoDispose<List<BudgetModel>>((ref) {
  final budgetDao = ref.watch(budgetDaoProvider);
  return budgetDao.watchAllBudgets();
});

// Provider to stream details of a single budget by its ID
final budgetDetailsProvider = StreamProvider.autoDispose
    .family<BudgetModel?, int>((ref, budgetId) {
      final budgetDao = ref.watch(budgetDaoProvider);
      return budgetDao.watchBudgetById(budgetId);
    });

// Provider to get the spent amount for a specific budget
// This is a FutureProvider because calculating spent amount involves an async call
final budgetSpentAmountProvider = FutureProvider.autoDispose
    .family<double, BudgetModel>((ref, budget) async {
      final budgetDao = ref.watch(budgetDaoProvider);
      return budgetDao.getSpentAmountForBudget(budget);
    });

// Provider to fetch transactions relevant to a specific budget
final transactionsForBudgetProvider = FutureProvider.autoDispose
    .family<List<TransactionModel>, BudgetModel>((ref, budget) async {
      Log.d(budget.toJson(), label: 'budget');
      final db = ref.watch(databaseProvider);
      final activeWallet = ref.watch(activeWalletProvider).value;
      final categories = await db.categoryDao.getSubCategories(
        budget.category.id!,
      );
      final categoryIds = [...categories.map((c) => c.id), budget.category.id!];

      // Assuming TransactionDao is accessible via db.transactionDao
      // and it has a method to stream or get transactions based on budget criteria.
      // For simplicity, using a future provider here, convert to stream if needed.
      return db.transactionDao.getTransactionsForBudget(
        categoryIds: categoryIds,
        startDate: budget.startDate,
        endDate: budget.endDate,
        walletId: activeWallet!.id ?? 0,
      ); // Convert Future to Stream for StreamProvider
    });

// Provider that defines the list of budget periods (months) to display as tabs
final budgetPeriodListProvider = Provider.autoDispose<List<DateTime>>((ref) {
  final budgetsAsync = ref.watch(budgetListProvider);

  return budgetsAsync.maybeWhen(
    data: (budgets) {
      // Extract unique months from budget start dates
      final uniqueMonthYears = budgets
          .map((b) => DateTime(b.startDate.year, b.startDate.month, 1))
          .toSet()
          .toList();

      // Sort months in descending order (most recent first)
      uniqueMonthYears.sort((a, b) => b.compareTo(a));
      return uniqueMonthYears;
    },
    orElse: () => [],
    // For loading and error states, return an empty list initially.
    // The UI can handle displaying loading/error messages based on budgetListProvider.
  );
});

// Notifier to keep track of the currently selected budget period (month)
class SelectedBudgetPeriodNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    // Default to the start of the current month
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setPeriod(DateTime period) => state = period;
}

final selectedBudgetPeriodProvider = NotifierProvider<SelectedBudgetPeriodNotifier, DateTime>(
  SelectedBudgetPeriodNotifier.new,
);

// Provider that filters the budgetListProvider based on the selectedBudgetPeriodProvider
final filteredBudgetListProvider = StreamProvider.autoDispose
    .family<List<BudgetModel>, DateTime>((ref, period) {
      // Watch the stream of all budgets
      final budgetDao = ref.watch(budgetDaoProvider);
      final allBudgetsStream = budgetDao.watchAllBudgets();

      // Filter the stream
      return allBudgetsStream.map((budgets) {
        // Filtering logic based on the period
        final periodStart = DateTime(period.year, period.month, 1);
        final periodEnd = DateTime(
          period.year,
          period.month + 1,
          0,
        ); // Last day of the month

        return budgets.where((budget) {
          // Check if the budget's date range overlaps with the given period (month)
          return (budget.startDate.isBefore(periodEnd) ||
                  budget.startDate.isAtSameMomentAs(periodEnd)) &&
              (budget.endDate.isAfter(periodStart) ||
                  budget.endDate.isAtSameMomentAs(periodStart));
        }).toList();
      });
    });
