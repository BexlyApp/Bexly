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
      // First check current status
      final currentStatus = await Permission.notification.status;
      Log.d('Current notification permission status: $currentStatus', label: 'notification');

      if (currentStatus.isGranted) {
        return true;
      }

      if (currentStatus.isPermanentlyDenied) {
        Log.w('Notification permission permanently denied', label: 'notification');
        return false;
      }

      // Request permission
      final status = await Permission.notification.request();
      Log.d('Notification permission after request: $status', label: 'notification');

      // Also request from flutter_local_notifications for iOS
      final iosGranted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      Log.d('iOS notification permission: $iosGranted', label: 'notification');

      return status.isGranted || (iosGranted ?? false);
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

  /// Schedule a one-time notification
  ///
  /// [id] - Unique notification ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [scheduledDate] - When to show notification
  /// [payload] - Data to pass when notification is tapped
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
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Don't schedule if the date is in the past
      if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        Log.w('Scheduled date is in the past, skipping: $scheduledDate', label: 'notification');
        return;
      }

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'scheduled_reminders', // Channel ID
        'Scheduled Reminders', // Channel name
        channelDescription: 'Reminders for recurring payments and reports',
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

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
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

  /// Schedule a daily repeating notification at a specific time
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) {
      Log.w('Notification service not initialized', label: 'notification');
      return;
    }

    try {
      // Calculate next occurrence
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'daily_reminders',
        'Daily Reminders',
        channelDescription: 'Daily reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
        payload: payload,
      );

      Log.i(
        'Scheduled daily notification $id at $hour:$minute',
        label: 'notification',
      );
    } catch (e) {
      Log.e('Failed to schedule daily notification: $e', label: 'notification');
    }
  }

  /// Schedule a weekly repeating notification
  static Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) {
      Log.w('Notification service not initialized', label: 'notification');
      return;
    }

    try {
      // Calculate next occurrence
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Find next occurrence of the weekday
      int daysUntil = (weekday - scheduledDate.weekday + 7) % 7;
      if (daysUntil == 0 && scheduledDate.isBefore(now)) {
        daysUntil = 7;
      }
      scheduledDate = scheduledDate.add(Duration(days: daysUntil));

      const androidDetails = AndroidNotificationDetails(
        'weekly_reports',
        'Weekly Reports',
        channelDescription: 'Weekly summary notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );

      Log.i(
        'Scheduled weekly notification $id for weekday $weekday at $hour:$minute',
        label: 'notification',
      );
    } catch (e) {
      Log.e('Failed to schedule weekly notification: $e', label: 'notification');
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
