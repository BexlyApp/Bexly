import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service to manage local push notifications
/// Used for recurring payment reminders
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) {
      Log.d('Notifications already initialized', label: 'notification');
      return;
    }

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      Log.i('Notification service initialized', label: 'notification');
    } catch (e) {
      Log.e('Failed to initialize notification service: $e', label: 'notification');
      rethrow;
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    Log.d('Notification tapped: ${response.payload}', label: 'notification');
    // TODO: Navigate to recurring detail screen using payload (recurring ID)
  }

  /// Request notification permission (Android 13+, iOS)
  static Future<bool> requestPermission() async {
    try {
      // Check Android version
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        Log.d('Notification permission: $status', label: 'notification');
        return status.isGranted;
      }

      // Already granted
      return true;
    } catch (e) {
      Log.e('Failed to request notification permission: $e', label: 'notification');
      return false;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      Log.e('Failed to check notification permission: $e', label: 'notification');
      return false;
    }
  }

  /// Schedule a notification for recurring payment reminder
  ///
  /// [id] - Unique notification ID (use recurring ID)
  /// [title] - Notification title
  /// [body] - Notification body
  /// [scheduledDate] - When to show notification
  /// [payload] - Data to pass when notification is tapped (recurring ID)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      Log.w('Notification service not initialized', label: 'notification');
      return;
    }

    try {
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'recurring_payments', // Channel ID
        'Recurring Payments', // Channel name
        channelDescription: 'Reminders for upcoming recurring payments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      Log.i(
        'Scheduled notification $id for ${scheduledDate.toString()}',
        label: 'notification',
      );
    } catch (e) {
      Log.e('Failed to schedule notification: $e', label: 'notification');
    }
  }

  /// Cancel a scheduled notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      Log.d('Cancelled notification $id', label: 'notification');
    } catch (e) {
      Log.e('Failed to cancel notification: $e', label: 'notification');
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      Log.i('Cancelled all notifications', label: 'notification');
    } catch (e) {
      Log.e('Failed to cancel all notifications: $e', label: 'notification');
    }
  }

  /// Show instant notification (not scheduled)
  /// Useful for alerts that should appear immediately
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      Log.w('Notification service not initialized', label: 'notification');
      return;
    }

    try {
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'instant_alerts', // Channel ID
        'Instant Alerts', // Channel name
        channelDescription: 'Immediate alerts for budget, goals, etc',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification immediately
      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      Log.i('Showed instant notification: $title', label: 'notification');
    } catch (e) {
      Log.e('Failed to show instant notification: $e', label: 'notification');
    }
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      Log.d('Pending notifications: ${pending.length}', label: 'notification');
      return pending;
    } catch (e) {
      Log.e('Failed to get pending notifications: $e', label: 'notification');
      return [];
    }
  }

  static bool get isInitialized => _initialized;
}
