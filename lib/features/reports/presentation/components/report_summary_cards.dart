part of '../screens/basic_monthly_report_screen.dart';

class ReportSummaryCards extends ConsumerWidget {
  final DateTime date;

  const ReportSummaryCards({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(monthlyTransactionsProvider(date));

    // Get previous month's transactions for comparison
    final previousMonth = DateTime(date.year, date.month - 1, 1);
    final previousTransactionsAsync = ref.watch(monthlyTransactionsProvider(previousMonth));

    final baseCurrency = ref.watch(baseCurrencyProvider);
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);

    return transactionsAsync.when(
      data: (transactions) {
        return previousTransactionsAsync.when(
          data: (previousTransactions) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _calculateTotalsWithComparison(
                transactions,
                previousTransactions,
                baseCurrency,
                exchangeRateService,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data ?? {
                  'income': 0.0,
                  'expense': 0.0,
                  'net': 0.0,
                  'incomeChange': null,
                  'expenseChange': null,
                  'netChange': null,
                };

                final totalIncome = data['income'] as double;
                final totalExpense = data['expense'] as double;
                final netSavings = data['net'] as double;
                final incomeChange = data['incomeChange'] as double?;
                final expenseChange = data['expenseChange'] as double?;
                final netChange = data['netChange'] as double?;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
                  child: Row(
                    children: [
                      // Total Income
                      Expanded(
                        child: _SummaryCard(
                          title: context.l10n.income,
                          amount: totalIncome,
                          currency: baseCurrency,
                          color: AppColors.green200,
                          icon: HugeIcons.strokeRoundedArrowDown01 as dynamic,
                          percentageChange: incomeChange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),

                      // Total Expense
                      Expanded(
                        child: _SummaryCard(
                          title: context.l10n.expense,
                          amount: totalExpense,
                          currency: baseCurrency,
                          color: AppColors.red700,
                          icon: HugeIcons.strokeRoundedArrowUp01 as dynamic,
                          percentageChange: expenseChange,
                          isExpense: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),

                      // Net Savings
                      Expanded(
                        child: _SummaryCard(
                          title: context.l10n.net,
                          amount: netSavings,
                          currency: baseCurrency,
                          color: netSavings >= 0 ? AppColors.green200 : AppColors.red700,
                          icon: HugeIcons.strokeRoundedWallet03 as dynamic,
                          percentageChange: netChange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 120,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateTotalsWithComparison(
    List<TransactionModel> transactions,
    List<TransactionModel> previousTransactions,
    String baseCurrency,
    ExchangeRateService exchangeRateService,
  ) async {
    // Calculate current month totals
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (var transaction in transactions) {
      double amount = transaction.amount;

      // Convert to base currency if needed
      if (transaction.wallet.currency != baseCurrency) {
        try {
          amount = await exchangeRateService.convertAmount(
            amount: transaction.amount,
            fromCurrency: transaction.wallet.currency,
            toCurrency: baseCurrency,
          );
        } catch (e) {
          Log.e('Failed to convert currency: $e', label: 'ReportSummary');
          // Use original amount if conversion fails
        }
      }

      if (transaction.transactionType == TransactionType.income) {
        totalIncome += amount;
      } else if (transaction.transactionType == TransactionType.expense) {
        totalExpense += amount;
      }
    }

    // Calculate previous month totals
    double prevIncome = 0.0;
    double prevExpense = 0.0;

    for (var transaction in previousTransactions) {
      double amount = transaction.amount;

      if (transaction.wallet.currency != baseCurrency) {
        try {
          amount = await exchangeRateService.convertAmount(
            amount: transaction.amount,
            fromCurrency: transaction.wallet.currency,
            toCurrency: baseCurrency,
          );
        } catch (e) {
          Log.e('Failed to convert currency: $e', label: 'ReportSummary');
        }
      }

      if (transaction.transactionType == TransactionType.income) {
        prevIncome += amount;
      } else if (transaction.transactionType == TransactionType.expense) {
        prevExpense += amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final prevNet = prevIncome - prevExpense;

    // Calculate percentage changes
    double? incomeChange;
    double? expenseChange;
    double? netChange;

    if (prevIncome > 0) {
      incomeChange = ((totalIncome - prevIncome) / prevIncome) * 100;
    }

    if (prevExpense > 0) {
      expenseChange = ((totalExpense - prevExpense) / prevExpense) * 100;
    }

    if (prevNet != 0) {
      netChange = ((netSavings - prevNet) / prevNet.abs()) * 100;
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'net': netSavings,
      'incomeChange': incomeChange,
      'expenseChange': expenseChange,
      'netChange': netChange,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final Color color;
  final dynamic icon; // HugeIcons returns dynamic type in v1.x
  final double? percentageChange;
  final bool isExpense;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
    this.percentageChange,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if change is positive or negative
    // For income/net: positive change = good (green)
    // For expense: negative change = good (green), positive = bad (red)
    Color? percentageColor;
    dynamic percentageIcon; // HugeIcons returns dynamic type in v1.x

    if (percentageChange != null) {
      final isPositiveChange = percentageChange! > 0;

      if (isExpense) {
        // For expenses: decrease is good, increase is bad
        percentageColor = isPositiveChange ? AppColors.red700 : AppColors.green200;
        percentageIcon = isPositiveChange
            ? HugeIcons.strokeRoundedArrowUp01 as dynamic
            : HugeIcons.strokeRoundedArrowDown01 as dynamic;
      } else {
        // For income/net: increase is good, decrease is bad
        percentageColor = isPositiveChange ? AppColors.green200 : AppColors.red700;
        percentageIcon = isPositiveChange
            ? HugeIcons.strokeRoundedArrowUp01 as dynamic
            : HugeIcons.strokeRoundedArrowDown01 as dynamic;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.body5.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              HugeIcon(icon: icon as dynamic, color: color, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            amount.toShortPriceFormat(currencySymbol: currency.currencySymbol, isoCode: currency),
            style: AppTextStyles.body1.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (percentageChange != null) ...[
            const SizedBox(height: AppSpacing.spacing2),
            Row(
              children: [
                HugeIcon(
                  icon: percentageIcon!,
                  color: percentageColor,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${percentageChange!.abs().toStringAsFixed(1)}%',
                  style: AppTextStyles.body5.copyWith(
                    color: percentageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
