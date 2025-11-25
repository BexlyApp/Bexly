import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';

class BudgetFilterDialog extends HookConsumerWidget {
  const BudgetFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedBudgetPeriodProvider);
    final now = DateTime.now();
    final monthController = TextEditingController(
      text: selectedPeriod.toMonthYear(),
    );

    return CustomBottomSheet(
      title: 'Lọc ngân sách',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.spacing16,
        children: [
          CustomSelectField(
            context: context,
            controller: monthController,
            label: 'Chọn tháng',
            hint: 'Tháng 11, 2025',
            prefixIcon: HugeIcons.strokeRoundedCalendar01,
            onTap: () async {
              final result = await showCalendarDatePicker2Dialog(
                context: context,
                config: CalendarDatePicker2WithActionButtonsConfig(
                  calendarType: CalendarDatePicker2Type.single,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(now.year + 1, 12, 31),
                  dayTextStyle: AppTextStyles.body4,
                  selectedDayTextStyle: AppTextStyles.body4.copyWith(
                    color: AppColors.light,
                  ),
                  monthTextStyle: AppTextStyles.body4,
                  selectedMonthTextStyle: AppTextStyles.body4.copyWith(
                    color: AppColors.light,
                  ),
                  yearTextStyle: AppTextStyles.body4,
                  selectedYearTextStyle: AppTextStyles.body4.copyWith(
                    color: AppColors.light,
                  ),
                  weekdayLabelTextStyle: AppTextStyles.body4,
                  todayTextStyle: AppTextStyles.body4.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                dialogSize: const Size(325, 400),
                value: [selectedPeriod],
                borderRadius: BorderRadius.circular(15),
              );

              if (result != null && result.isNotEmpty && result.first != null) {
                final selected = result.first!;
                ref.read(selectedBudgetPeriodProvider.notifier).state =
                    DateTime(selected.year, selected.month, 1);
                monthController.text =
                    DateTime(selected.year, selected.month, 1).toMonthYear();
              }
            },
          ),
          PrimaryButton(
            label: 'Áp dụng',
            onPressed: () => context.pop(),
          ),
          TextButton(
            child: Text(
              'Đặt về tháng này',
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
