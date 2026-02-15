import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/selected_month_provider.dart';

/// Provider for dashboard spending grouped by PARENT category
/// Subcategory amounts are rolled up into their parent category
final dashboardCategorySpendingProvider =
    FutureProvider.autoDispose<List<MapEntry<String, double>>>((ref) async {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final selectedWallet = ref.watch(dashboardWalletFilterProvider);
  final db = ref.read(databaseProvider);

  final transactions = transactionsAsync.value ?? [];

  // Filter by wallet if selected
  final filtered = selectedWallet != null
      ? transactions.where((t) => t.wallet.id == selectedWallet.id).toList()
      : transactions;

  // Filter to current month expenses only
  final expenses = filtered.where((t) {
    return t.date.year == selectedMonth.year &&
        t.date.month == selectedMonth.month &&
        t.transactionType == TransactionType.expense;
  }).toList();

  if (expenses.isEmpty) return [];

  // Collect all unique parentIds from subcategories
  final parentIds = expenses
      .where((t) => t.category.parentId != null)
      .map((t) => t.category.parentId!)
      .toSet()
      .toList();

  // Batch fetch parent categories
  Map<int, String> parentNames = {};
  if (parentIds.isNotEmpty) {
    final parents = await db.categoryDao.getCategoriesByIds(parentIds);
    parentNames = {for (var p in parents) p.id: p.title};
  }

  // Group by parent category
  final Map<String, double> categorySpending = {};
  for (var expense in expenses) {
    final category = expense.category;
    String groupName;
    if (category.parentId != null && parentNames.containsKey(category.parentId)) {
      groupName = parentNames[category.parentId]!;
    } else {
      groupName = category.title;
    }

    categorySpending[groupName] =
        (categorySpending[groupName] ?? 0) + expense.amount;
  }

  // Sort descending by amount
  final sorted = categorySpending.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted;
});
