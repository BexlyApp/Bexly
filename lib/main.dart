import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/app.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(ProviderScope(child: const MyApp()));
}
