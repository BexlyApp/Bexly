import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/firebase_messaging_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Widget wrapper to sync FCM token with Firestore when user auth state changes
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
    // Listen to Firebase auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            // User logged in
            final userId = user.uid;
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
        },
        loading: () {
          // Auth state loading
        },
        error: (error, stack) {
          Log.e('Auth state error: $error', label: 'FCM Sync');
        },
      );
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
