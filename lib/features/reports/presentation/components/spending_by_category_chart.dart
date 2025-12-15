part of '../screens/basic_monthly_report_screen.dart';

class SpendingByCategoryChart extends ConsumerWidget {
  final DateTime date;
  const SpendingByCategoryChart({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch transactions filtered by the given month
    final transactionsAsync = ref.watch(monthlyTransactionsProvider(date));

    return transactionsAsync.when(
      data: (transactions) {
        // Use FutureBuilder to handle async currency conversion
        return _ChartWithConversion(
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

/// Inner widget that handles async currency conversion
class _ChartWithConversion extends ConsumerWidget {
  final DateTime date;
  final List<TransactionModel> transactions;

  const _ChartWithConversion({
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);

    return FutureBuilder<List<_ChartData>>(
      future: _processData(
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

        final expenseData = snapshot.data ?? [];

        if (expenseData.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No expense data for this period.',
                style: AppTextStyles.body3,
              ),
            ),
          );
        }

        final totalExpenses = expenseData.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );

        // Use fixed height instead of screenSize percentage for consistent rendering
        // across all platforms (Android, iOS, Web)
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
                    text: 'Spending by Category',
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
                            'Total Spent',
                            style: AppTextStyles.body3.copyWith(
                              color: AppColors.neutral400,
                            ),
                          ),
                          Text(
                            totalExpenses.toShortPriceFormat(
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
                      dataSource: expenseData,
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
                        // Display percentage on slices
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: AppTextStyles.body4,
                      ),
                      innerRadius: '70%', // This creates the donut shape
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

  /// Process transaction data with currency conversion to base currency
  Future<List<_ChartData>> _processData(
    BuildContext context,
    List<TransactionModel> transactions,
    String baseCurrency,
    ExchangeRateService exchangeRateService,
  ) async {
    final Map<String, double> categoryExpenses = {};

    // Convert all amounts to base currency before summing
    // Process ONLY expense transactions (chart is "Spending by Category")
    for (var transaction in transactions) {
      // Skip income transactions - this chart is for expenses only
      if (transaction.transactionType == TransactionType.income) {
        continue;
      }

      final categoryTitle = transaction.category.title;

      // Convert transaction amount to base currency
      double amountInBaseCurrency;
      if (transaction.wallet.currency == baseCurrency) {
        // Same currency, no conversion needed
        amountInBaseCurrency = transaction.amount;
      } else {
        // Different currency, need to convert
        try {
          amountInBaseCurrency = await exchangeRateService.convertAmount(
            amount: transaction.amount,
            fromCurrency: transaction.wallet.currency,
            toCurrency: baseCurrency,
          );
        } catch (e) {
          Log.e(
            'Failed to convert ${transaction.amount} ${transaction.wallet.currency} to $baseCurrency: $e',
            label: 'SpendingChart',
          );
          // Fallback: use original amount if conversion fails
          amountInBaseCurrency = transaction.amount;
        }
      }

      categoryExpenses.update(
        categoryTitle,
        (value) => value + amountInBaseCurrency,
        ifAbsent: () => amountInBaseCurrency,
      );
    }

    // Define color palette for chart segments
    final colorPalette = [
      AppColors.primary600,
      AppColors.secondary600,
      AppColors.tertiary600,
      AppColors.red600,
      AppColors.purple600,
      AppColors.green200,
      AppColors.primary400,
      AppColors.secondary400,
      AppColors.tertiary400,
      AppColors.red400,
      AppColors.purple400,
      AppColors.primary800,
      AppColors.secondary800,
      AppColors.tertiary800,
      AppColors.red800,
      AppColors.purple800,
    ];

    var colorIndex = 0;
    return categoryExpenses.entries
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              colorPalette[colorIndex++ % colorPalette.length],
            ))
        .toList();
  }
}

class _ChartData {
  _ChartData(this.category, this.amount, this.color);
  final String category;
  final double amount;
  final Color color;
}
