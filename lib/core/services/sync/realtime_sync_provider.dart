import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/sync/realtime_sync_service.dart';

/// Provider for RealtimeSyncService
/// Automatically disposes service and stops listeners when provider is disposed
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = RealtimeSyncService(db: db);

  // Stop sync when provider is disposed
  ref.onDispose(() async {
    await service.stopSync();
  });

  return service;
});

/// Provider to track sync state
/// Returns true if sync is active and initial sync is complete
final isSyncActiveProvider = Provider<bool>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.isSyncing && service.isInitialSyncComplete;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.isAuthenticated;
});
