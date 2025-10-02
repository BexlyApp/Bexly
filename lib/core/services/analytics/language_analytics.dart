import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bexly/features/settings/presentation/riverpod/language_provider.dart';

class LanguageAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Track when user changes language
  static Future<void> trackLanguageChange({
    required String fromLanguage,
    required String toLanguage,
  }) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {
        'from_language': fromLanguage,
        'to_language': toLanguage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Also set user property for current language
    await _analytics.setUserProperty(
      name: 'preferred_language',
      value: toLanguage,
    );
  }

  /// Track language selection in onboarding
  static Future<void> trackOnboardingLanguageSelection(String language) async {
    await _analytics.logEvent(
      name: 'onboarding_language_selected',
      parameters: {
        'language': language,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track language usage session
  static Future<void> trackLanguageSessionStart(String language) async {
    await _analytics.logEvent(
      name: 'language_session_start',
      parameters: {
        'language': language,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get language distribution for A/B testing
  static Future<void> logLanguageDistribution(Map<String, int> distribution) async {
    await _analytics.logEvent(
      name: 'language_distribution',
      parameters: distribution,
    );
  }
}