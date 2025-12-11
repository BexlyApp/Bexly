import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/menu_tile_button.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/firestore_database.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperPortalScreen extends HookConsumerWidget {
  const DeveloperPortalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    return CustomScaffold(
      context: context,
      title: 'Developer Portal',
      body: isLoading.value
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.spacing20),
              child: Column(
                spacing: AppSpacing.spacing16,
                children: [
                  Text(
                    'Warning! Make sure you are know what you are doing. Use with caution.',
                    style: AppTextStyles.body2.copyWith(color: Colors.orange),
                  ),
                  MenuTileButton(
                    label: 'Reset Categories',
                    icon: HugeIcons.strokeRoundedStructure01 as dynamic,
                    onTap: () async {
                      context.openBottomSheet(
                        isScrollControlled: false,
                        child: AlertBottomSheet(
                          title: 'Reset Categories',
                          content: Text(
                            'Are you sure you want to reset the categories?',
                            style: AppTextStyles.body2,
                          ),
                          onConfirm: () async {
                            isLoading.value = true;
                            context.pop();
                            final db = ref.read(databaseProvider);
                            await db.resetCategories();
                            isLoading.value = false;
                          },
                        ),
                      );
                    },
                  ),
                  MenuTileButton(
                    label: 'Reset Wallets',
                    icon: HugeIcons.strokeRoundedWallet02 as dynamic,
                    onTap: () async {
                      context.openBottomSheet(
                        isScrollControlled: false,
                        child: AlertBottomSheet(
                          title: 'Reset Wallets',
                          content: Text(
                            'Are you sure you want to reset the wallets?',
                            style: AppTextStyles.body2,
                          ),
                          onConfirm: () async {
                            isLoading.value = true;
                            context.pop();
                            final db = ref.read(databaseProvider);
                            await db.resetWallets();
                            isLoading.value = false;
                          },
                        ),
                      );
                    },
                  ),
                  MenuTileButton(
                    label: 'Reset Database',
                    icon: HugeIcons.strokeRoundedDeletePutBack as dynamic,
                    onTap: () {
                      context.openBottomSheet(
                        isScrollControlled: false,
                        child: AlertBottomSheet(
                          title: 'Reset Database',
                          content: Text(
                            'Are you sure you want to reset the database?',
                            style: AppTextStyles.body2,
                          ),
                          onConfirm: () async {
                            isLoading.value = true;
                            context.pop();

                            final user = ref.read(authProvider).valueOrNull;
                            final isLoggedIn = user != null && user.email.isNotEmpty;
                            String resultMessage;

                            // Delete cloud data first (if user is logged in)
                            if (isLoggedIn) {
                              try {
                                final firestoreDb = FirestoreDatabase();
                                await firestoreDb.deleteAllUserData();
                                Log.i('Cloud data deleted successfully', label: 'DevPortal');
                                resultMessage = 'Local + Cloud data deleted';
                              } catch (e) {
                                Log.e('Failed to delete cloud data: $e', label: 'DevPortal');
                                resultMessage = 'Local data deleted (Cloud delete failed: $e)';
                              }
                            } else {
                              resultMessage = 'Local data deleted (Not logged in)';
                            }

                            // Clear SharedPreferences (base_currency, etc.)
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('base_currency');

                            // Then reset local database
                            final db = ref.read(databaseProvider);
                            await db.clearAllDataAndReset();
                            await db.populateData();

                            // Note: base currency will be set when user creates their first wallet

                            isLoading.value = false;

                            // Show result to user
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resultMessage)),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
