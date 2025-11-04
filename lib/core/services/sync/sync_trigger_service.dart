import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';
import 'package:bexly/core/services/sync/conflict_resolution_service.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
import 'package:bexly/core/components/dialogs/conflict_resolution_dialog.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/data_population_service/wallet_population_service.dart';

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

      // Check if already synced before AND has local data
      // IMPORTANT: Don't skip sync if local database is empty (e.g., after reinstall)
      final hasSynced = await hasSyncedBefore();
      Log.i('📍 hasSynced check result: $hasSynced', label: 'sync');
      print('📍 hasSynced check result: $hasSynced');

      // Check if local database has any data
      // IMPORTANT: Check transactions, not wallets!
      // App auto-creates default wallet on launch, but no transactions
      final transactions = await localDb.transactionDao.getAllTransactions();
      final hasLocalData = transactions.isNotEmpty;
      Log.i('📍 Local database has data: $hasLocalData (${transactions.length} transactions)', label: 'sync');
      print('📍 Local database has data: $hasLocalData (${transactions.length} transactions)');

      if (hasSynced && hasLocalData) {
        Log.i('User has synced before and has local data, skipping initial sync', label: 'sync');
        print('⏭️ User has synced before and has local data, skipping initial sync');
        return;
      }

      if (hasSynced && !hasLocalData) {
        Log.i('⚠️ User has synced before but local database is empty, forcing sync', label: 'sync');
        print('⚠️ User has synced before but local database is empty, forcing sync');
      }

      Log.i('🚀 First time login detected, checking for conflicts...', label: 'sync');
      print('🚀 First time login detected, checking for conflicts...');

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
      final conflictInfo = await conflictService.detectConflict();
      Log.i('📍 detectConflict() returned: ${conflictInfo != null ? "CONFLICT DETECTED" : "NO CONFLICT"}', label: 'sync');
      print('📍 detectConflict() returned: ${conflictInfo != null ? "CONFLICT DETECTED" : "NO CONFLICT"}');

      if (conflictInfo != null && context.mounted) {
        // Check if this is a real conflict or just first-time login with empty local DB
        final isRealConflict = hasLocalData; // hasLocalData means user has local transactions

        ConflictResolution? resolution;

        if (!isRealConflict) {
          // Local DB empty, cloud has data → Auto download, no dialog needed
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

            // Populate wallets if missing
            if (walletsAfterPull.isEmpty) {
              Log.i('📦 No wallets from cloud, creating default wallet...', label: 'sync');
              print('📦 No wallets from cloud, creating default wallet...');
              final walletDao = ref.read(walletDaoProvider);
              await WalletPopulationService.populateWithDao(walletDao);
              Log.i('✅ Default wallet created', label: 'sync');
              print('✅ Default wallet created');
            } else {
              Log.i('✅ Pulled ${walletsAfterPull.length} wallet(s) from cloud', label: 'sync');
              print('✅ Pulled ${walletsAfterPull.length} wallet(s) from cloud');
            }

            // IMPORTANT: Always populate categories if missing!
            // Categories are NOT synced to cloud - they are hardcoded in the app
            if (categoriesAfterPull.isEmpty) {
              Log.i('📦 No categories found, creating default categories...', label: 'sync');
              print('📦 No categories found, creating default categories...');
              await CategoryPopulationService.populate(localDb);
              Log.i('✅ Default categories created', label: 'sync');
              print('✅ Default categories created');
            } else {
              Log.i('✅ Found ${categoriesAfterPull.length} categories in database', label: 'sync');
              print('✅ Found ${categoriesAfterPull.length} categories in database');
            }
          } catch (e) {
            Log.w('Failed to pull cloud data (might not exist): $e', label: 'sync');
            print('❌ Failed to pull cloud data: $e');

            // If cloud pull failed, ensure we have default data
            final walletsAfterError = await localDb.walletDao.getAllWallets();
            if (walletsAfterError.isEmpty) {
              Log.i('📦 No cloud data and no local wallets, populating defaults...', label: 'sync');
              print('📦 No wallets found, creating default wallet...');
              final walletDao = ref.read(walletDaoProvider);
              await WalletPopulationService.populateWithDao(walletDao);
              Log.i('✅ Default wallet populated after cloud pull failure', label: 'sync');
              print('✅ Default wallet created');
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
}
