part of '../screens/dashboard_screen.dart';

class SpendingProgressChart extends ConsumerWidget {
  const SpendingProgressChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorySpendingAsync = ref.watch(dashboardCategorySpendingProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    // Define a list of colors for categories
    final List<Color> categoryColors = [
      const Color(0xFF93DBF3), // Light Blue
      const Color(0xFFE27DE5), // Pink/Purple
      const Color(0xFFA0EBA1), // Light Green
      const Color(0xFFEBC58F), // Light Orange/Yellow
      const Color(0xFFADD8E6), // Another Light Blue
      const Color(0xFFF08080), // Light Coral
    ];

    return categorySpendingAsync.when(
      data: (sortedCategories) {
        if (sortedCategories.isEmpty) {
          return Column(
            children: [
              _buildHeader(context, selectedMonth),
              const Gap(AppSpacing.spacing8),
              CustomProgressIndicator(
                value: 0,
                color: context.placeholderBackground,
                radius: BorderRadius.circular(AppRadius.radiusFull),
              ),
            ],
          );
        }

        // Localize category names for display
        final localizedCategories = sortedCategories.map((entry) {
          // Try to find a matching default category name via localization
          // For parent categories, the title is already the parent's title
          return entry;
        }).toList();

        final totalMonthSpending = localizedCategories.fold(
          0.0,
          (sum, entry) => sum + entry.value,
        );

        final topCategories = localizedCategories.take(4).toList();

        return Column(
          children: [
            _buildHeader(context, selectedMonth),
            const Gap(AppSpacing.spacing8),
            if (topCategories.isNotEmpty)
              Row(
                children: topCategories.map((entry) {
                  final categoryTotal = entry.value;
                  final percentage = totalMonthSpending > 0
                      ? categoryTotal / totalMonthSpending
                      : 0.0;
                  final colorIndex =
                      topCategories.indexOf(entry) % categoryColors.length;
                  final color = categoryColors[colorIndex];

                  // Determine radius for first and last items
                  BorderRadius? radius;
                  if (topCategories.first == entry) {
                    radius = const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.radiusFull),
                    );
                  }
                  if (topCategories.last == entry && topCategories.length > 1) {
                    radius =
                        radius?.copyWith(
                          topRight: const Radius.circular(AppRadius.radiusFull),
                          bottomRight: const Radius.circular(
                            AppRadius.radiusFull,
                          ),
                        ) ??
                        const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.radiusFull),
                        );
                  } else if (topCategories.last == entry &&
                      topCategories.length == 1) {
                    radius = BorderRadius.circular(
                      AppRadius.radiusFull,
                    );
                  }

                  return CustomProgressIndicator(
                    value: percentage,
                    color: color,
                    radius: radius,
                  );
                }).toList(),
              )
            else
              Container(),
            const Gap(AppSpacing.spacing8),
            if (topCategories.isNotEmpty)
              Wrap(
                spacing: AppSpacing.spacing8,
                runSpacing: AppSpacing.spacing4,
                alignment: WrapAlignment.start,
                children: topCategories.map((entry) {
                  final categoryName = entry.key;
                  final colorIndex =
                      topCategories.indexOf(entry) % categoryColors.length;
                  final color = categoryColors[colorIndex];
                  return CustomProgressIndicatorLegend(
                    label: categoryName,
                    color: color,
                  );
                }).toList(),
              )
            else
              Container(),
          ],
        );
      },
      loading: () => Column(
        children: [
          _buildHeader(context, selectedMonth),
          const Gap(AppSpacing.spacing8),
          CustomProgressIndicator(
            value: 0,
            color: context.placeholderBackground,
            radius: BorderRadius.circular(AppRadius.radiusFull),
          ),
        ],
      ),
      error: (error, stack) => Center(child: Text(context.l10n.errorLoadingSpendingData)),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime selectedMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.mySpendingThisMonth,
          style: AppTextStyles.body4.copyWith(
            fontVariations: [AppFontWeights.medium],
          ),
        ),
        InkWell(
          onTap: () {
            context.push(Routes.basicMonthlyReports, extra: selectedMonth);
          },
          child: Text(
            context.l10n.viewReport,
            style: AppTextStyles.body5.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
