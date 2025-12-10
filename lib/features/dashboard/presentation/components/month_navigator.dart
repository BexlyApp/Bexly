part of '../screens/dashboard_screen.dart';

class MonthNavigator extends ConsumerWidget {
  const MonthNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous month button
        IconButton(
          onPressed: () {
            final previousMonth = DateTime(
              selectedMonth.year,
              selectedMonth.month - 1,
            );
            ref.read(selectedMonthProvider.notifier).state = previousMonth;
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: context.colors.onSurface,
            size: 20,
          ),
          visualDensity: VisualDensity.compact,
        ),

        // Month/Year display with Today button
        GestureDetector(
          onTap: selectedMonth != currentMonth
              ? () {
                  // Jump to current month
                  ref.read(selectedMonthProvider.notifier).state = currentMonth;
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing12,
              vertical: AppSpacing.spacing4,
            ),
            decoration: selectedMonth != currentMonth
                ? BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary600.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                  )
                : null,
            child: Text(
              selectedMonth.toMonthYear(),
              style: AppTextStyles.heading6.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
        ),

        // Next month button (disabled if current month)
        IconButton(
          onPressed: selectedMonth.month == currentMonth.month &&
                  selectedMonth.year == currentMonth.year
              ? null
              : () {
                  final nextMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  );
                  ref.read(selectedMonthProvider.notifier).state = nextMonth;
                },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: selectedMonth.month == currentMonth.month &&
                    selectedMonth.year == currentMonth.year
                ? context.colors.onSurface.withOpacity(0.3)
                : context.colors.onSurface,
            size: 20,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
