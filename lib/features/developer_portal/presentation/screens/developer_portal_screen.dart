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
import 'package:bexly/core/database/migrations/category_migration_helper.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart' as supabase_auth;
import 'package:bexly/core/services/sync/supabase_sync_provider.dart' as supabase_sync;
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/database/migrations/migrate_existing_goals_to_cloud.dart';

class DeveloperPortalScreen extends HookConsumerWidget {
  const DeveloperPortalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final supabaseAuthState = ref.watch(supabase_auth.supabaseAuthServiceProvider);
    final isAuthenticated = supabaseAuthState.isAuthenticated;

    return CustomScaffold(
      context: context,
      title: 'Developer & Data Tools',
      showBalance: false,
      body: isLoading.value
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.spacing20),
              child: Column(
                spacing: AppSpacing.spacing16,
                children: [
                  Text(
                    '⚠️ Advanced tools - Use with caution!',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
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
                    label: 'Run Category Migration (Modified Hybrid Sync)',
                    icon: HugeIcons.strokeRoundedArrowDataTransferHorizontal as dynamic,
                    onTap: () async {
                      context.openBottomSheet(
                        isScrollControlled: false,
                        child: AlertBottomSheet(
                          title: 'Run Category Migration',
                          content: Text(
                            'This will convert existing categories to Modified Hybrid Sync:\n\n'
                            '• Add source, built_in_id, has_been_modified, is_deleted fields\n'
                            '• Mark existing categories as built-in\n'
                            '• Generate stable IDs\n\n'
                            'This is safe and can be run multiple times.',
                            style: AppTextStyles.body2,
                          ),
                          onConfirm: () async {
                            isLoading.value = true;
                            context.pop();

                            try {
                              final db = ref.read(databaseProvider);
                              final migrationHelper = CategoryMigrationHelper(db);

                              // Run migration
                              final result = await migrationHelper.runMigration();

                              // Verify migration
                              final verification = await migrationHelper.verifyMigration();

                              isLoading.value = false;

                              // Show results
                              if (context.mounted) {
                                final message = result.isSuccess
                                    ? '✅ Migration completed!\n\n'
                                      'Total: ${result.totalCategories}\n'
                                      'Updated: ${result.updated}\n'
                                      'Skipped: ${result.skipped}\n'
                                      'Errors: ${result.errors}\n\n'
                                      '${verification.isComplete ? "✅ Verification passed!" : "⚠️ Verification incomplete"}'
                                    : '❌ Migration failed with ${result.errors} errors';

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            } catch (e) {
                              isLoading.value = false;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('❌ Migration failed: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                  // Sync to Cloud (Supabase)
                  if (isAuthenticated)
                    MenuTileButton(
                      label: 'Force Sync to Cloud (Fixed Order)',
                      icon: HugeIcons.strokeRoundedCloudUpload,
                      onTap: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final syncService = ref.read(supabase_sync.supabaseSyncServiceProvider);

                          // CRITICAL: Sync in dependency order!
                          // 1. Categories FIRST (no dependencies)
                          await syncService.syncCategoriesToCloud();

                          // 2. Wallets SECOND (no dependencies)
                          await syncService.syncWalletsToCloud();

                          // 3. Transactions LAST (depends on wallets and categories)
                          await syncService.syncTransactionsToCloud();

                          if (context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Data synced to cloud successfully!\nCategories → Wallets → Transactions'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.pop();
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
                  // Migrate Existing Data to Cloud
                  if (isAuthenticated)
                    MenuTileButton(
                      label: 'Migrate Data to Cloud (Goals/Budgets)',
                      icon: HugeIcons.strokeRoundedCloudUpload,
                      onTap: () async {
                        context.openBottomSheet(
                          isScrollControlled: false,
                          child: AlertBottomSheet(
                            title: 'Migrate Data to Cloud',
                            content: Text(
                              'This will:\n\n'
                              '• Find all goals/budgets without cloudId\n'
                              '• Generate UUIDs for them\n'
                              '• Upload to Supabase\n'
                              '• Also migrate checklist items\n\n'
                              'Safe to run multiple times.',
                              style: AppTextStyles.body2,
                            ),
                            onConfirm: () async {
                              try {
                                context.pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                final db = ref.read(databaseProvider);
                                final syncService = ref.read(supabase_sync.supabaseSyncServiceProvider);

                                // Run migration
                                await MigrateExistingGoalsToCloud.runMigration(db, syncService);

                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Goals migrated to cloud successfully!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Migration failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  // Force Re-upload Budgets
                  if (isAuthenticated)
                    MenuTileButton(
                      label: 'Force Re-upload Budgets',
                      icon: HugeIcons.strokeRoundedCloudUpload,
                      onTap: () async {
                        context.openBottomSheet(
                          isScrollControlled: false,
                          child: AlertBottomSheet(
                            title: 'Force Re-upload Budgets',
                            content: Text(
                              'This will upload ALL budgets to Supabase,\n'
                              'even if they already have cloudId.\n\n'
                              'Use this if previous upload failed.',
                              style: AppTextStyles.body2,
                            ),
                            onConfirm: () async {
                              try {
                                context.pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                final db = ref.read(databaseProvider);
                                final syncService = ref.read(supabase_sync.supabaseSyncServiceProvider);

                                // Step 1: Run budget migration to ensure budgets have cloudId
                                Log.d('🚀 Running budget migration before upload...');
                                await MigrateExistingGoalsToCloud.migrateBudgets(db, syncService);

                                Log.d('✅ Budget migration complete, budgets now have cloudId');

                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ Budgets migrated and uploaded successfully!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Migration failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  // Force Pull from Cloud (Goals & Budgets)
                  if (isAuthenticated)
                    MenuTileButton(
                      label: 'Force Pull Goals & Budgets from Cloud',
                      icon: HugeIcons.strokeRoundedCloudDownload,
                      onTap: () async {
                        context.openBottomSheet(
                          isScrollControlled: false,
                          child: AlertBottomSheet(
                            title: 'Force Pull from Cloud',
                            content: Text(
                              'This will:\n\n'
                              '• First sync wallets and categories (needed for budgets)\n'
                              '• Pull goals from Supabase\n'
                              '• Pull budgets from Supabase\n\n'
                              'Check logs for details if data doesn\'t appear.',
                              style: AppTextStyles.body2,
                            ),
                            onConfirm: () async {
                              try {
                                context.pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                final syncService = ref.read(supabase_sync.supabaseSyncServiceProvider);

                                Log.i('🔄 Starting force pull from cloud...');

                                // Step 1: Pull wallets and categories first (needed for budgets)
                                Log.i('📦 Pulling wallets from cloud...');
                                await syncService.pullWalletsFromCloud();

                                Log.i('📦 Pulling categories from cloud...');
                                await syncService.pullCategoriesFromCloud();

                                // Step 2: Pull goals (no dependencies)
                                Log.i('🎯 Pulling goals from cloud...');
                                await syncService.pullGoalsFromCloud();

                                // Step 3: Pull budgets (depends on wallets and categories)
                                Log.i('💰 Pulling budgets from cloud...');
                                await syncService.pullBudgetsFromCloud();

                                Log.i('✅ Force pull completed!');

                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Goals & Budgets pulled from cloud!\nCheck logs for details.'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } catch (e) {
                                Log.e('❌ Force pull failed: $e');
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Pull failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  // Debug CloudIds (check sync status)
                  if (isAuthenticated)
                    MenuTileButton(
                      label: 'Debug: Check CloudIds Status',
                      icon: HugeIcons.strokeRoundedBug01,
                      onTap: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final db = ref.read(databaseProvider);

                          // Check wallets
                          final wallets = await db.walletDao.getAllWallets();
                          final walletsWithCloudId = wallets.where((w) => w.cloudId != null).length;

                          // Check categories
                          final categories = await db.categoryDao.getAllCategories();
                          final categoriesWithCloudId = categories.where((c) => c.cloudId != null).length;

                          // Check budgets
                          final budgets = await db.budgetDao.getAllBudgets();
                          final budgetsWithCloudId = budgets.where((b) => b.cloudId != null).length;

                          // Check goals
                          final goals = await db.goalDao.getAllGoals();
                          final goalsWithCloudId = goals.where((g) => g.cloudId != null).length;

                          Log.i('📊 CloudId Status:', label: 'Debug');
                          Log.i('  Wallets: $walletsWithCloudId/${wallets.length} have cloudId', label: 'Debug');
                          Log.i('  Categories: $categoriesWithCloudId/${categories.length} have cloudId', label: 'Debug');
                          Log.i('  Budgets: $budgetsWithCloudId/${budgets.length} have cloudId', label: 'Debug');
                          Log.i('  Goals: $goalsWithCloudId/${goals.length} have cloudId', label: 'Debug');

                          // List wallets without cloudId
                          final walletsWithoutCloudId = wallets.where((w) => w.cloudId == null).toList();
                          if (walletsWithoutCloudId.isNotEmpty) {
                            Log.w('⚠️ Wallets WITHOUT cloudId:', label: 'Debug');
                            for (final w in walletsWithoutCloudId) {
                              Log.w('  - ${w.name} (id: ${w.id})', label: 'Debug');
                            }
                          }

                          if (context.mounted) {
                            context.pop();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('CloudId Status'),
                                content: Text(
                                  'Wallets: $walletsWithCloudId/${wallets.length} have cloudId\n'
                                  'Categories: $categoriesWithCloudId/${categories.length} have cloudId\n'
                                  'Budgets: $budgetsWithCloudId/${budgets.length} have cloudId\n'
                                  'Goals: $goalsWithCloudId/${goals.length} have cloudId\n\n'
                                  '${walletsWithoutCloudId.isNotEmpty ? "⚠️ Some wallets missing cloudId!\nThis can cause budget sync to fail." : "✅ All wallets have cloudId"}\n\n'
                                  'Check console logs for details.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  // Re-populate Categories
                  MenuTileButton(
                    label: context.l10n.repopulateCategories,
                    icon: HugeIcons.strokeRoundedDatabaseRestore,
                    onTap: () async {
                      context.openBottomSheet(
                        isScrollControlled: false,
                        child: AlertBottomSheet(
                          title: context.l10n.repopulateCategories,
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
                              SizedBox(height: AppSpacing.spacing12),
                              Text(
                                context.l10n.repopulateCategoriesTransactions,
                                style: AppTextStyles.body2,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          onConfirm: () async {
                            context.pop();
                            isLoading.value = true;
                            try {
                              final db = ref.read(databaseProvider);
                              await CategoryPopulationService.repopulate(db);
                              isLoading.value = false;
                              if (context.mounted) {
                                toastification.show(
                                  context: context,
                                  title: Text(context.l10n.categoriesRepopulatedSuccess),
                                  description: Text(context.l10n.defaultCategoriesRestored),
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                              }
                            } catch (e) {
                              isLoading.value = false;
                              if (context.mounted) {
                                toastification.show(
                                  context: context,
                                  title: Text(context.l10n.errorRepopulatingCategories),
                                  description: Text(e.toString()),
                                  autoCloseDuration: const Duration(seconds: 5),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                  // Backup & Restore
                  MenuTileButton(
                    label: context.l10n.backupAndRestore,
                    icon: HugeIcons.strokeRoundedDatabaseSync01,
                    onTap: () => context.push(Routes.backupAndRestore),
                  ),
                  // Delete My Data
                  MenuTileButton(
                    label: context.l10n.deleteMyData,
                    icon: HugeIcons.strokeRoundedDelete01,
                    onTap: () => context.push(Routes.accountDeletion),
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

                            final user = ref.read(authProvider).value;
                            final isLoggedIn = user != null && user.email.isNotEmpty;

                            // Cloud delete removed - Supabase handles RLS deletion
                            final resultMessage = isLoggedIn
                                ? 'Local data deleted (Cloud: handled by Supabase RLS)'
                                : 'Local data deleted (Not logged in)';

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
