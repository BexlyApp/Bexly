import 'package:intl/intl.dart';
import 'package:bexly/core/config/number_format_config.dart';

extension DoubleFormattingExtensions on double {
  /// Formats the double as a price string with thousand separators.
  ///
  /// Uses the app's locale setting (from [NumberFormatConfig]) by default.
  /// For Vietnamese locale: `100.000,50` (dot thousands, comma decimal)
  /// For English locale: `100,000.50` (comma thousands, dot decimal)
  ///
  /// [decimalDigits] - Number of decimal places to show. If null, auto-detect:
  ///   - 0 decimals if value is integer (e.g., 123.0)
  ///   - 2 decimals otherwise
  /// For currencies like VND, JPY, KRW that don't use decimals, pass decimalDigits: 0
  String toPriceFormat({String? locale, int? decimalDigits}) {
    final effectiveLocale = locale ?? NumberFormatConfig.locale;

    // Handle negative zero (-0.0) and very small values near zero
    // If value rounds to 0 when displayed, show as positive 0
    final value = abs() < 0.005 ? 0.0 : this;

    // If decimalDigits is explicitly provided, use it
    if (decimalDigits != null) {
      if (decimalDigits == 0) {
        // Round to nearest integer and format without decimals
        return NumberFormat("#,##0", effectiveLocale).format(value.round());
      } else {
        // Format with specified decimal places
        return NumberFormat("#,##0.${'0' * decimalDigits}", effectiveLocale).format(value);
      }
    }

    // Auto-detect: check if the double is effectively an integer (e.g., 123.0)
    if (value % 1 == 0) {
      // Format as an integer with thousand separators
      return NumberFormat("#,##0", effectiveLocale).format(value);
    } else {
      // Format with two decimal places and thousand separators
      return NumberFormat("#,##0.00", effectiveLocale).format(value);
    }
  }

  /// Formats the double as a human-readable short price (e.g., 1K, 2.5M)
  /// Uses locale-aware decimal separator from [NumberFormatConfig].
  /// Optionally adds currency symbol with correct positioning based on [isoCode].
  /// For VND/JPY/KRW: "14,8M ₫", others: "$14.8M"
  String toShortPriceFormat({String? currencySymbol, String? isoCode}) {
    final decSep = NumberFormatConfig.decimalSeparator;

    final absValue = abs();
    String suffix = '';
    double divisor = 1;
    if (absValue >= 1e6) {
      suffix = 'M';
      divisor = 1e6;
    } else if (absValue >= 1e3) {
      suffix = 'K';
      divisor = 1e3;
    }
    double shortValue = this / divisor;
    String formatted;
    if (suffix.isEmpty) {
      formatted = toStringAsFixed(
        truncateToDouble() == this ? 0 : 2,
      ).replaceAll('.', decSep);
    } else {
      // Show 2 decimals for M, K, but trim trailing zeros
      formatted = shortValue.toStringAsFixed(2).replaceAll('.', decSep);
      if (formatted.endsWith('${decSep}00')) {
        formatted = formatted.substring(0, formatted.length - 3);
      } else if (formatted.endsWith('0')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    // Add currency symbol if provided
    if (currencySymbol != null && currencySymbol.isNotEmpty) {
      final base = '$formatted$suffix';
      // VND, JPY, KRW: symbol after
      const symbolAfter = ['VND', 'JPY', 'KRW'];
      if (isoCode != null && symbolAfter.contains(isoCode.toUpperCase())) {
        return '$base $currencySymbol';
      }
      return '$currencySymbol$base';
    }
    return '$formatted$suffix';
  }

  /// Calculates the percentage difference between this value (current) and a previous value.
  ///
  /// Returns 0.0 if previousValue is 0 to avoid division by zero.
  ///
  /// Example:
  /// - `current: 110, previous: 100` results in `10.0` (10% increase)
  /// - `current: 90, previous: 100` results in `-10.0` (10% decrease)
  double calculatePercentDifference(double previousValue) {
    if (previousValue == 0) {
      // If previous value was 0, any current value is an "infinite" increase if positive,
      // or 0% change if current is also 0. For simplicity, return 100% if current is > 0, else 0.
      return this > 0 ? 100.0 : 0.0;
    }
    return ((this - previousValue) / previousValue) * 100;
  }
}
