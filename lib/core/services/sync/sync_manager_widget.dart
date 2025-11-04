import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
import 'package:bexly/core/services/sync/sync_trigger_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Widget that manages sync lifecycle based on authentication state
/// Place this near the root of the widget tree to automatically start/stop sync
class SyncManagerWidget extends ConsumerStatefulWidget {
  final Widget child;

  const SyncManagerWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SyncManagerWidget> createState() => _SyncManagerWidgetState();
}

class _SyncManagerWidgetState extends ConsumerState<SyncManagerWidget> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    // IMPORTANT: Listen to bexly-app auth, not default (dos-me)
    final bexlyAuth = FirebaseAuth.instanceFor(app: FirebaseInitService.bexlyApp);
    bexlyAuth.authStateChanges().listen((User? user) async {
      if (user != null && _currentUser == null) {
        // User just logged in - start sync
        Log.i('User logged in to bexly-app, starting real-time sync', label: 'sync');
        print('🔄 User logged in, starting real-time sync');
        await _startSync();
      } else if (user == null && _currentUser != null) {
        // User just logged out - stop sync
        Log.i('User logged out from bexly-app, stopping real-time sync', label: 'sync');
        print('⏸️ User logged out, stopping real-time sync');
        await _stopSync();
      }
      _currentUser = user;
    });

    // Also check current state on init
    final currentUser = bexlyAuth.currentUser;
    if (currentUser != null) {
      _currentUser = currentUser;
      Log.i('User already logged in on init, starting sync after delay', label: 'sync');
      print('🔄 User already logged in, starting sync after delay');
      // Start sync after a short delay to let providers initialize
      Future.delayed(const Duration(seconds: 1), () {
        _startSync();
      });
    }
  }

  Future<void> _startSync() async {
    try {
      Log.i('_startSync() called', label: 'sync');
      print('🔧 _startSync() called');

      // CRITICAL: Don't start realtime sync until initial sync completes
      // Otherwise realtime listener will create duplicate wallets during initial sync
      final hasSynced = await SyncTriggerService.hasSyncedBefore();
      final syncService = ref.read(realtimeSyncServiceProvider);

      Log.i('Got sync service, isSyncing: ${syncService.isSyncing}, isAuth: ${syncService.isAuthenticated}, hasSynced: $hasSynced', label: 'sync');
      print('🔧 Sync service state - isSyncing: ${syncService.isSyncing}, isAuth: ${syncService.isAuthenticated}, hasSynced: $hasSynced');

      if (!hasSynced) {
        Log.i('⏳ Initial sync not completed yet, skipping realtime listener setup', label: 'sync');
        print('⏳ Initial sync not completed yet, skipping realtime listener setup');
        return;
      }

      if (!syncService.isSyncing) {
        Log.i('Calling startSync()...', label: 'sync');
        print('🔧 Calling startSync()...');
        await syncService.startSync();
        Log.i('Real-time sync started successfully', label: 'sync');
        print('✅ Real-time sync started successfully');
      } else {
        Log.i('Sync already running, skipping', label: 'sync');
        print('⏭️ Sync already running, skipping');
      }
    } catch (e, stack) {
      Log.e('Failed to start sync: $e', label: 'sync');
      print('❌ Failed to start sync: $e');
      Log.e('Stack: $stack', label: 'sync');
      print('❌ Stack: $stack');
    }
  }

  Future<void> _stopSync() async {
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      if (syncService.isSyncing) {
        await syncService.stopSync();
        Log.i('Real-time sync stopped successfully', label: 'sync');
      }
    } catch (e, stack) {
      Log.e('Failed to stop sync: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Just pass through the child - sync management happens in lifecycle
    return widget.child;
  }
}
