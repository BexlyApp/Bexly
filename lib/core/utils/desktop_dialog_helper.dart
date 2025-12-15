import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';

/// Helper class for showing screens as dialogs on desktop layout
class DesktopDialogHelper {
  DesktopDialogHelper._();

  /// Shows a widget as a dialog on desktop, or navigates to a route on mobile
  ///
  /// [context] - Build context
  /// [desktopWidget] - Widget to show in dialog on desktop
  /// [mobileRoute] - Route to navigate on mobile (optional)
  /// [mobileRouteExtra] - Extra data to pass to mobile route (optional)
  /// [maxWidth] - Maximum width of dialog (default: 600)
  /// [maxHeight] - Maximum height of dialog (default: 800)
  static void showScreen(
    BuildContext context, {
    required Widget desktopWidget,
    String? mobileRoute,
    Object? mobileRouteExtra,
    double maxWidth = 600,
    double maxHeight = 800,
  }) {
    if (context.isDesktopLayout) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 80,
            vertical: 40,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius16),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: desktopWidget,
            ),
          ),
        ),
      );
    } else if (mobileRoute != null) {
      context.push(mobileRoute, extra: mobileRouteExtra);
    }
  }

  /// Shows a widget as a dialog only (no mobile route fallback)
  /// Useful for screens that should always be dialogs on desktop
  static void showDialogOnly(
    BuildContext context, {
    required Widget child,
    double maxWidth = 600,
    double maxHeight = 800,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 80,
          vertical: 40,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          ),
        ),
      ),
    );
  }
}
