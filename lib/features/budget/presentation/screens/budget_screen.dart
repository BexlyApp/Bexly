import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/features/budget/presentation/components/budget_card_holder.dart';
import 'package:bexly/features/budget/presentation/components/budget_summary_card.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';

class BudgetScreen extends HookConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final allBudgetsAsyncValue = ref.watch(budgetListProvider);
    final selectedPeriod = ref.watch(selectedBudgetPeriodProvider);

    return Scaffold(
      body: allBudgetsAsyncValue.when(
        data: (allBudgets) {
          if (allBudgets.isEmpty) {
            return const Center(child: Text('No budgets recorded yet.'));
          }

          // Filter budgets for the selected period
          final periodStart = DateTime(selectedPeriod.year, selectedPeriod.month, 1);
          final periodEnd = DateTime(selectedPeriod.year, selectedPeriod.month + 1, 0);

          final budgetsForPeriod = allBudgets.where((budget) {
            return (budget.startDate.isBefore(periodEnd) ||
                    budget.startDate.isAtSameMomentAs(periodEnd)) &&
                (budget.endDate.isAfter(periodStart) ||
                    budget.endDate.isAtSameMomentAs(periodStart));
          }).toList();

          if (budgetsForPeriod.isEmpty) {
            return const Center(
              child: Text('No budgets for this month.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing20),
            children: const [
              BudgetSummaryCard(),
              Gap(20),
              BudgetCardHolder(),
              Gap(100),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
