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
    // Check Supabase Auth state to determine if user is authenticated
    final supabaseAuthState = ref.watch(supabase_auth.supabaseAuthServiceProvider);
    final isAuthenticated = supabaseAuthState.isAuthenticated;

    return SettingsGroupHolder(
      title: context.l10n.dataManagement,
      settingTiles: [
        // Sync to Cloud button (only show if authenticated)
        if (isAuthenticated)
          MenuTileButton(
            label: 'Sync to Cloud',
            icon: HugeIcons.strokeRoundedCloudUpload,
            onTap: () async {
              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Trigger sync
                final syncService = ref.read(supabase_sync.supabaseSyncServiceProvider);
                await syncService.syncWalletsToCloud();
                await syncService.syncCategoriesToCloud();
                await syncService.syncTransactionsToCloud();
                await syncService.syncBudgetsToCloud();
                await syncService.syncGoalsToCloud();
                await syncService.syncChecklistItemsToCloud();
                await syncService.syncRecurringToCloud();

                if (context.mounted) {
                  context.pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Data synced to cloud successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  context.pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Sync failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
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
                      // IMPORTANT: Clear guest mode flag FIRST before signing out
                      // Because signOut() will trigger rebuild and splash screen will check this flag
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hasSkippedAuth', false);

                      // Sign out from Supabase (this will trigger rebuild)
                      await ref.read(supabase_auth.supabaseAuthServiceProvider.notifier).signOut();

                      // Clear local user data from database
                      await ref.read(authStateProvider.notifier).logout();

                      // Also sign out from Google/Facebook SDK
                      try {
                        await GoogleSignIn.instance.signOut();
                      } catch (e) {
                        Log.w('Google sign out error: $e', label: 'Settings');
                      }
                      try {
                        await FacebookAuth.instance.logOut();
                      } catch (e) {
                        Log.w('Facebook sign out error: $e', label: 'Settings');
                      }

                      // Navigate to login screen after sign out
                      if (context.mounted) {
                        context.go(Routes.login);
                      }
                    } catch (e) {
                      Log.e('Sign out error: $e', label: 'Settings');
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
