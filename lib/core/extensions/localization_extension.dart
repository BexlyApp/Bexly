import 'package:flutter/material.dart';
import 'package:bexly/core/localization/generated/app_localizations.dart';

// Re-export extensions so callers only need to import localization_extension.dart
export 'package:bexly/core/localization/time_ago_l10n.dart';
export 'package:bexly/core/localization/category_name_l10n.dart';

/// Extension for easier access to localization
extension LocalizationExtension on BuildContext {
  /// Shorthand for AppLocalizations.of(context)!
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Safe access with fallback
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}

/// Extension for safe localization with fallbacks
extension SafeLocalization on AppLocalizations? {
  /// Returns the localized string or fallback if null
  String getOrDefault(String Function(AppLocalizations l10n) getter, String fallback) {
    if (this == null) return fallback;
    try {
      return getter(this!);
    } catch (_) {
      return fallback;
    }
  }
}