part of '../screens/dashboard_screen.dart';

class CashFlowCards extends ConsumerWidget {
  const CashFlowCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use converted providers that handle currency conversion
    final currentIncomeAsync = ref.watch(convertedMonthlyIncomeProvider);
    final currentExpenseAsync = ref.watch(convertedMonthlyExpenseProvider);
    final lastMonthIncomeAsync = ref.watch(convertedLastMonthIncomeProvider);
    final lastMonthExpenseAsync = ref.watch(convertedLastMonthExpenseProvider);

    // Wait for all providers to load
    return currentIncomeAsync.when(
      data: (currentIncome) {
        return currentExpenseAsync.when(
          data: (currentExpense) {
            return lastMonthIncomeAsync.when(
              data: (lastIncome) {
                return lastMonthExpenseAsync.when(
                  data: (lastExpense) {
                    final incomePercentDifference =
                        currentIncome.calculatePercentDifference(lastIncome);
                    final expensePercentDifference =
                        currentExpense.calculatePercentDifference(lastExpense);

                    return Row(
                      children: [
                        Expanded(
                          child: TransactionCard(
                            title: AppLocalizations.of(context)!.income,
                            amount: currentIncome,
                            amountLastMonth: lastIncome,
                            percentDifference: incomePercentDifference,
                            backgroundColor: context.incomeBackground,
                            titleColor: context.incomeForeground,
                            borderColor: context.incomeLine,
                            amountColor: context.incomeText,
                            statsBackgroundColor: context.incomeBackground,
                            statsForegroundColor: context.incomeForeground,
                            statsIconColor: context.incomeText,
                          ),
                        ),
                        const Gap(AppSpacing.spacing12),
                        Expanded(
                          child: TransactionCard(
                            title: AppLocalizations.of(context)!.expense,
                            amount: currentExpense,
                            amountLastMonth: lastExpense,
                            percentDifference: expensePercentDifference,
                            backgroundColor: context.expenseBackground,
                            titleColor: context.expenseForeground,
                            borderColor: context.expenseLine,
                            amountColor: context.expenseText,
                            statsBackgroundColor: context.expenseStatsBackground,
                            statsForegroundColor: context.expenseForeground,
                            statsIconColor: context.expenseText,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => _buildLoadingRow(),
                  error: (error, stack) {
                    debugPrint('❌ [CashFlow] lastMonthExpense error: $error');
                    debugPrint('❌ [CashFlow] Stack: $stack');
                    return _buildErrorRow(context);
                  },
                );
              },
              loading: () => _buildLoadingRow(),
              error: (error, stack) {
                debugPrint('❌ [CashFlow] lastMonthIncome error: $error');
                debugPrint('❌ [CashFlow] Stack: $stack');
                return _buildErrorRow(context);
              },
            );
          },
          loading: () => _buildLoadingRow(),
          error: (error, stack) {
            debugPrint('❌ [CashFlow] currentExpense error: $error');
            debugPrint('❌ [CashFlow] Stack: $stack');
            return _buildErrorRow(context);
          },
        );
      },
      loading: () => _buildLoadingRow(),
      error: (error, stack) {
        debugPrint('❌ [CashFlow] currentIncome error: $error');
        debugPrint('❌ [CashFlow] Stack: $stack');
        return _buildErrorRow(context);
      },
    );
  }

  Widget _buildLoadingRow() {
    return const Row(
      children: [
        Expanded(child: ShimmerTransactionCardPlaceholder()),
        Gap(AppSpacing.spacing12),
        Expanded(child: ShimmerTransactionCardPlaceholder()),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.errorLoadingIncomeData,
            ),
          ),
        ),
        const Gap(AppSpacing.spacing12),
        Expanded(
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.errorLoadingExpenseData,
            ),
          ),
        ),
      ],
    );
  }
}

// Optional: A placeholder for loading state to improve UX
class ShimmerTransactionCardPlaceholder extends StatelessWidget {
  const ShimmerTransactionCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // You can use a shimmer effect package or a simple container
    return Container(
      height: 150, // Adjust to match TransactionCard's approximate height
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
