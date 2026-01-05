import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bexly/core/app.dart';
import 'package:bexly/core/services/background_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/services/firebase_messaging_service.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
import 'package:bexly/core/services/ads/ad_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until explicitly removed
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  // Initialize dual Firebase apps
  try {
    await FirebaseInitService.initialize();
    // Only setup Crashlytics after successful Firebase init
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    print('Firebase init error in main: $e');
    // Continue without Crashlytics if Firebase fails
  }

  // Initialize Google Sign-In (google_sign_in 7.x requires explicit initialization)
  // serverClientId must be provided explicitly for debug builds to work
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: '368090586626-ch5cd0afri6pilfipeersbtqkpf6huj6.apps.googleusercontent.com',
    );
  } catch (e) {
    print('Google Sign-In init error: $e');
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

  // Initialize SharedPreferences for AI usage tracking
  final sharedPrefs = await SharedPreferences.getInstance();

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
