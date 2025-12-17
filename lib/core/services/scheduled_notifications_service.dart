import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service to manage all scheduled notifications (daily, weekly, monthly)
class ScheduledNotificationsService {
  // Notification IDs (must be unique)
  static const int _dailyReminderId = 9000;
  static const int _weeklyReportId = 9001;
  static const int _monthlyReportId = 9002;

  /// Get current language code from SharedPreferences
  static Future<String> _getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code') ?? 'en';
  }

  /// Helper to create notification record in database
  static Future<void> _createNotificationRecord({
    required String title,
    required String body,
    required String type,
    required tz.TZDateTime scheduledFor,
  }) async {
    try {
      final db = AppDatabase();
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          title: Value(title),
          body: Value(body),
          type: Value(type),
          scheduledFor: Value(scheduledFor),
          isRead: const Value(false),
        ),
      );
      Log.d('Created notification record: $title', label: 'notification');
    } catch (e) {
      Log.e('Failed to create notification record: $e', label: 'notification');
    }
  }

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

      // Get localized strings
      final langCode = await _getLanguageCode();
      final title = AppLocalizations.getByLocale(langCode, 'notifDailyReminderTitle');
      final body = AppLocalizations.getByLocale(langCode, 'notifDailyReminderBody');

      // Schedule daily at 9 PM (21:00)
      await NotificationService.scheduleDailyNotification(
        id: _dailyReminderId,
        title: title,
        body: body,
        hour: 21,
        minute: 0,
      );

      Log.i('Daily reminder scheduled for 21:00', label: 'notification');
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

      // Get localized strings
      final langCode = await _getLanguageCode();
      final title = AppLocalizations.getByLocale(langCode, 'notifWeeklyReportTitle');
      final body = AppLocalizations.getByLocale(langCode, 'notifWeeklyReportBody');

      // Schedule weekly on Monday at 9 AM
      await NotificationService.scheduleWeeklyNotification(
        id: _weeklyReportId,
        title: title,
        body: body,
        weekday: DateTime.monday,
        hour: 9,
        minute: 0,
      );

      Log.i('Weekly report scheduled for Monday 9:00', label: 'notification');
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

      // Get localized strings
      final langCode = await _getLanguageCode();
      final title = AppLocalizations.getByLocale(langCode, 'notifMonthlyReportTitle');
      final body = AppLocalizations.getByLocale(langCode, 'notifMonthlyReportBody');

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
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );

      // Create notification record in database
      await _createNotificationRecord(
        title: title,
        body: body,
        type: 'monthly_report',
        scheduledFor: scheduledDate,
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

}
