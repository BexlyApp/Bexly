part of '../screens/basic_monthly_report_screen.dart';

class IncomeByCategoryChart extends ConsumerWidget {
  final DateTime date;
  const IncomeByCategoryChart({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(incomeByCategoryChartProvider(date));
    final baseCurrency = ref.watch(baseCurrencyProvider);

    return chartDataAsync.when(
      data: (incomeData) {
        if (incomeData.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No income data for this period.',
                style: AppTextStyles.body3,
              ),
            ),
          );
        }

        final totalIncome = incomeData.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );

        return Container(
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: context.purpleBackground,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          child: Column(
            children: [
              Expanded(
                child: SfCircularChart(
                  title: ChartTitle(
                    text: 'Income by Category',
                    textStyle: AppTextStyles.body2,
                  ),
                  legend: const Legend(
                    isVisible: true,
                    overflowMode: LegendItemOverflowMode.wrap,
                    position: LegendPosition.bottom,
                    textStyle: AppTextStyles.body4,
                  ),
                  annotations: <CircularChartAnnotation>[
                    CircularChartAnnotation(
                      widget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Earned',
                            style: AppTextStyles.body3.copyWith(
                              color: AppColors.neutral400,
                            ),
                          ),
                          Text(
                            totalIncome.toShortPriceFormat(
                              currencySymbol: baseCurrency.currencySymbol,
                            ),
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                  ],
                  series: <CircularSeries>[
                    DoughnutSeries<ChartSegmentData, String>(
                      dataSource: incomeData,
                      xValueMapper: (ChartSegmentData data, _) => data.category,
                      yValueMapper: (ChartSegmentData data, _) => data.amount,
                      pointColorMapper: (ChartSegmentData data, _) => data.color,
                      dataLabelMapper: (datum, index) =>
                          datum.amount.toShortPriceFormat(
                            currencySymbol: baseCurrency.currencySymbol,
                          ),
                      animationDuration: 0, // Disable animation to prevent jitter
                      groupMode: CircularChartGroupMode.point,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: AppTextStyles.body4,
                      ),
                      innerRadius: '70%',
                    ),
                  ],
                ),
              ),
              Text(
                'Toggle legend items to show/hide categories.',
                style: AppTextStyles.body4,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => SizedBox(
        height: 200,
        child: Center(child: Text('Error: ${err.toString()}')),
      ),
    );
  }
}
