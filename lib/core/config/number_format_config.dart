import 'package:intl/intl.dart';

/// Static configuration for number formatting across the app.
///
/// Used by extension methods (like `toPriceFormat()`) that cannot access
/// Riverpod providers. The locale is either auto-detected from the app
/// language or manually overridden via Settings > Preferences > Number Format.
class NumberFormatConfig {
  static String? _overrideLocale;

  /// Get the effective locale for number formatting.
  /// Returns the override if set, otherwise falls back to Intl.defaultLocale.
  static String get locale => _overrideLocale ?? Intl.getCurrentLocale();

  /// Thousand separator for the current locale.
  /// ',' for en/ja/ko/zh/th/hi, '.' for vi/fr/de/es/pt/id/ru/ar
  static String get thousandSeparator => _usesCommaSeparator ? ',' : '.';

  /// Decimal separator for the current locale.
  /// '.' for en/ja/ko/zh/th/hi, ',' for vi/fr/de/es/pt/id/ru/ar
  static String get decimalSeparator => _usesCommaSeparator ? '.' : ',';

  /// Whether the current locale uses comma for thousands (US-style).
  static bool get _usesCommaSeparator {
    final loc = locale.toLowerCase();
    // These locales use comma for thousands, dot for decimal
    const commaThousandLocales = ['en', 'ja', 'ko', 'zh', 'th', 'hi'];
    return commaThousandLocales.any((l) => loc.startsWith(l));
  }

  /// Set a manual override locale for number formatting.
  /// Pass null to revert to auto (follow app language).
  static void setOverride(String? locale) {
    _overrideLocale = locale;
  }

  /// Whether the override is currently active.
  static bool get hasOverride => _overrideLocale != null;

  /// Current mode label for display in settings.
  static String get currentMode {
    if (_overrideLocale == null) return 'auto';
    if (_usesCommaSeparator) return 'en_US';
    return 'vi_VN';
  }

  /// Format a sample number for preview in settings UI.
  static String get previewText {
    final format = NumberFormat('#,##0.00', locale);
    return format.format(1234567.89);
  }
}
