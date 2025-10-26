import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';
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
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null && _currentUser == null) {
        // User just logged in - start sync
        Log.i('User logged in, starting real-time sync', label: 'sync');
        await _startSync();
      } else if (user == null && _currentUser != null) {
        // User just logged out - stop sync
        Log.i('User logged out, stopping real-time sync', label: 'sync');
        await _stopSync();
      }
      _currentUser = user;
    });

    // Also check current state on init
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUser = currentUser;
      // Start sync after a short delay to let providers initialize
      Future.delayed(const Duration(seconds: 1), () {
        _startSync();
      });
    }
  }

  Future<void> _startSync() async {
    try {
      final syncService = ref.read(realtimeSyncServiceProvider);
      if (!syncService.isSyncing) {
        await syncService.startSync();
        Log.i('Real-time sync started successfully', label: 'sync');
      }
    } catch (e, stack) {
      Log.e('Failed to start sync: $e', label: 'sync');
      Log.e('Stack: $stack', label: 'sync');
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
