import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:drift/drift.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Log.i('Handling background message: ${message.messageId}', label: 'FCM');

  // Store notification in database
  try {
    final db = AppDatabase();
    await db.notificationDao.insertNotification(
      NotificationsCompanion(
        title: Value(message.notification?.title ?? 'Notification'),
        body: Value(message.notification?.body ?? ''),
        type: Value(message.data['type'] ?? 'remote_push'),
        scheduledFor: Value(DateTime.now()),
        isRead: const Value(false),
      ),
    );
    Log.i('Stored background notification in database', label: 'FCM');
  } catch (e) {
    Log.e('Failed to store background notification: $e', label: 'FCM');
  }
}

/// Service to handle Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _fcmToken;

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    print('🚀 [FCM] Starting FCM initialization...');

    if (_initialized) {
      print('⚠️ [FCM] Already initialized');
      Log.d('FCM already initialized', label: 'FCM');
      return;
    }

    try {
      print('📱 [FCM] Checking notification permission...');

      // Check current permission status first
      NotificationSettings currentSettings = await _messaging.getNotificationSettings();
      print('🔍 [FCM] Current permission status: ${currentSettings.authorizationStatus}');

      NotificationSettings settings;

      if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
        // Permission not determined yet - request it
        print('📱 [FCM] Requesting permission...');
        settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        print('✅ [FCM] Permission requested. Status: ${settings.authorizationStatus}');
      } else {
        // Permission already determined - use current status
        print('✅ [FCM] Permission already determined: ${currentSettings.authorizationStatus}');
        settings = currentSettings;
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [FCM] Permission GRANTED');
        Log.i('FCM permission granted', label: 'FCM');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ [FCM] Permission PROVISIONAL');
        Log.i('FCM provisional permission granted', label: 'FCM');
      } else {
        print('❌ [FCM] Permission DENIED');
        Log.w('FCM permission denied', label: 'FCM');
        return;
      }

      print('🔑 [FCM] Getting FCM token...');
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('✅ [FCM] Token received');
        if (kDebugMode) {
          Log.i('FCM Token: $_fcmToken', label: 'FCM');
        }
      } else {
        print('❌ [FCM] Token is NULL!');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          Log.i('FCM Token refreshed: $newToken', label: 'FCM');
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app was terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      Log.i('Firebase Cloud Messaging initialized', label: 'FCM');
    } catch (e) {
      Log.e('Failed to initialize FCM: $e', label: 'FCM');
      rethrow;
    }
  }

  /// Handle foreground message
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 [FCM] _handleForegroundMessage called');
    print('🔔 [FCM] Message ID: ${message.messageId}');
    print('🔔 [FCM] Notification: ${message.notification}');
    print('🔔 [FCM] Notification title: ${message.notification?.title}');
    print('🔔 [FCM] Notification body: ${message.notification?.body}');
    print('🔔 [FCM] Data: ${message.data}');

    Log.i('Received foreground message: ${message.notification?.title}', label: 'FCM');

    // Show local notification
    if (message.notification != null) {
      print('🔔 [FCM] Showing local notification...');
      try {
        await NotificationService.showInstantNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data['payload'],
        );
        print('✅ [FCM] Local notification shown');
      } catch (e) {
        print('❌ [FCM] Failed to show notification: $e');
        Log.e('Failed to show notification: $e', label: 'FCM');
      }
    } else {
      print('⚠️ [FCM] message.notification is NULL - cannot show notification');
    }

    // Store notification in database
    try {
      print('💾 [FCM] Storing notification in database...');
      final db = AppDatabase();
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          title: Value(message.notification?.title ?? 'Notification'),
          body: Value(message.notification?.body ?? ''),
          type: Value(message.data['type'] ?? 'remote_push'),
          scheduledFor: Value(DateTime.now()),
          isRead: const Value(false),
        ),
      );
      print('✅ [FCM] Stored foreground notification in database');
      Log.i('Stored foreground notification in database', label: 'FCM');
    } catch (e) {
      print('❌ [FCM] Failed to store notification: $e');
      Log.e('Failed to store foreground notification: $e', label: 'FCM');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    Log.i('Notification tapped: ${message.data}', label: 'FCM');

    // TODO: Navigate to specific screen based on message.data['route']
    // For example:
    // if (message.data['route'] == 'transactions') {
    //   navigatorKey.currentState?.pushNamed('/transactions');
    // }
  }

  /// Get current FCM token. Send this to the server when push delivery is wired up
  /// (currently no consumer reads/sends pushes — the legacy Firestore pipeline was
  /// removed when the bot moved to Supabase Edge Functions).
  static String? get fcmToken => _fcmToken;

  /// Check if FCM is initialized
  static bool get isInitialized => _initialized;

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      Log.i('Subscribed to topic: $topic', label: 'FCM');
    } catch (e) {
      Log.e('Failed to subscribe to topic: $e', label: 'FCM');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      Log.i('Unsubscribed from topic: $topic', label: 'FCM');
    } catch (e) {
      Log.e('Failed to unsubscribe from topic: $e', label: 'FCM');
    }
  }
}
