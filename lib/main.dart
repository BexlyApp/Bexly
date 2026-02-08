import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:workmanager/workmanager.dart';
import 'package:bexly/core/app.dart';
import 'package:bexly/core/services/background_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/services/firebase_messaging_service.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
import 'package:bexly/core/services/ads/ad_service.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/features/email_sync/domain/services/email_sync_worker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Background callback dispatcher for WorkManager
///
/// This runs in an isolate separate from the main app.
/// It's called by the OS when background tasks need to execute.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('[WorkManager] Task started: $task');

      switch (task) {
        case EmailSyncWorker.taskName:
          // Run email sync in background
          final success = await EmailSyncWorker.syncCallback();
          print('[WorkManager] Email sync completed: $success');
          return success;

        default:
          print('[WorkManager] Unknown task: $task');
          return false;
      }
    } catch (e) {
      print('[WorkManager] Task failed: $e');
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until explicitly removed
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // In release mode, show a user-friendly error widget instead of grey screen
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Something went wrong. Please restart the app.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded successfully');
    print('STRIPE_PUBLISHABLE_KEY exists: ${dotenv.env.containsKey('STRIPE_PUBLISHABLE_KEY')}');
    print('STRIPE_PUBLISHABLE_KEY length: ${(dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '').length}');
  } catch (e) {
    print('❌ Could not load .env file: $e');
    // App can continue without .env file
  }

  // Lock orientation only on Android
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize Supabase (primary auth provider)
  try {
    await SupabaseInitService.initialize();
    print('✅ Supabase initialized');
  } catch (e) {
    print('⚠️ Supabase init error: $e');
    // Continue without Supabase - will fallback to Firebase
  }

  // Initialize Firebase apps (for Firestore, Analytics, Crashlytics, etc.)
  try {
    await FirebaseInitService.initialize();
    // Only setup Crashlytics after successful Firebase init
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    print('✅ Firebase initialized');
  } catch (e) {
    print('Firebase init error in main: $e');
    // Continue without Crashlytics if Firebase fails
  }

  // Initialize Google Sign-In (google_sign_in 7.x requires explicit initialization)
  // serverClientId is auto-detected from google-services.json (web client)
  // See: https://pub.dev/packages/google_sign_in_android
  try {
    print('🔑 Initializing Google Sign-In (auto-detect from google-services.json)...');
    await GoogleSignIn.instance.initialize();
    print('✅ Google Sign-In initialized successfully');
  } catch (e) {
    print('❌ Google Sign-In init error: $e');
    // Continue without Google Sign-In if init fails
  }

  // Initialize PackageInfo service
  final packageInfoService = PackageInfoService();
  await packageInfoService.init();

  // Initialize notification service
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification service init error: $e');
    // Continue without notifications if init fails
  }

  // Initialize Firebase Cloud Messaging
  try {
    await FirebaseMessagingService.initialize();
  } catch (e) {
    print('FCM init error: $e');
    // Continue without FCM if init fails
  }

  // Initialize Background Service for recurring payments (Android/iOS only)
  try {
    await BackgroundService.initialize();
    await BackgroundService.scheduleRecurringChargeTask();
  } catch (e) {
    print('BackgroundService init error: $e');
    // Continue without background service if init fails
  }

  // Initialize WorkManager for email sync (Android/iOS only)
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    print('✅ WorkManager initialized for email sync');
  } catch (e) {
    print('❌ WorkManager init error: $e');
    // Continue without WorkManager if init fails
  }

  // Initialize SharedPreferences for AI usage tracking
  final sharedPrefs = await SharedPreferences.getInstance();

  // Pending notification listener permission check is handled by
  // AutoTransactionService.initialize() — not here, because calling
  // native plugins before runApp() can cause grey screen on some devices.

  // Initialize AdMob
  try {
    await AdService().initialize();
  } catch (e) {
    debugPrint('AdMob init error: $e');
    // Continue without ads if init fails
  }

  runApp(
    ProviderScope(
      overrides: [
        packageInfoServiceProvider.overrideWithValue(packageInfoService),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MyApp(),
    ),
  );
}

