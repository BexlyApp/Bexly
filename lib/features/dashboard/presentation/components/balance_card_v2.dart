part of '../screens/dashboard_screen.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final selectedWallet = ref.watch(dashboardWalletFilterProvider);
    final totalBalanceAsync = ref.watch(totalBalanceConvertedProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);

    return totalBalanceAsync.when(
      data: (totalBalance) {
        final walletsAsync = ref.watch(allWalletsStreamProvider);
        final wallets = walletsAsync.valueOrNull ?? [];

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
                  const WalletSwitcherDropdown(),
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
                              selectedWallet.balance.toPriceFormat(),
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
                              totalBalance.toPriceFormat(),
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
}
