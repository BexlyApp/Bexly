import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/progress_indicators/progress_bar.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/presentation/components/budget_spent_card.dart';
import 'package:bexly/features/budget/presentation/components/budget_total_card.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

class BudgetSummaryCard extends ConsumerWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);
    final selectedPeriod = ref.watch(selectedBudgetPeriodProvider);
    final activeWallet = ref.watch(activeWalletProvider).valueOrNull;
    final currencySymbol = activeWallet?.currency == 'USD' ? '\$' : 'đ';

    return budgetsAsync.when(
      data: (allBudgets) {
        if (allBudgets.isEmpty) {
          return const SizedBox.shrink();
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

        double totalBudgetAmount = budgets.fold(
          0.0,
          (sum, budget) => sum + budget.amount,
        );
        double totalSpentAmount = 0;

        for (final budget in budgets) {
          final spentAsync = ref.watch(budgetSpentAmountProvider(budget));
          totalSpentAmount += spentAsync.maybeWhen(
            data: (s) => s,
            orElse: () => 0,
          );
        }

        Log.d(totalSpentAmount, label: 'totalSpentAmount');

        final double totalRemainingAmount =
            totalBudgetAmount - totalSpentAmount;
        final double overallProgress =
            totalSpentAmount > 0 && totalBudgetAmount > 0
            ? (totalSpentAmount / totalBudgetAmount).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: context.purpleBackground,
            border: Border.all(color: context.purpleBorderLighter),
            borderRadius: BorderRadius.circular(AppRadius.radius8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Remaining Budgets',
                    style: AppTextStyles.body4,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: AppSpacing.spacing2,
                    children: [
                      Text(
                        currencySymbol,
                        style: AppTextStyles.body3.copyWith(color: context.primaryText),
                      ),
                      Text(
                        totalRemainingAmount.toPriceFormat(),
                        style: AppTextStyles.numericTitle.copyWith(
                          color: context.primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(AppSpacing.spacing8),
              ProgressBar(
                value: overallProgress,
                foreground: AppColors.primary,
                height: 6,
              ),
              const Gap(AppSpacing.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: BudgetTotalCard(totalAmount: totalBudgetAmount, currencySymbol: currencySymbol),
                  ),
                  const Gap(AppSpacing.spacing12),
                  Expanded(
                    child: BudgetSpentCard(spentAmount: totalSpentAmount, currencySymbol: currencySymbol),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Center(child: Text('Error loading budget summary: $err')),
      ),
    );
  }
}
