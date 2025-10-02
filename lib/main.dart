import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/app.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
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

  // Initialize PackageInfo service
  final packageInfoService = PackageInfoService();
  await packageInfoService.init();

  runApp(
    ProviderScope(
      overrides: [
        packageInfoServiceProvider.overrideWithValue(packageInfoService),
      ],
      child: const MyApp(),
    ),
  );
}
