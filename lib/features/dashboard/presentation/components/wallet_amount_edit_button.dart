part of '../screens/dashboard_screen.dart';

class WalletAmountEditButton extends ConsumerWidget {
  const WalletAmountEditButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if a specific wallet is selected (not Total mode)
    final dashboardWallet = ref.watch(dashboardWalletFilterProvider);

    // Hide edit button when in Total mode (dashboardWallet is null)
    if (dashboardWallet == null) {
      return const SizedBox.shrink();
    }

    return CustomIconButton(
      context,
      onPressed: () {
        final defaultCurrencies = ref.read(currenciesStaticProvider);

        // Only set currency if currencies list is available
        if (defaultCurrencies.isNotEmpty) {
          final selectedCurrency = defaultCurrencies.firstWhere(
            (currency) => currency.isoCode == dashboardWallet.currency,
            orElse: () => defaultCurrencies.first,
          );
          ref.read(currencyProvider.notifier).state = selectedCurrency;
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => WalletFormBottomSheet(wallet: dashboardWallet),
        );
      },
      icon: HugeIcons.strokeRoundedEdit02,
      themeMode: context.themeMode,
      iconSize: IconSize.small, // Changed from tiny to small for better tap target
    );
  }
}
