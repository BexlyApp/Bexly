import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/firestore_database.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/services/keyboard_service/virtual_keyboard_service.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

final accountDeletionLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class AccountDeletionScreen extends HookConsumerWidget {
  const AccountDeletionScreen({super.key});

  Future<void> _showConfirmationSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    KeyboardService.closeKeyboard();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => AlertBottomSheet(
        context: context,
        title: context.l10n.deleteAccount,
        confirmText: context.l10n.delete,
        content: Text(
          'All your data, including goals, transactions, budgets, and personal settings, will be permanently erased. Your account will remain active and you can start fresh.',
          style: AppTextStyles.body2,
        ),
        onConfirm: () {
          context.pop(); // close this dialog
          _performAccountDeletion(ref, context);
        },
      ),
    );
  }

  Future<void> _performAccountDeletion(
    WidgetRef ref,
    BuildContext context,
  ) async {
    ref.read(accountDeletionLoadingProvider.notifier).state = true;
    await Future.delayed(Duration(milliseconds: 1200));

    try {
      final db = ref.read(databaseProvider);

      // STEP 1: Delete cloud data from Firestore (if user is logged in)
      try {
        final firestoreDb = FirestoreDatabase();
        Log.i('Starting cloud data deletion...', label: 'delete account');
        await firestoreDb.deleteAllUserData();
        Log.i('✅ Cloud data deleted from Firestore successfully.', label: 'delete account');
      } catch (e, stackTrace) {
        // User might not be logged in, or network error
        Log.e('❌ Failed to delete cloud data: $e', label: 'delete account');
        Log.e('Stack trace: $stackTrace', label: 'delete account');

        // Dismiss loading dialog
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

        // Show error to user
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.minimal,
            title: const Text('Failed to delete cloud data'),
            description: Text('Error: $e'),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: false,
          );
        }
        return; // Stop execution if cloud deletion fails
      }

      // STEP 2: Logout user
      await ref.read(authStateProvider.notifier).logout();
      Log.i('User logged out.');

      // STEP 3: Clear local database
      await db.clearAllDataAndReset();
      Log.i('Database has been reset successfully.');

      // STEP 4: Populate default categories
      await CategoryPopulationService.populate(db);
      Log.i('Default categories populated.');

      // STEP 5: Clear all SharedPreferences
      await _clearAllSharedPreferences();
      Log.i('SharedPreferences cleared.');

      // STEP 6: Reset and invalidate all providers
      // IMPORTANT: Call reset() before invalidate to clear cached state
      ref.read(activeWalletProvider.notifier).reset();
      ref.invalidate(activeWalletProvider);
      ref.invalidate(allWalletsStreamProvider);
      ref.invalidate(defaultWalletIdProvider);

      // Force rebuild providers by reading them
      // This ensures they query fresh data from the cleared database
      await Future.delayed(const Duration(milliseconds: 100));
      final wallets = await ref.read(allWalletsStreamProvider.future);
      Log.i('All providers reset and refreshed. Current wallets: ${wallets.length}');

      // Dismiss loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Navigate to onboarding screen to recreate initial wallet and user setup
      if (context.mounted) context.go(Routes.onboarding);
      Log.i('Navigated to onboarding screen.');
    } catch (e) {
      Log.e('Error during account deletion', label: 'delete account');
      // Show error message
      if (context.mounted) {
        toastification.show(
          description: Text('Error deleting account: ${e.toString()}'),
        );
      }
    } finally {
      // Ensure loading state is reset.
      // If the widget is disposed (e.g. due to navigation), autoDispose handles the provider.
      // If still mounted (e.g. error occurred), this hides the overlay.
      ref.read(accountDeletionLoadingProvider.notifier).state = false;
    }
  }

  /// Clear all SharedPreferences to reset app state
  Future<void> _clearAllSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear specific keys that should be reset on account deletion
      final keysToRemove = [
        'has_synced_to_cloud',      // Sync status - reset so first sync after re-login is initial sync
        'app_language',             // Language preference
        'themeMode',                // Theme mode
        'language_usage_stats',     // Analytics
        'llm_provider',             // AI config
        'llm_api_key',
        'llm_model',
        'custom_llm_endpoint',
        'claude_api_key',
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      Log.i('Cleared ${keysToRemove.length} SharedPreferences keys');
    } catch (e) {
      Log.e('Error clearing SharedPreferences: $e', label: 'delete account');
      // Don't rethrow - this is not critical
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(accountDeletionLoadingProvider);
    // Assuming UserModel has a 'name' property. Adjust if it's different (e.g., 'username').
    final currentUser = ref.read(authStateProvider);

    final userName = currentUser.name;
    final isChallengeMet = useState(false); // Initialize to false

    return Stack(
      children: [
        CustomScaffold(
          context: context,
          title: context.l10n.deleteAccount,
          showBalance: false,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warning: Account Deletion is Permanent',
                  style: AppTextStyles.body2.copyWith(color: AppColors.red),
                ),
                const Gap(AppSpacing.spacing12),
                Text(
                  'If you decided proceed, all your application data, including financial records, '
                  'goals, and settings, will be permanently erased from this device. '
                  'This action cannot be undone or irreversible. '
                  'The application will be reset to its initial state, '
                  'and you will be logged out.',
                  style: AppTextStyles.body2,
                ),
                const Gap(AppSpacing.spacing16),
                Text(
                  "Type your user name '$userName' to continue:",
                  style: AppTextStyles.body2,
                ),
                const Gap(AppSpacing.spacing8),
                CustomTextField(
                  hint: 'Enter your username',
                  label: 'Challenge Confirmation',
                  onChanged: (value) {
                    isChallengeMet.value = value == userName;
                  },
                ),
                const Spacer(),
                PrimaryButton(
                  label: context.l10n.deleteMyAccount,
                  onPressed: isChallengeMet.value
                      ? () => _showConfirmationSheet(context, ref)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(150), // Semi-transparent overlay
              child: Center(child: LoadingIndicator(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
