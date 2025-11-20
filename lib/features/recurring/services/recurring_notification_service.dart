import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:intl/intl.dart';

/// Service to manage notifications for recurring payments
class RecurringNotificationService {
  /// Schedule notification for a recurring payment
  static Future<void> scheduleNotification(RecurringModel recurring) async {
    try {
      // Check if recurring payment notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final recurringEnabled = prefs.getBool('notif_recurring_payments') ?? true;

      if (!recurringEnabled) {
        Log.d(
          'Recurring payment notifications disabled, skipping schedule',
          label: 'notification',
        );
        return;
      }

      // Check if this recurring has reminders enabled
      if (!recurring.enableReminder) {
        Log.d(
          'Reminders disabled for recurring ${recurring.id}, skipping',
          label: 'notification',
        );
        return;
      }

      // Check if recurring has ID (must be saved first)
      if (recurring.id == null) {
        Log.w(
          'Cannot schedule notification for unsaved recurring',
          label: 'notification',
        );
        return;
      }

      // Calculate notification date (X days before due date)
      final notificationDate = recurring.nextDueDate.subtract(
        Duration(days: recurring.reminderDaysBefore),
      );

      // Don't schedule if notification date is in the past
      if (notificationDate.isBefore(DateTime.now())) {
        Log.d(
          'Notification date is in the past for recurring ${recurring.id}',
          label: 'notification',
        );
        return;
      }

      // Format amount with currency
      final currencyFormat = NumberFormat.currency(
        symbol: recurring.currency,
        decimalDigits: 2,
      );
      final formattedAmount = currencyFormat.format(recurring.amount);

      // Create notification title and body
      final title = 'Payment Reminder: ${recurring.name}';
      final body = '$formattedAmount due on ${DateFormat.yMMMd().format(recurring.nextDueDate)}';

      // Schedule notification
      await NotificationService.scheduleNotification(
        id: recurring.id!,
        title: title,
        body: body,
        scheduledDate: notificationDate,
        payload: recurring.id.toString(), // Pass recurring ID for navigation
      );

      Log.i(
        'Scheduled notification for recurring ${recurring.id} at $notificationDate',
        label: 'notification',
      );
    } catch (e) {
      Log.e(
        'Failed to schedule notification for recurring: $e',
        label: 'notification',
      );
    }
  }

  /// Cancel notification for a recurring payment
  static Future<void> cancelNotification(int recurringId) async {
    try {
      await NotificationService.cancelNotification(recurringId);
      Log.d(
        'Cancelled notification for recurring $recurringId',
        label: 'notification',
      );
    } catch (e) {
      Log.e(
        'Failed to cancel notification for recurring: $e',
        label: 'notification',
      );
    }
  }

  /// Reschedule notification (cancel old and schedule new)
  static Future<void> rescheduleNotification(RecurringModel recurring) async {
    if (recurring.id != null) {
      await cancelNotification(recurring.id!);
    }
    await scheduleNotification(recurring);
  }

  /// Schedule notifications for multiple recurring payments
  static Future<void> scheduleAllNotifications(
    List<RecurringModel> recurrings,
  ) async {
    for (final recurring in recurrings) {
      await scheduleNotification(recurring);
    }
    Log.i(
      'Scheduled notifications for ${recurrings.length} recurrings',
      label: 'notification',
    );
  }

  /// Cancel all recurring payment notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
      Log.i('Cancelled all recurring notifications', label: 'notification');
    } catch (e) {
      Log.e(
        'Failed to cancel all recurring notifications: $e',
        label: 'notification',
      );
    }
  }
}
