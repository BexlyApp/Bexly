part of '../screens/settings_screen.dart';

class SettingsDataGroup extends ConsumerWidget {
  const SettingsDataGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check Firebase Auth state to determine if user is authenticated
    final firebaseAuthState = ref.watch(firebase_auth.authStateProvider);
    final isAuthenticated = firebaseAuthState.valueOrNull != null;

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
        // Show Sign Out button if authenticated, or Sign In button if guest mode
        if (isAuthenticated)
          MenuTileButton(
            label: context.l10n.signOut,
            icon: HugeIcons.strokeRoundedLogout01,
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (context) => AlertBottomSheet(
                  title: context.l10n.signOut,
                  content: Text(
                    context.l10n.signOutConfirm,
                    style: AppTextStyles.body2,
                  ),
                  confirmText: context.l10n.signOut,
                  cancelText: context.l10n.cancel,
                  onConfirm: () async {
                    context.pop(); // close bottom sheet

                    try {
                      // Reset sync status on logout
                      await SyncTriggerService.resetSyncStatus();

                      // Clear local user data from database
                      await ref.read(authStateProvider.notifier).logout();

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
                  },
                ),
              );
            },
          )
        else
          // Guest mode - show Sign In button
          MenuTileButton(
            label: 'Sign In',
            icon: HugeIcons.strokeRoundedLogin01,
            onTap: () {
              // Navigate to login screen to link account
              context.go('/login');
            },
          ),
      ],
    );
  }
}
