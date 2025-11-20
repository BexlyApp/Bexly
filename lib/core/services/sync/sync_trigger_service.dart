import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';
import 'package:bexly/core/services/sync/conflict_resolution_service.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
import 'package:bexly/core/components/dialogs/conflict_resolution_dialog.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Service to trigger initial sync when user logs in for the first time
class SyncTriggerService {
  static const String _hasSyncedKey = 'has_synced_to_cloud';

  /// Check if user has synced before
  static Future<bool> hasSyncedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSyncedKey) ?? false;
  }

  /// Mark user as synced
  static Future<void> markAsSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSyncedKey, true);
  }

  /// Reset sync status (for testing or when user logs out)
  static Future<void> resetSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSyncedKey);
  }

  /// Trigger sync if this is the first time user logs in
  /// Handles conflict detection and resolution with user dialog
  /// Also handles guest mode → account binding scenario
  static Future<void> triggerInitialSyncIfNeeded(
    CloudSyncService syncService, {
    required BuildContext context,
    required AppDatabase localDb,
    required String userId,
    required WidgetRef ref,
  }) async {
    try {
      Log.i('📍 triggerInitialSyncIfNeeded START', label: 'sync');
      print('📍 triggerInitialSyncIfNeeded START');

      // Check if user was in guest mode (needs to upload local data)
      final prefs = await SharedPreferences.getInstance();
      final wasGuestMode = prefs.getBool('hasSkippedAuth') ?? false;
      Log.i('📍 wasGuestMode check result: $wasGuestMode', label: 'sync');
      print('📍 wasGuestMode check result: $wasGuestMode');

      // Check if already synced before AND has local data
      // IMPORTANT: Don't skip sync if local database is empty (e.g., after reinstall)
      // IMPORTANT: Don't skip sync if user was in guest mode (need to upload local data)
      final hasSynced = await hasSyncedBefore();
      Log.i('📍 hasSynced check result: $hasSynced', label: 'sync');
      print('📍 hasSynced check result: $hasSynced');

      // Check if local database has any data
      // Check BOTH transactions AND wallets (wallet count > 0 means user created data)
      final transactions = await localDb.transactionDao.getAllTransactions();
      final wallets = await localDb.walletDao.getAllWallets();
      final hasLocalData = transactions.isNotEmpty || wallets.isNotEmpty;
      Log.i('📍 Local database has data: $hasLocalData (${wallets.length} wallets, ${transactions.length} transactions)', label: 'sync');
      print('📍 Local database has data: $hasLocalData (${wallets.length} wallets, ${transactions.length} transactions)');

      // Always run sync to check cloud data, even if user has synced before
      // This handles cases where:
      // 1. User deleted local data but cloud still has data → need to pull
      // 2. User created new data after delete → need to check for conflicts
      // 3. Guest mode binding → need to upload local data

      if (wasGuestMode && hasLocalData) {
        Log.i('🔗 Guest mode → account binding detected, will upload local data', label: 'sync');
        print('🔗 Guest mode → account binding detected, will upload local data');
        // Clear guest mode flag after binding
        await prefs.setBool('hasSkippedAuth', false);
      }

      Log.i('🚀 First time login or guest binding detected, checking for conflicts...', label: 'sync');
      print('🚀 First time login or guest binding detected, checking for conflicts...');

      // Check for conflicts
      // IMPORTANT: Use Bexly Firebase app instance, NOT dos-me!
      final bexlyFirestore = FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly");

      final walletDao = ref.read(walletDaoProvider);
      final conflictService = ConflictResolutionService(
        localDb: localDb,
        firestore: bexlyFirestore,
        userId: userId,
        walletDao: walletDao,
      );

      Log.i('📍 Calling detectConflict()...', label: 'sync');
      print('📍 Calling detectConflict()...');

      dynamic conflictInfo;
      try {
        conflictInfo = await conflictService.detectConflict();
        Log.i('📍 detectConflict() returned: ${conflictInfo != null ? "CONFLICT DETECTED" : "NO CONFLICT"}', label: 'sync');
        print('📍 detectConflict() returned: ${conflictInfo != null ? "CONFLICT DETECTED" : "NO CONFLICT"}');
      } catch (e, stack) {
        Log.e('❌ detectConflict() FAILED: $e', label: 'sync');
        print('❌ detectConflict() FAILED: $e');
        print('Stack: $stack');
        rethrow;
      }

      if (conflictInfo != null && context.mounted) {
        // Check if this is a real conflict or just first-time login with empty local DB
        // IMPORTANT: If user was in guest mode with local data, ALWAYS show dialog!
        final isRealConflict = hasLocalData || wasGuestMode;

        ConflictResolution? resolution;

        if (!isRealConflict) {
          // Local DB empty AND not guest mode, cloud has data → Auto download, no dialog needed
          Log.i('📥 Local database empty, auto-downloading from cloud...', label: 'sync');
          print('📥 Local database empty, auto-downloading from cloud...');
          resolution = ConflictResolution.useCloud;
        } else {
          // Real conflict detected - show resolution dialog
          Log.w('Conflict detected, showing resolution dialog', label: 'sync');
          print('⚠️ Conflict detected, showing resolution dialog');

          resolution = await showModalBottomSheet<ConflictResolution>(
            context: context,
            isDismissible: false,
            enableDrag: false,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => ConflictResolutionDialog(
              conflictInfo: conflictInfo,
            ),
          );

          if (resolution == null) {
            // User cancelled, don't sync
            Log.i('User cancelled conflict resolution', label: 'sync');
            return;
          }
        }

        if (resolution == ConflictResolution.useCloud) {
          // Use cloud data - download and replace local
          Log.i('User chose cloud data, downloading...', label: 'sync');
          print('☁️ User chose cloud data, downloading...');
          await conflictService.useCloudData();

          // IMPORTANT: After downloading cloud data, check if categories exist
          // Categories are NOT synced to cloud - they are hardcoded in the app
          final categoriesAfterPull = await localDb.categoryDao.getAllCategories();
          Log.i('📍 After cloud download: ${categoriesAfterPull.length} categories', label: 'sync');
          print('📍 After cloud download: ${categoriesAfterPull.length} categories');

          if (categoriesAfterPull.isEmpty) {
            Log.i('📦 No categories found, creating default categories...', label: 'sync');
            print('📦 No categories found, creating default categories...');
            await CategoryPopulationService.populate(localDb);
            Log.i('✅ Default categories created', label: 'sync');
            print('✅ Default categories created');
          } else {
            Log.i('✅ Found ${categoriesAfterPull.length} categories in database', label: 'sync');
            print('✅ Found ${categoriesAfterPull.length} categories');
          }

          // IMPORTANT: Set active wallet after downloading from cloud
          final walletsAfterDownload = await localDb.walletDao.getAllWallets();
          if (walletsAfterDownload.isNotEmpty) {
            final activeWalletNotifier = ref.read(activeWalletProvider.notifier);
            final currentActiveWallet = ref.read(activeWalletProvider).valueOrNull;

            if (currentActiveWallet == null) {
              // No active wallet set, auto-select first wallet
              final firstWallet = walletsAfterDownload.first;
              activeWalletNotifier.setActiveWallet(firstWallet.toModel());
              Log.i('✅ Auto-selected first wallet as active: ${firstWallet.name}', label: 'sync');
              print('✅ Auto-selected first wallet as active: ${firstWallet.name}');
            }
          }
        } else {
          // Use local data - upload to cloud
          Log.i('User chose local data, uploading...', label: 'sync');
          print('📤 User chose local data, uploading...');
          await conflictService.useLocalData();
          await syncService.fullSync();
        }
      } else {
        // No conflict detected (auto-resolved or one side empty)
        // Check if we need to pull cloud data
        Log.i('📍 No conflict - checking if local is empty...', label: 'sync');
        print('📍 No conflict - checking if local is empty...');

        final localTransactions = await localDb.transactionDao.getAllTransactions();
        final localWallets = await localDb.walletDao.getAllWallets();

        Log.i('📍 Local data: ${localWallets.length} wallets, ${localTransactions.length} transactions', label: 'sync');
        print('📍 Local data: ${localWallets.length} wallets, ${localTransactions.length} transactions');

        // IMPORTANT: Only check transactions, not wallets!
        // App auto-creates a default wallet on first launch, but no transactions
        // So we should pull cloud data if there are no transactions (even if wallet exists)
        if (localTransactions.isEmpty) {
          // Local has no transactions - might have cloud data to pull
          Log.i('🔄 No transactions locally, pulling cloud data...', label: 'sync');
          print('🔄 No transactions locally, pulling cloud data...');

          try {
            // Try to pull cloud data
            await conflictService.useCloudData();
            Log.i('✅ Successfully pulled cloud data to empty local database', label: 'sync');
            print('✅ Successfully pulled cloud data!');

            // Check if we have wallets and categories after pulling cloud data
            final walletsAfterPull = await localDb.walletDao.getAllWallets();
            final categoriesAfterPull = await localDb.categoryDao.getAllCategories();

            Log.i('📍 After cloud pull: ${walletsAfterPull.length} wallets, ${categoriesAfterPull.length} categories', label: 'sync');
            print('📍 After cloud pull: ${walletsAfterPull.length} wallets, ${categoriesAfterPull.length} categories');

            // Don't auto-create wallet here - let onboarding flow handle it
            // This prevents race condition where sync creates wallet before splash screen checks
            if (walletsAfterPull.isEmpty) {
              Log.i('📦 No wallets from cloud - user will be directed to onboarding', label: 'sync');
              print('📦 No wallets from cloud - onboarding will handle wallet creation');
            } else {
              Log.i('✅ Pulled ${walletsAfterPull.length} wallet(s) from cloud', label: 'sync');
              print('✅ Pulled ${walletsAfterPull.length} wallet(s) from cloud');
            }

            // IMPORTANT: Always populate categories if missing!
            // Categories NEED to be synced to cloud for transaction sync to work
            if (categoriesAfterPull.isEmpty) {
              Log.i('📦 No categories found, creating default categories...', label: 'sync');
              print('📦 No categories found, creating default categories...');
              await CategoryPopulationService.populate(localDb);
              Log.i('✅ Default categories created', label: 'sync');
              print('✅ Default categories created');

              // CRITICAL: Upload all categories to cloud after populating
              // This ensures transactions can reference categoryCloudId
              Log.i('📤 Uploading all categories to cloud...', label: 'sync');
              print('📤 Uploading all categories to cloud...');
              await _uploadAllCategoriesToCloud(localDb, userId);
              Log.i('✅ All categories uploaded to cloud', label: 'sync');
              print('✅ All categories uploaded to cloud');
            } else {
              Log.i('✅ Found ${categoriesAfterPull.length} categories in database', label: 'sync');
              print('✅ Found ${categoriesAfterPull.length} categories in database');

              // Check if categories have cloudId - if not, upload them
              final categoriesWithoutCloudId = categoriesAfterPull.where((c) => c.cloudId == null).toList();
              if (categoriesWithoutCloudId.isNotEmpty) {
                Log.i('📤 Uploading ${categoriesWithoutCloudId.length} categories without cloudId...', label: 'sync');
                print('📤 Uploading ${categoriesWithoutCloudId.length} categories without cloudId...');
                await _uploadAllCategoriesToCloud(localDb, userId);
                Log.i('✅ Categories uploaded to cloud', label: 'sync');
                print('✅ Categories uploaded to cloud');
              }
            }

            // IMPORTANT: Set active wallet after pulling from cloud
            final walletsAfterPull2 = await localDb.walletDao.getAllWallets();
            if (walletsAfterPull2.isNotEmpty) {
              final activeWalletNotifier = ref.read(activeWalletProvider.notifier);
              final currentActiveWallet = ref.read(activeWalletProvider).valueOrNull;

              if (currentActiveWallet == null) {
                // No active wallet set, auto-select first wallet
                final firstWallet = walletsAfterPull2.first;
                activeWalletNotifier.setActiveWallet(firstWallet.toModel());
                Log.i('✅ Auto-selected first wallet as active: ${firstWallet.name}', label: 'sync');
                print('✅ Auto-selected first wallet as active: ${firstWallet.name}');
              }
            }
          } catch (e) {
            Log.w('Failed to pull cloud data (might not exist): $e', label: 'sync');
            print('❌ Failed to pull cloud data: $e');

            // Don't auto-create wallet on error - let onboarding handle it
            // This prevents race condition and ensures consistent user flow
            Log.i('📦 Cloud pull failed - user will be directed to onboarding if no wallet exists', label: 'sync');
            print('📦 Cloud pull failed - onboarding will handle wallet creation if needed');

            // Populate categories if missing
            final categoriesAfterError = await localDb.categoryDao.getAllCategories();
            if (categoriesAfterError.isEmpty) {
              Log.i('📦 No categories, creating default categories...', label: 'sync');
              print('📦 Creating default categories...');
              await CategoryPopulationService.populate(localDb);
              Log.i('✅ Default categories created', label: 'sync');
              print('✅ Default categories created');

              // Upload categories to cloud
              try {
                Log.i('📤 Uploading categories to cloud...', label: 'sync');
                print('📤 Uploading categories to cloud...');
                await _uploadAllCategoriesToCloud(localDb, userId);
                Log.i('✅ Categories uploaded to cloud', label: 'sync');
                print('✅ Categories uploaded to cloud');
              } catch (uploadError) {
                Log.w('Failed to upload categories: $uploadError', label: 'sync');
                print('⚠️ Failed to upload categories (will retry later): $uploadError');
              }
            }
          }
        } else {
          // Local has transactions - data already synced
          Log.i('✅ Local has transactions, skipping initial sync', label: 'sync');
          print('✅ Local has ${localTransactions.length} transactions, skipping sync');
          // Don't call fullSync() here - it will be handled by real-time sync going forward
        }
      }

      // Mark as synced
      await markAsSynced();
      print('📌 Marked as synced');

      Log.i('✅ Initial sync completed and marked', label: 'sync');
      print('✅ Initial sync completed and marked');

      // CRITICAL: Start realtime listener AFTER initial sync completes
      // This prevents duplicate wallet creation during initial sync
      try {
        final realtimeSyncService = ref.read(realtimeSyncServiceProvider);
        if (!realtimeSyncService.isSyncing) {
          Log.i('🔧 Starting realtime listener after initial sync...', label: 'sync');
          print('🔧 Starting realtime listener after initial sync...');
          await realtimeSyncService.startSync();
          Log.i('✅ Realtime listener started successfully', label: 'sync');
          print('✅ Realtime listener started successfully');
        } else {
          Log.i('⏭️ Realtime listener already running', label: 'sync');
          print('⏭️ Realtime listener already running');
        }
      } catch (e) {
        Log.e('❌ Failed to start realtime listener: $e', label: 'sync');
        print('❌ Failed to start realtime listener: $e');
      }
    } catch (e) {
      Log.e('❌ Initial sync failed: $e', label: 'sync');
      print('❌ Initial sync failed: $e');
      // Don't rethrow - sync can fail but app should continue
    }
  }

  /// Upload all categories to cloud (helper method)
  /// This ensures all default categories have cloudId for transaction sync
  static Future<void> _uploadAllCategoriesToCloud(
    AppDatabase localDb,
    String userId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: FirebaseInitService.bexlyApp,
        databaseId: "bexly",
      );
      final categoriesCollection = firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('categories')
          .collection('items');

      // Get all categories from local database
      final allCategories = await localDb.categoryDao.getAllCategories();

      Log.i('📤 Uploading ${allCategories.length} categories to cloud...', label: 'sync');

      int uploaded = 0;
      for (final category in allCategories) {
        try {
          // Generate cloudId if not exists
          final cloudId = category.cloudId ?? const Uuid().v7();

          // Upload to Firestore
          await categoriesCollection.doc(cloudId).set({
            'title': category.title,
            'icon': category.icon,
            'iconBackground': category.iconBackground,
            'iconType': category.iconType,
            'parentId': category.parentId,
            'description': category.description,
            'isSystemDefault': category.isSystemDefault,
            'createdAt': category.createdAt,
            'updatedAt': DateTime.now(),
          });

          // Update local category with cloudId
          if (category.cloudId == null) {
            await (localDb.update(localDb.categories)
                  ..where((c) => c.id.equals(category.id)))
                .write(CategoriesCompanion(cloudId: Value(cloudId)));
          }

          uploaded++;
          if (uploaded % 10 == 0) {
            Log.i('  Progress: $uploaded/${allCategories.length} categories uploaded', label: 'sync');
          }
        } catch (e) {
          Log.e('Failed to upload category ${category.title}: $e', label: 'sync');
        }
      }

      Log.i('✅ Successfully uploaded $uploaded/${allCategories.length} categories', label: 'sync');
    } catch (e, stack) {
      Log.e('Failed to upload categories to cloud: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
      rethrow;
    }
  }
}
