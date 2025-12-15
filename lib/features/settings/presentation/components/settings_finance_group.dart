part of '../screens/settings_screen.dart';

class SettingsFinanceGroup extends StatelessWidget {
  const SettingsFinanceGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsGroupHolder(
      title: context.l10n.finance,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.wallets,
          icon: HugeIcons.strokeRoundedWallet03,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.manageWallets,
            desktopWidget: WalletsScreen(),
          ),
        ),
        MenuTileButton(
          label: context.l10n.manageCategories,
          icon: HugeIcons.strokeRoundedStructure01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.manageCategories,
            desktopWidget: const CategoryPickerScreen(isManageCategories: true),
          ),
        ),
      ],
    );
  }
}
