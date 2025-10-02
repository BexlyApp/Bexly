part of '../screens/dashboard_screen.dart';

class WalletAmountEditButton extends ConsumerWidget {
  const WalletAmountEditButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomIconButton(
      context,
      onPressed: () {
        final activeWallet = ref.read(activeWalletProvider).valueOrNull;

        if (activeWallet != null) {
          final defaultCurrencies = ref.read(currenciesStaticProvider);

          // Only set currency if currencies list is available
          if (defaultCurrencies.isNotEmpty) {
            final selectedCurrency = defaultCurrencies.firstWhere(
              (currency) => currency.isoCode == activeWallet.currency,
              orElse: () => defaultCurrencies.first,
            );
            ref.read(currencyProvider.notifier).state = selectedCurrency;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => WalletFormBottomSheet(wallet: activeWallet),
          );
        }
      },
      icon: HugeIcons.strokeRoundedEdit02,
      themeMode: context.themeMode,
      iconSize: IconSize.small, // Changed from tiny to small for better tap target
    );
  }
}
