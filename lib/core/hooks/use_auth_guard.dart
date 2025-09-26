import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/auth_required_dialog.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';

/// Hook to check authentication status and show dialog if needed
/// Returns a function that executes the callback only if authenticated
typedef AuthGuardCallback = Future<void> Function();

AuthGuardCallback useAuthGuard(
  WidgetRef ref,
  BuildContext context, {
  required String featureName,
  required String description,
}) {
  final isGuest = ref.read(isGuestModeProvider);

  return useCallback(() async {
    if (isGuest) {
      final shouldLogin = await AuthRequiredDialog.show(
        context,
        featureName: featureName,
        description: description,
      );

      if (shouldLogin != true) {
        // User cancelled, don't proceed with the action
        return;
      }
    }

    // If authenticated or user chose to login, proceed with the callback
    // The actual callback will be passed as a parameter
  }, [isGuest]);
}

/// Alternative implementation that returns a wrapper function
Future<T?> checkAuthAndExecute<T>({
  required WidgetRef ref,
  required BuildContext context,
  required String featureName,
  required String description,
  required Future<T> Function() callback,
}) async {
  final isGuest = ref.read(isGuestModeProvider);

  if (isGuest) {
    final shouldLogin = await AuthRequiredDialog.show(
      context,
      featureName: featureName,
      description: description,
    );

    if (shouldLogin != true) {
      return null;
    }

    // After login, the user would need to retry the action
    // Return null to indicate the action was not completed
    return null;
  }

  // Execute the callback if authenticated
  return await callback();
}