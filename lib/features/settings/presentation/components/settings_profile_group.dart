part of '../screens/settings_screen.dart';

class SettingsProfileGroup extends ConsumerWidget {
  const SettingsProfileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState != null;

    return SettingsGroupHolder(
      title: 'Profile',
      settingTiles: [
        MenuTileButton(
          label: 'Personal Details',
          icon: HugeIcons.strokeRoundedUser,
          onTap: () => context.push(Routes.personalDetails),
        ),
      ],
    );
  }
}
