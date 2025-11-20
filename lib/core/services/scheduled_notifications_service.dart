import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service to manage all scheduled notifications (daily, weekly, monthly)
class ScheduledNotificationsService {
  // Notification IDs (must be unique)
  static const int _dailyReminderId = 9000;
  static const int _weeklyReportId = 9001;
  static const int _monthlyReportId = 9002;

  /// Schedule daily reminder notification (9 PM every day)
  static Future<void> scheduleDailyReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_daily_reminder') ?? false;

      if (!enabled) {
        Log.d('Daily reminder disabled, skipping', label: 'notification');
        await NotificationService.cancelNotification(_dailyReminderId);
        return;
      }

      // Schedule for 9 PM today (or tomorrow if past 9 PM)
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21, // 9 PM
        0,
      );

      // If 9 PM has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await NotificationService.scheduleNotification(
        id: _dailyReminderId,
        title: 'Log Your Expenses',
        body: 'Don\'t forget to record today\'s spending!',
        scheduledDate: scheduledDate,
      );

      // Schedule to repeat daily
      await _scheduleRepeatingDaily();

      Log.i('Daily reminder scheduled for $scheduledDate', label: 'notification');
    } catch (e) {
      Log.e('Failed to schedule daily reminder: $e', label: 'notification');
    }
  }

  /// Schedule weekly report notification (Monday 9 AM)
  static Future<void> scheduleWeeklyReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_weekly_report') ?? false;

      if (!enabled) {
        Log.d('Weekly report disabled, skipping', label: 'notification');
        await NotificationService.cancelNotification(_weeklyReportId);
        return;
      }

      // Schedule for next Monday at 9 AM
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9 AM
        0,
      );

      // Find next Monday
      int daysUntilMonday = (DateTime.monday - scheduledDate.weekday + 7) % 7;
      if (daysUntilMonday == 0 && scheduledDate.isBefore(now)) {
        daysUntilMonday = 7; // Schedule for next week if Monday 9 AM has passed
      }
      scheduledDate = scheduledDate.add(Duration(days: daysUntilMonday));

      await NotificationService.scheduleNotification(
        id: _weeklyReportId,
        title: 'Weekly Spending Report',
        body: 'Check out your spending summary from last week',
        scheduledDate: scheduledDate,
      );

      Log.i('Weekly report scheduled for $scheduledDate', label: 'notification');
    } catch (e) {
      Log.e('Failed to schedule weekly report: $e', label: 'notification');
    }
  }

  /// Schedule monthly report notification (1st day of month at 9 AM)
  static Future<void> scheduleMonthlyReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_monthly_report') ?? false;

      if (!enabled) {
        Log.d('Monthly report disabled, skipping', label: 'notification');
        await NotificationService.cancelNotification(_monthlyReportId);
        return;
      }

      // Schedule for 1st day of next month at 9 AM
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        1, // 1st day
        9, // 9 AM
        0,
      );

      await NotificationService.scheduleNotification(
        id: _monthlyReportId,
        title: 'Monthly Financial Report',
        body: 'Your complete financial summary for last month is ready',
        scheduledDate: scheduledDate,
      );

      Log.i('Monthly report scheduled for $scheduledDate', label: 'notification');
    } catch (e) {
      Log.e('Failed to schedule monthly report: $e', label: 'notification');
    }
  }

  /// Reschedule all enabled notifications
  static Future<void> rescheduleAll() async {
    await scheduleDailyReminder();
    await scheduleWeeklyReport();
    await scheduleMonthlyReport();
    Log.i('All scheduled notifications updated', label: 'notification');
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await NotificationService.cancelNotification(_dailyReminderId);
    await NotificationService.cancelNotification(_weeklyReportId);
    await NotificationService.cancelNotification(_monthlyReportId);
    Log.i('All scheduled notifications cancelled', label: 'notification');
  }

  /// Helper to schedule repeating daily notification
  /// Note: This is a placeholder - proper implementation needs background job
  static Future<void> _scheduleRepeatingDaily() async {
    // For now, we just schedule once
    // In production, use WorkManager or similar for true repeating notifications
    // Or reschedule after each notification is shown
  }
}
