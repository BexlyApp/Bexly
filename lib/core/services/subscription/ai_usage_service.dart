import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/subscription/subscription_tier.dart';
import 'package:bexly/core/services/subscription/subscription_provider.dart';

/// Service to track AI message usage per month
class AiUsageService {
  static const String _keyPrefix = 'ai_messages_';

  final SharedPreferences _prefs;

  AiUsageService(this._prefs);

  /// Get the storage key for current month
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '$_keyPrefix${now.year}_${now.month}';
  }

  /// Get number of AI messages used this month
  int getUsedMessagesThisMonth() {
    return _prefs.getInt(_getCurrentMonthKey()) ?? 0;
  }

  /// Increment AI message count
  Future<void> incrementMessageCount() async {
    final key = _getCurrentMonthKey();
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }

  /// Check if user can send more AI messages
  bool canSendMessage(SubscriptionLimits limits) {
    final used = getUsedMessagesThisMonth();
    final max = limits.maxAiMessagesPerMonth;
    if (max == -1) return true; // Unlimited
    return used < max;
  }

  /// Get remaining messages this month
  int getRemainingMessages(SubscriptionLimits limits) {
    final max = limits.maxAiMessagesPerMonth;
    if (max == -1) return -1; // Unlimited
    final used = getUsedMessagesThisMonth();
    return (max - used).clamp(0, max);
  }

  /// Reset message count (for testing)
  Future<void> resetMessageCount() async {
    await _prefs.remove(_getCurrentMonthKey());
  }

  /// Clean up old month data (optional, call periodically)
  Future<void> cleanupOldData() async {
    final now = DateTime.now();
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));

    for (final key in keys) {
      // Parse year and month from key
      final parts = key.replaceFirst(_keyPrefix, '').split('_');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);

        if (year != null && month != null) {
          // Remove if older than 3 months
          final keyDate = DateTime(year, month);
          final threeMonthsAgo = DateTime(now.year, now.month - 3);
          if (keyDate.isBefore(threeMonthsAgo)) {
            await _prefs.remove(key);
          }
        }
      }
    }
  }
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for AiUsageService
final aiUsageServiceProvider = Provider<AiUsageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiUsageService(prefs);
});

/// Provider for remaining AI messages this month
final remainingAiMessagesProvider = Provider<int>((ref) {
  final service = ref.watch(aiUsageServiceProvider);
  final limits = ref.watch(subscriptionLimitsProvider);
  return service.getRemainingMessages(limits);
});

/// Provider to check if user can send AI message
final canSendAiMessageProvider = Provider<bool>((ref) {
  final service = ref.watch(aiUsageServiceProvider);
  final limits = ref.watch(subscriptionLimitsProvider);
  return service.canSendMessage(limits);
});
