import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';

class BudgetFilterDialog extends HookConsumerWidget {
  const BudgetFilterDialog({super.key});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedBudgetPeriodProvider);
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;

    final selectedYear = useState(selectedPeriod.year);
    final selectedMonth = useState(selectedPeriod.month);

    final firstDate = DateTime(2020, 1);
    final lastDate = DateTime(now.year + 1, 12);

    bool isMonthDisabled(int month) {
      final date = DateTime(selectedYear.value, month);
      return date.isBefore(DateTime(firstDate.year, firstDate.month)) ||
          date.isAfter(DateTime(lastDate.year, lastDate.month));
    }

    return CustomBottomSheet(
      title: 'Filter Budgets',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.spacing16,
        children: [
          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
                onPressed: selectedYear.value > firstDate.year
                    ? () => selectedYear.value--
                    : null,
              ),
              DropdownButton<int>(
                value: selectedYear.value,
                underline: const SizedBox(),
                items: List.generate(
                  lastDate.year - firstDate.year + 1,
                  (index) {
                    final year = firstDate.year + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: AppTextStyles.heading6,
                      ),
                    );
                  },
                ),
                onChanged: (year) {
                  if (year != null) {
                    selectedYear.value = year;
                  }
                },
              ),
              IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01),
                onPressed: selectedYear.value < lastDate.year
                    ? () => selectedYear.value++
                    : null,
              ),
            ],
          ),

          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == selectedMonth.value;
              final isDisabled = isMonthDisabled(month);

              return InkWell(
                onTap: isDisabled
                    ? null
                    : () => selectedMonth.value = month,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isDisabled
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: !isSelected && !isDisabled
                        ? Border.all(color: colorScheme.outline.withValues(alpha: 0.3))
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _months[index],
                    style: AppTextStyles.body3.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : isDisabled
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),

          PrimaryButton(
            label: 'Apply',
            onPressed: () {
              ref.read(selectedBudgetPeriodProvider.notifier).state =
                  DateTime(selectedYear.value, selectedMonth.value, 1);
              context.pop();
            },
          ),
          TextButton(
            child: Text(
              'Reset to This Month',
              style: AppTextStyles.body2.copyWith(color: AppColors.red),
            ),
            onPressed: () {
              ref.read(selectedBudgetPeriodProvider.notifier).state =
                  DateTime(now.year, now.month, 1);
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
