import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
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
import 'package:bexly/features/email_sync/domain/services/email_sync_worker.dart';
import 'package:bexly/features/settings/presentation/riverpod/number_format_provider.dart';
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

/// Safely initializes a non-critical service, catching and logging errors.
Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
    print('✅ $name initialized');
  } catch (e) {
    print('⚠️ $name init error: $e');
  }
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // In release mode, show a user-friendly error widget instead of grey screen
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('ErrorWidget: ${details.exception}');
      debugPrint('ErrorWidget stack: ${details.stack}');
      return Material(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Something went wrong.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${details.exception}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  // ── Phase 1: Fast critical setup (sequential, each <50ms) ──
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded successfully');
  } catch (e) {
    print('❌ Could not load .env file: $e');
  }

  await NumberFormatNotifier.initFromPrefs();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ── Phase 2: Auth providers (parallel — independent of each other) ──
  await Future.wait([
    _safeInit('Supabase', () => SupabaseInitService.initialize()),
    _safeInit('Firebase', () async {
      await FirebaseInitService.initialize();
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }),
  ]);

  // ── Phase 3: All remaining services (parallel) ──
  // PackageInfoService and SharedPreferences are needed for ProviderScope
  // overrides; the rest are non-critical and wrapped in _safeInit.
  final packageInfoService = PackageInfoService();
  final results = await Future.wait<dynamic>([
    packageInfoService.init(), // index 0
    SharedPreferences.getInstance(), // index 1
    _safeInit(
      'GoogleSignIn',
      () => GoogleSignIn.instance.initialize(
        // iOS requires explicit clientId so serverClientId is applied correctly
        clientId: Platform.isIOS
            ? '368090586626-jp6s7eerkn9v7279dvgrluaf6jep8kku.apps.googleusercontent.com'
            : null,
        serverClientId:
            '368090586626-ch5cd0afri6pilfipeersbtqkpf6huj6.apps.googleusercontent.com',
      ),
    ),
    _safeInit('Notifications', () => NotificationService.initialize()),
    _safeInit('FCM', () => FirebaseMessagingService.initialize()),
    _safeInit('BackgroundService', () async {
      await BackgroundService.initialize();
      await BackgroundService.scheduleRecurringChargeTask();
    }),
    _safeInit(
      'WorkManager',
      () => Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      ),
    ),
    _safeInit('AdService', () => AdService().initialize()),
  ]);

  final sharedPrefs = results[1] as SharedPreferences;

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

