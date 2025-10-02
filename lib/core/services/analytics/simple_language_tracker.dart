import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple local language usage tracker without Firebase
class SimpleLanguageTracker {
  static const String _trackingKey = 'language_usage_stats';

  /// Track language usage locally
  static Future<void> trackLanguageUsage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_trackingKey) ?? '{}';
    final Map<String, dynamic> stats = json.decode(statsJson);

    // Update usage count
    final key = 'usage_$languageCode';
    stats[key] = (stats[key] ?? 0) + 1;
    stats['last_used'] = languageCode;
    stats['last_used_time'] = DateTime.now().toIso8601String();

    await prefs.setString(_trackingKey, json.encode(stats));
  }

  /// Get language usage statistics
  static Future<Map<String, dynamic>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_trackingKey) ?? '{}';
    return json.decode(statsJson);
  }

  /// Get most used language
  static Future<String?> getMostUsedLanguage() async {
    final stats = await getUsageStats();
    String? mostUsed;
    int maxCount = 0;

    stats.forEach((key, value) {
      if (key.startsWith('usage_') && value is int && value > maxCount) {
        maxCount = value;
        mostUsed = key.replaceFirst('usage_', '');
      }
    });

    return mostUsed;
  }

  /// Clear all tracking data (for privacy)
  static Future<void> clearTrackingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trackingKey);
  }
}