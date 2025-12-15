part of '../screens/settings_screen.dart';

class SettingsDataGroup extends ConsumerWidget {
  const SettingsDataGroup({super.key});

  void _showRepopulateCategoriesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => AlertBottomSheet(
        context: context,
        title: context.l10n.repopulateCategories,
        confirmText: context.l10n.repopulate,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.repopulateCategoriesWarning,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.spacing12),
            Text(
              context.l10n.repopulateCategoriesTransactions,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.spacing12),
            Text(
              context.l10n.repopulateCategoriesRecommended,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        onConfirm: () async {
          context.pop(); // close bottom sheet
          await _performRepopulateCategories(ref, context);
        },
      ),
    );
  }

  Future<void> _performRepopulateCategories(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final db = ref.read(databaseProvider);

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: LoadingIndicator()),
        );
      }

      // Use UPSERT to update/insert categories
      // This preserves foreign key relationships with transactions
      await CategoryPopulationService.repopulate(db);

      // Dismiss loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Show success message
      if (context.mounted) {
        toastification.show(
          context: context,
          title: Text(context.l10n.categoriesRepopulatedSuccess),
          description: Text(context.l10n.defaultCategoriesRestored),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e, stack) {
      Log.e('Error re-populating categories: $e', label: 'category');
      Log.e('Stack: $stack', label: 'category');

      // Dismiss loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      if (context.mounted) {
        toastification.show(
          context: context,
          title: Text(context.l10n.errorRepopulatingCategories),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check Firebase Auth state to determine if user is authenticated
    final firebaseAuthState = ref.watch(firebase_auth.authStateProvider);
    final isAuthenticated = firebaseAuthState.value != null;

    return SettingsGroupHolder(
      title: context.l10n.dataManagement,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.backupAndRestore,
          icon: HugeIcons.strokeRoundedDatabaseSync01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.backupAndRestore,
            desktopWidget: const BackupRestoreScreen(),
          ),
        ),
        MenuTileButton(
          label: context.l10n.repopulateCategories,
          icon: HugeIcons.strokeRoundedDatabaseRestore,
          onTap: () => _showRepopulateCategoriesSheet(context, ref),
        ),
        MenuTileButton(
          label: context.l10n.deleteMyData,
          icon: HugeIcons.strokeRoundedDelete01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.accountDeletion,
            desktopWidget: const AccountDeletionScreen(),
          ),
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
                      await GoogleSignIn.instance.signOut();
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
          // Guest mode - show Bind Account button
          MenuTileButton(
            label: context.l10n.bindAccount,
            icon: HugeIcons.strokeRoundedUserAdd01,
            onTap: () {
              // Show bind account bottom sheet with auth options
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (context) => const BindAccountBottomSheet(),
              );
            },
          ),
      ],
    );
  }
}
