part of '../screens/settings_screen.dart';

class SettingsDataGroup extends ConsumerWidget {
  const SettingsDataGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState != null;

    return SettingsGroupHolder(
      title: context.l10n.dataManagement,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.backupAndRestore,
          icon: HugeIcons.strokeRoundedDatabaseSync01,
          onTap: () {
            context.push(Routes.backupAndRestore);
          },
        ),
        MenuTileButton(
          label: context.l10n.deleteMyData,
          icon: HugeIcons.strokeRoundedDelete01,
          onTap: () => context.push(Routes.accountDeletion),
        ),
        if (isAuthenticated)
          MenuTileButton(
            label: context.l10n.signOut,
            icon: HugeIcons.strokeRoundedLogout01,
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    context.l10n.signOut,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    context.l10n.signOutConfirm,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        context.l10n.cancel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        context.l10n.signOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                try {
                  // Sign out from Firebase (DOS-Me)
                  final dosmeApp = FirebaseInitService.dosmeApp;
                  if (dosmeApp != null) {
                    await FirebaseAuth.instanceFor(app: dosmeApp).signOut();
                  }

                  // Also sign out from Google/Facebook if needed
                  await GoogleSignIn().signOut();
                  await FacebookAuth.instance.logOut();

                  // Navigate to login screen
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${context.l10n.errorSigningOut}: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
      ],
    );
  }
}
