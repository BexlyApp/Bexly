part of '../screens/settings_screen.dart';

class SettingsProfileGroup extends ConsumerWidget {
  const SettingsProfileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroupHolder(
      title: context.l10n.profile,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.personalDetails,
          icon: HugeIcons.strokeRoundedUser,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.personalDetails,
            desktopWidget: const PersonalDetailsScreen(),
          ),
        ),
        MenuTileButton(
          label: context.l10n.subscription,
          icon: HugeIcons.strokeRoundedCrown,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.subscription,
            desktopWidget: const SubscriptionScreen(),
          ),
        ),
      ],
    );
  }
}
