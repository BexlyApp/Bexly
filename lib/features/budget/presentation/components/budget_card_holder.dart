import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/budget/presentation/components/budget_card.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';

class BudgetCardHolder extends ConsumerWidget {
  const BudgetCardHolder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);
    final selectedPeriod = ref.watch(selectedBudgetPeriodProvider);

    return budgetsAsync.when(
      data: (allBudgets) {
        if (allBudgets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing20),
              child: Text(
                'No budgets found. Create one!',
                style: AppTextStyles.body2,
              ),
            ),
          );
        }

        // Filter budgets for the selected period
        final periodStart = DateTime(selectedPeriod.year, selectedPeriod.month, 1);
        final periodEnd = DateTime(selectedPeriod.year, selectedPeriod.month + 1, 0);

        final budgets = allBudgets.where((budget) {
          return (budget.startDate.isBefore(periodEnd) ||
                  budget.startDate.isAtSameMomentAs(periodEnd)) &&
              (budget.endDate.isAfter(periodStart) ||
                  budget.endDate.isAtSameMomentAs(periodStart));
        }).toList();

        if (budgets.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing20,
          ),
          shrinkWrap: true,
          itemBuilder: (context, index) => BudgetCard(budget: budgets[index]),
          separatorBuilder: (context, index) => const Gap(AppSpacing.spacing12),
          itemCount: budgets.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
