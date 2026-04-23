import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart';
import 'package:bexly/core/services/firebase_messaging_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Widget wrapper to sync FCM token when user auth state changes
class FcmTokenSyncWidget extends ConsumerStatefulWidget {
  final Widget child;

  const FcmTokenSyncWidget({super.key, required this.child});

  @override
  ConsumerState<FcmTokenSyncWidget> createState() => _FcmTokenSyncWidgetState();
}

class _FcmTokenSyncWidgetState extends ConsumerState<FcmTokenSyncWidget> {
  String? _lastSyncedUserId;

  @override
  Widget build(BuildContext context) {
    // Listen to Supabase auth state changes
    ref.listen(supabaseAuthServiceProvider, (previous, next) {
      if (next.isAuthenticated && next.userId != null) {
        // User logged in
        final userId = next.userId!;
        if (_lastSyncedUserId != userId) {
          _syncFcmToken(userId);
          _lastSyncedUserId = userId;
        }
      } else {
        // User logged out
        if (_lastSyncedUserId != null) {
          Log.i('User logged out - FCM token cleared', label: 'FCM Sync');
          _lastSyncedUserId = null;
        }
      }
    });

    return widget.child;
  }

  /// Sync FCM token to Firestore
  Future<void> _syncFcmToken(String userId) async {
    try {
      // Wait a bit for FCM to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (FirebaseMessagingService.isInitialized) {
        await FirebaseMessagingService.saveTokenToFirestore(userId);
        Log.i('FCM token synced for user: $userId', label: 'FCM Sync');
      } else {
        Log.w('FCM not initialized yet, will retry on token refresh', label: 'FCM Sync');
      }
    } catch (e) {
      Log.e('Failed to sync FCM token: $e', label: 'FCM Sync');
    }
  }
}
