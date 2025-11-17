import 'package:flutter/material.dart';
import 'package:bexly/core/constants/app_colors.dart';

/// Helper class for consistent field decoration styles across the app
class FieldDecorationHelper {
  FieldDecorationHelper._();

  /// Get background color for a field based on enabled state
  ///
  /// Returns the theme's surfaceContainerHighest when enabled,
  /// or a light gray (neutral50) when disabled to match CustomTextField
  static Color getBackgroundColor(BuildContext context, bool enabled) {
    if (!enabled) {
      // Use light gray to match disabled CustomTextField appearance
      return AppColors.neutral50;
    }

    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainerHighest;
  }

  /// Get border color for a field based on enabled state
  ///
  /// Returns neutral600 for both enabled and disabled states
  /// to maintain visual consistency
  static Color getBorderColor(bool enabled) {
    return AppColors.neutral600;
  }

  /// Get a complete BoxDecoration for a custom field
  ///
  /// Provides consistent decoration for custom selector fields
  /// (wallet type, currency, etc.) that don't use standard TextField
  static BoxDecoration getFieldDecoration(
    BuildContext context, {
    required bool enabled,
    double borderRadius = 8.0,
  }) {
    return BoxDecoration(
      color: getBackgroundColor(context, enabled),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: getBorderColor(enabled),
      ),
    );
  }

  /// Get text opacity for disabled fields
  ///
  /// Returns 1.0 for enabled (no opacity change)
  /// Returns 0.5 for disabled (makes text more subtle)
  ///
  /// Note: Currently set to 1.0 for both to maintain readability
  static double getTextOpacity(bool enabled) {
    return 1.0; // Keep text readable even when disabled
  }
}
