import 'package:flutter/widgets.dart';
import 'package:bexly/core/localization/generated/app_localizations.dart';

/// Helper for looking up localized strings in background services that
/// have no BuildContext (e.g., notification schedulers).
///
/// Usage:
///   final l10n = await BackgroundL10n.load(langCode);
///   final title = l10n.notifDailyReminderTitle;
class BackgroundL10n {
  /// Load an AppLocalizations instance for the given language code.
  /// Falls back to English if the language is not supported.
  static Future<AppLocalizations> load(String languageCode) async {
    final locale = Locale(languageCode);
    final delegate = AppLocalizations.delegate;
    if (delegate.isSupported(locale)) {
      return delegate.load(locale);
    }
    return delegate.load(const Locale('en'));
  }
}
