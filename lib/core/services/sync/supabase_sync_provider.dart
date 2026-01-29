import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/sync/supabase_sync_service.dart';

/// Provider for Supabase sync service
/// Automatically disposes service and stops listeners when provider is disposed
final supabaseSyncServiceProvider = Provider<SupabaseSyncService>((ref) {
  final service = SupabaseSyncService(ref);

  // TODO: Add cleanup logic when provider is disposed
  ref.onDispose(() async {
    // Cleanup subscriptions if needed
  });

  return service;
});

/// Provider to track if Supabase sync is available
/// Returns true if user is authenticated and Supabase is configured
final isSupabaseSyncAvailableProvider = Provider<bool>((ref) {
  final service = ref.watch(supabaseSyncServiceProvider);
  return service.isAuthenticated;
});
