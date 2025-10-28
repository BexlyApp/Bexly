import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';
import 'package:bexly/core/services/sync/conflict_resolution_service.dart';
import 'package:bexly/core/components/dialogs/conflict_resolution_dialog.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/utils/logger.dart';

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
  }) async {
    try {
      // Check if already synced before
      final hasSynced = await hasSyncedBefore();

      if (hasSynced) {
        Log.i('User has synced before, skipping initial sync', label: 'sync');
        return;
      }

      Log.i('🚀 First time login detected, checking for conflicts...', label: 'sync');

      // Check for conflicts
      final conflictService = ConflictResolutionService(
        localDb: localDb,
        firestore: FirebaseFirestore.instance,
        userId: userId,
      );

      final conflictInfo = await conflictService.detectConflict();

      if (conflictInfo != null && context.mounted) {
        // Show conflict resolution dialog
        Log.w('Conflict detected, showing resolution dialog', label: 'sync');

        final resolution = await showModalBottomSheet<ConflictResolution>(
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

        if (resolution == ConflictResolution.useCloud) {
          // Use cloud data - download and replace local
          Log.i('User chose cloud data, downloading...', label: 'sync');
          await conflictService.useCloudData();
        } else {
          // Use local data - upload to cloud
          Log.i('User chose local data, uploading...', label: 'sync');
          await conflictService.useLocalData();
          await syncService.fullSync();
        }
      } else {
        // No conflict, perform normal sync
        Log.i('No conflict, performing full sync...', label: 'sync');
        await syncService.fullSync();
      }

      // Mark as synced
      await markAsSynced();

      Log.i('✅ Initial sync completed and marked', label: 'sync');
    } catch (e) {
      Log.e('❌ Initial sync failed: $e', label: 'sync');
      // Don't rethrow - sync can fail but app should continue
    }
  }
}
