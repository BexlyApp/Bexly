part of '../screens/dashboard_screen.dart';

/// Responsive row for Balance, Income, and Expense cards
/// On wide desktop screens (>= 900px), shows all 3 cards in a single row
/// On smaller screens, shows Balance on top, Income/Expense below
class DashboardCardsRow extends StatelessWidget {
  const DashboardCardsRow({super.key});

  // Breakpoint for switching to horizontal layout
  static const double _wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth >= _wideBreakpoint;

        if (isWideLayout) {
          // Wide desktop: all 3 cards in one row
          return const _WideLayout();
        } else {
          // Default: Balance on top, Income/Expense below
          return const _DefaultLayout();
        }
      },
    );
  }
}

/// Wide layout: Balance, Income, Expense in a single row
class _WideLayout extends ConsumerWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIncomeAsync = ref.watch(convertedMonthlyIncomeProvider);
    final currentExpenseAsync = ref.watch(convertedMonthlyExpenseProvider);
    final lastMonthIncomeAsync = ref.watch(convertedLastMonthIncomeProvider);
    final lastMonthExpenseAsync = ref.watch(convertedLastMonthExpenseProvider);

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance card takes more space
                        const Expanded(
                          flex: 2,
                          child: BalanceCard(),
                        ),
                        const Gap(AppSpacing.spacing12),
                        // Income card
                        Expanded(
                          flex: 2,
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
                        // Expense card
                        Expanded(
                          flex: 2,
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
                  error: (e, s) => _buildErrorRow(context),
                );
              },
              loading: () => _buildLoadingRow(),
              error: (e, s) => _buildErrorRow(context),
            );
          },
          loading: () => _buildLoadingRow(),
          error: (e, s) => _buildErrorRow(context),
        );
      },
      loading: () => _buildLoadingRow(),
      error: (e, s) => _buildErrorRow(context),
    );
  }

  Widget _buildLoadingRow() {
    return const Row(
      children: [
        Expanded(flex: 2, child: ShimmerTransactionCardPlaceholder()),
        Gap(AppSpacing.spacing12),
        Expanded(flex: 2, child: ShimmerTransactionCardPlaceholder()),
        Gap(AppSpacing.spacing12),
        Expanded(flex: 2, child: ShimmerTransactionCardPlaceholder()),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 2, child: BalanceCard()),
        const Gap(AppSpacing.spacing12),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingIncomeData),
          ),
        ),
        const Gap(AppSpacing.spacing12),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingExpenseData),
          ),
        ),
      ],
    );
  }
}

/// Default layout: Balance on top, CashFlowCards (Income/Expense) below
class _DefaultLayout extends StatelessWidget {
  const _DefaultLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        BalanceCard(),
        Gap(AppSpacing.spacing12),
        CashFlowCards(),
      ],
    );
  }
}
