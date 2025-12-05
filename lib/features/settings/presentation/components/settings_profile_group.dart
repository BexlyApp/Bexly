part of '../screens/settings_screen.dart';

class SettingsProfileGroup extends ConsumerWidget {
  const SettingsProfileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState != null;

    return SettingsGroupHolder(
      title: context.l10n.profile,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.personalDetails,
          icon: HugeIcons.strokeRoundedUser,
          onTap: () => context.push(Routes.personalDetails),
        ),
        MenuTileButton(
          label: 'Subscription',
          icon: HugeIcons.strokeRoundedCrown,
          onTap: () => context.push(Routes.subscription),
        ),
      ],
    );
  }
}
