import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Churn Prevention: tracks app usage and schedules re-engagement
/// notifications when the user hasn't opened the app in 3+ days.
class ChurnPreventionService {
  static const String _lastOpenKey = 'churn_last_app_open';
  static const String _streakKey = 'churn_daily_streak';
  static const String _lastStreakDateKey = 'churn_last_streak_date';
  static const int _reengageNotifId = 9020;
  static const int _reengageNotifId2 = 9021;
  static const int _reengageNotifId3 = 9022;

  /// Record that the app was opened. Call from LifecycleManager on app start.
  static Future<void> recordAppOpen(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    prefs.setString(_lastOpenKey, now.toIso8601String());

    // Update daily streak
    final lastStreakDate = prefs.getString(_lastStreakDateKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;

    if (lastStreakDate == null) {
      prefs.setInt(_streakKey, 1);
    } else if (lastStreakDate == today) {
      // Same day, no change
    } else {
      final lastDate = DateTime.parse(lastStreakDate);
      final diff = now.difference(lastDate).inDays;
      if (diff == 1) {
        // Consecutive day
        prefs.setInt(_streakKey, currentStreak + 1);
      } else {
        // Streak broken
        prefs.setInt(_streakKey, 1);
      }
    }
    prefs.setString(_lastStreakDateKey, today);

    Log.d('App open recorded. Streak: ${prefs.getInt(_streakKey)}', label: 'ChurnPrevention');
  }

  /// Get current daily streak
  static int getStreak(SharedPreferences prefs) {
    return prefs.getInt(_streakKey) ?? 0;
  }

  /// Schedule re-engagement notifications for when user goes inactive.
  /// Called on app open — schedules future notifications that will only
  /// fire if user hasn't opened the app by then.
  static Future<void> scheduleReengagement() async {
    try {
      // Cancel existing re-engagement notifications
      await NotificationService.cancelNotification(_reengageNotifId);
      await NotificationService.cancelNotification(_reengageNotifId2);
      await NotificationService.cancelNotification(_reengageNotifId3);

      // Schedule re-engagement at 3, 7, and 14 days of inactivity
      final now = DateTime.now();

      // Day 3: Gentle reminder
      await NotificationService.scheduleNotification(
        id: _reengageNotifId,
        title: 'Your finances miss you!',
        body: 'You haven\'t checked your spending in 3 days. '
            'A quick look keeps you on track.',
        scheduledDate: now.add(const Duration(days: 3)),
      );

      // Day 7: Urgency + value
      await NotificationService.scheduleNotification(
        id: _reengageNotifId2,
        title: 'Weekly spending check-in',
        body: 'It\'s been a week — your Financial Health Score may have changed. '
            'Tap to see your weekly summary.',
        scheduledDate: now.add(const Duration(days: 7)),
      );

      // Day 14: Win-back
      await NotificationService.scheduleNotification(
        id: _reengageNotifId3,
        title: 'Your savings goal is waiting',
        body: 'Come back and check how your budget is doing this month. '
            'Bexly AI has new insights for you.',
        scheduledDate: now.add(const Duration(days: 14)),
      );

      Log.d('Re-engagement notifications scheduled (3d, 7d, 14d)', label: 'ChurnPrevention');
    } catch (e) {
      Log.e('Failed to schedule re-engagement: $e', label: 'ChurnPrevention');
    }
  }
}
