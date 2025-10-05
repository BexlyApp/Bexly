part of '../screens/settings_screen.dart';

class SettingsFinanceGroup extends ConsumerWidget {
  const SettingsFinanceGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final currencies = ref.watch(currenciesStaticProvider);
    final currency = currencies.fromIsoCode(baseCurrency);

    return SettingsGroupHolder(
      title: context.l10n.finance,
      settingTiles: [
        MenuTileButton(
          label: 'Base Currency',
          subtitle: Text('${currency?.name ?? baseCurrency} (${currency?.symbol ?? baseCurrency})'),
          icon: HugeIcons.strokeRoundedMoney02,
          onTap: () => context.push(Routes.baseCurrencySetting),
        ),
        MenuTileButton(
          label: context.l10n.wallets,
          icon: HugeIcons.strokeRoundedWallet03,
          onTap: () => context.push(Routes.manageWallets),
        ),
        MenuTileButton(
          label: context.l10n.manageCategories,
          icon: HugeIcons.strokeRoundedStructure01,
          onTap: () => context.push(Routes.manageCategories),
        ),
      ],
    );
  }
}
