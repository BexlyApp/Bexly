import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:bexly/firebase_options.dart';
import 'package:bexly/core/config/dos_me_firebase_options.dart';

class FirebaseInitService {
  static bool _initialized = false;
  static FirebaseApp? _dosmeApp;
  static FirebaseApp? _bexlyApp;

  static FirebaseApp? get dosmeApp => _dosmeApp;

  static FirebaseApp get bexlyApp {
    if (_bexlyApp == null) {
      throw Exception('Bexly Firebase not initialized');
    }
    return _bexlyApp!;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('Firebase already initialized, skipping');
      return;
    }

    try {
      // Check if Firebase apps already exist
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase apps already initialized: ${Firebase.apps.length}');

        // Find existing apps
        for (var app in Firebase.apps) {
          debugPrint('Found existing app: ${app.name}');
          if (app.name == 'dos-me') {
            _dosmeApp = app;
          } else if (app.name == '[DEFAULT]') {
            _bexlyApp = app;
          }
        }

        if (_bexlyApp != null) {
          _initialized = true;
          debugPrint('Using existing Firebase apps');
          return;
        }
      }

      // Initialize default app (Bexly project - for Firestore, Analytics, etc.)
      try {
        _bexlyApp = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Bexly Firebase initialized');
      } catch (e) {
        if (e.toString().contains('duplicate-app')) {
          // App already exists, find it
          for (var app in Firebase.apps) {
            if (app.name == '[DEFAULT]') {
              _bexlyApp = app;
              debugPrint('Using existing default Firebase app');
              break;
            }
          }
        } else {
          rethrow;
        }
      }

      // Initialize secondary app (DOS-Me project - for Authentication only)
      try {
        _dosmeApp = await Firebase.initializeApp(
          name: 'dos-me',
          options: DOSMeFirebaseOptions.currentPlatform,
        );
        debugPrint('DOS-Me Firebase initialized');
      } catch (e) {
        if (e.toString().contains('duplicate-app')) {
          // App already exists, find it
          for (var app in Firebase.apps) {
            if (app.name == 'dos-me') {
              _dosmeApp = app;
              debugPrint('Using existing DOS-Me Firebase app');
              break;
            }
          }
        } else {
          // DOS-Me app is optional, log error but continue
          debugPrint('DOS-Me Firebase initialization failed (optional): $e');
        }
      }

      _initialized = true;
      debugPrint('Firebase initialization complete');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');

      // Try to recover by using existing apps if available
      if (Firebase.apps.isNotEmpty) {
        for (var app in Firebase.apps) {
          if (app.name == 'dos-me') {
            _dosmeApp = app;
          } else if (app.name == '[DEFAULT]') {
            _bexlyApp = app;
          }
        }

        if (_bexlyApp != null) {
          _initialized = true;
          debugPrint('Recovered using existing Firebase apps');
          return;
        }
      }

      rethrow;
    }
  }

  static bool get isInitialized => _initialized;
}