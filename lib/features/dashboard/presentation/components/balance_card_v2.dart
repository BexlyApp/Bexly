part of '../screens/dashboard_screen.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final selectedWallet = ref.watch(dashboardWalletFilterProvider);
    final totalBalanceAsync = ref.watch(totalBalanceConvertedProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return totalBalanceAsync.when(
      data: (totalBalance) {
        final walletsAsync = ref.watch(allWalletsStreamProvider);
        final wallets = walletsAsync.valueOrNull ?? [];
        final transactions = transactionsAsync.valueOrNull ?? [];

        // Calculate balance change percentage
        double balancePercentChange = 0.0;
        if (selectedWallet == null) {
          // Calculate for total balance
          // Filter transactions by selected month
          final currentMonth = selectedMonth.month;
          final currentYear = selectedMonth.year;

          // Calculate net change this month (income - expense)
          double netChangeThisMonth = 0;
          for (var t in transactions) {
            if (t.date.year == currentYear && t.date.month == currentMonth) {
              if (t.transactionType == TransactionType.income) {
                netChangeThisMonth += t.amount;
              } else if (t.transactionType == TransactionType.expense) {
                netChangeThisMonth -= t.amount;
              }
            }
          }

          // Balance last month = Current balance - Net change this month
          final balanceLastMonth = totalBalance - netChangeThisMonth;
          balancePercentChange = totalBalance.calculatePercentDifference(balanceLastMonth);
        } else {
          // Calculate for individual wallet
          final currentMonth = selectedMonth.month;
          final currentYear = selectedMonth.year;

          // Filter transactions for this wallet
          final walletTransactions = transactions.where((t) => t.wallet.id == selectedWallet.id).toList();

          // Calculate net change this month for this wallet
          double netChangeThisMonth = 0;
          for (var t in walletTransactions) {
            if (t.date.year == currentYear && t.date.month == currentMonth) {
              if (t.transactionType == TransactionType.income) {
                netChangeThisMonth += t.amount;
              } else if (t.transactionType == TransactionType.expense) {
                netChangeThisMonth -= t.amount;
              }
            }
          }

          // Balance last month = Current balance - Net change this month
          final balanceLastMonth = selectedWallet.balance - netChangeThisMonth;
          balancePercentChange = selectedWallet.balance.calculatePercentDifference(balanceLastMonth);
        }

        // If no wallets exist
        if (wallets.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: context.secondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.radius16),
              border: Border.all(color: context.secondaryBorderLighter),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WalletSwitcherDropdown(), // Still show dropdown to create
                const Gap(AppSpacing.spacing8),
                Text(context.l10n.noWalletSelected, style: AppTextStyles.body2),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: context.secondaryBackground,
                borderRadius: BorderRadius.circular(AppRadius.radius16),
                border: Border.all(color: context.secondaryBorderLighter),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.spacing8,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 88), // Space for visibility + edit buttons
                    child: Row(
                      children: [
                        const Flexible(child: WalletSwitcherDropdown()),
                        const Gap(AppSpacing.spacing8),
                        _buildPercentageIndicator(context, balancePercentChange),
                      ],
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final isVisible = ref.watch(
                        walletAmountVisibilityProvider,
                      );

                      if (!isVisible) {
                        return Text(
                          '•••••••••••',
                          style: AppTextStyles.numericHeading.copyWith(
                            height: 1,
                          ),
                        );
                      }

                      // Show wallet-specific balance or total balance
                      if (selectedWallet != null) {
                        // Show individual wallet balance
                        final currency = selectedWallet.currencyByIsoCode(ref);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.spacing2,
                          children: [
                            Text(
                              currency.symbol,
                              style: AppTextStyles.body3,
                            ),
                            Text(
                              selectedWallet.balance.toPriceFormat(
                                decimalDigits: currency.decimalDigits,
                              ),
                              style: AppTextStyles.numericHeading.copyWith(
                                height: 1,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Show total balance in base currency
                        final currencies = ref.read(currenciesStaticProvider);
                        final currency = currencies.fromIsoCode(baseCurrency);
                        final symbol = currency?.symbol ?? baseCurrency;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.spacing2,
                          children: [
                            Text(
                              symbol,
                              style: AppTextStyles.body3,
                            ),
                            Text(
                              totalBalance.toPriceFormat(
                                decimalDigits: currency?.decimalDigits,
                              ),
                              style: AppTextStyles.numericHeading.copyWith(
                                height: 1,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              right: AppSpacing.spacing12,
              top: AppSpacing.spacing12,
              child: Row(
                spacing: AppSpacing.spacing8,
                children: [
                  WalletAmountEditButton(),
                  WalletAmountVisibilityButton(),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Container(
        // Basic loading state
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: context.secondaryBackground,
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          border: Border.all(color: context.secondaryBorderLighter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WalletSwitcherDropdown(), // Show dropdown even when loading
            const Gap(AppSpacing.spacing8),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
      error: (error, stack) => Container(
        // Basic error state
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: context.secondaryBackground,
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          border: Border.all(color: context.secondaryBorderLighter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WalletSwitcherDropdown(),
            const Gap(AppSpacing.spacing8),
            Text(
              context.l10n.errorLoadingBalance,
              style: AppTextStyles.body2.copyWith(color: AppColors.red700),
            ),
          ],
        ),
      ),
    );
  }

  /// Build percentage change indicator similar to Income/Expense cards
  Widget _buildPercentageIndicator(BuildContext context, double percentChange) {
    // Determine color based on whether it's positive or negative
    final isPositive = !percentChange.isNegative;
    final backgroundColor = isPositive
        ? context.incomeBackground
        : context.expenseStatsBackground;
    final foregroundColor = isPositive
        ? context.incomeForeground
        : context.expenseForeground;
    final iconColor = isPositive
        ? context.incomeText
        : context.expenseText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: percentChange.isNegative
                ? HugeIcons.strokeRoundedArrowDown01
                : HugeIcons.strokeRoundedArrowUp01,
            size: 14,
            color: iconColor,
          ),
          const Gap(AppSpacing.spacing2),
          Text(
            '${percentChange.abs().toStringAsFixed(1)}%',
            style: AppTextStyles.body5.copyWith(
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
