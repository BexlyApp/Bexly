import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/config/number_format_config.dart';

/// Provider for managing number format preference.
///
/// Options:
/// - 'auto' (default): follow app language locale
/// - 'en_US': comma thousands, dot decimal (1,000.50)
/// - 'vi_VN': dot thousands, comma decimal (1.000,50)
class NumberFormatNotifier extends Notifier<String> {
  static const String _prefsKey = 'number_format';

  @override
  String build() {
    _loadPreference();
    return 'auto';
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = saved;
      NumberFormatConfig.setOverride(saved == 'auto' ? null : saved);
    }
  }

  Future<void> setFormat(String format) async {
    state = format;
    NumberFormatConfig.setOverride(format == 'auto' ? null : format);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, format);
  }

  /// Initialize NumberFormatConfig from saved preference (call on app start).
  static Future<void> initFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved != 'auto') {
      NumberFormatConfig.setOverride(saved);
    }
  }
}

final numberFormatProvider = NotifierProvider<NumberFormatNotifier, String>(
  NumberFormatNotifier.new,
);
