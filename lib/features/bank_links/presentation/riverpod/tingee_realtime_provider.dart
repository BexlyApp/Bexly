import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/bank_links/data/services/tingee_realtime_service.dart';

/// Singleton TingeeRealtimeService scoped to the lifetime of the app.
final tingeeRealtimeServiceProvider = Provider<TingeeRealtimeService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = TingeeRealtimeService(db);
  ref.onDispose(() => service.stop());
  return service;
});

/// Side-effect provider: starts/stops the realtime subscription as the
/// Supabase auth state changes. Watch this once from a top-level widget
/// to keep the listener alive for the session.
final tingeeRealtimeBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(tingeeRealtimeServiceProvider);

  // Kick off whenever auth state shifts.
  final sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null) {
      service.start();
    } else {
      service.stop();
    }
  });
  ref.onDispose(sub.cancel);

  // Also start immediately if the user is already signed in at app boot.
  if (Supabase.instance.client.auth.currentSession != null) {
    service.start();
  }
});
