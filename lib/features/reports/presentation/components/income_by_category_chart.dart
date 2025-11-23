part of '../screens/basic_monthly_report_screen.dart';

class IncomeByCategoryChart extends ConsumerWidget {
  final DateTime date;
  const IncomeByCategoryChart({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(monthlyTransactionsProvider(date));

    return transactionsAsync.when(
      data: (transactions) {
        return _IncomeChartWithConversion(
          date: date,
          transactions: transactions,
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => SizedBox(
        height: 200,
        child: Center(child: Text('Error: ${err.toString()}')),
      ),
    );
  }
}

class _IncomeChartWithConversion extends ConsumerWidget {
  final DateTime date;
  final List<TransactionModel> transactions;

  const _IncomeChartWithConversion({
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);

    return FutureBuilder<List<_ChartData>>(
      future: _processIncomeData(
        context,
        transactions,
        baseCurrency,
        exchangeRateService,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final incomeData = snapshot.data ?? [];

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
          height: context.screenSize.height * 0.5,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: context.purpleBackground,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          child: Column(
            spacing: AppSpacing.spacing12,
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
                    DoughnutSeries<_ChartData, String>(
                      dataSource: incomeData,
                      xValueMapper: (_ChartData data, _) => data.category,
                      yValueMapper: (_ChartData data, _) => data.amount,
                      pointColorMapper: (_ChartData data, _) => data.color,
                      dataLabelMapper: (datum, index) =>
                          datum.amount.toShortPriceFormat(
                            currencySymbol: baseCurrency.currencySymbol,
                          ),
                      animationDuration: 500,
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
    );
  }

  Future<List<_ChartData>> _processIncomeData(
    BuildContext context,
    List<TransactionModel> transactions,
    String baseCurrency,
    ExchangeRateService exchangeRateService,
  ) async {
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};

    // Process ONLY income transactions
    for (var transaction in transactions) {
      // Skip expense transactions - this chart is for income only
      if (transaction.transactionType == TransactionType.expense) {
        continue;
      }
      final categoryTitle = transaction.category.title;

      // Convert amount to base currency if needed
      double convertedAmount = transaction.amount;
      if (transaction.wallet.currency != baseCurrency) {
        try {
          convertedAmount = await exchangeRateService.convertAmount(
            amount: transaction.amount,
            fromCurrency: transaction.wallet.currency,
            toCurrency: baseCurrency,
          );
          Log.d(
            'Converted ${transaction.amount} ${transaction.wallet.currency} to $convertedAmount $baseCurrency',
            label: 'IncomeChart',
          );
        } catch (e) {
          Log.e('Failed to convert currency: $e', label: 'IncomeChart');
          // Use original amount if conversion fails
        }
      }

      categoryTotals[categoryTitle] =
          (categoryTotals[categoryTitle] ?? 0) + convertedAmount;

      // Use green shades for income categories
      if (!categoryColors.containsKey(categoryTitle)) {
        categoryColors[categoryTitle] = AppColors.green200;
      }
    }

    // Convert to chart data
    return categoryTotals.entries
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              categoryColors[entry.key]!,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

// _ChartData is already defined in spending_by_category_chart.dart
// and will be shared across both charts via the part file

