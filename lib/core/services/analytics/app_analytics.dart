import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Main analytics service for the app
class AppAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      print('Analytics: Screen view - $screenName');
    }
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // User actions
  static Future<void> logButtonClick({
    required String buttonName,
    String? screen,
    Map<String, Object?>? parameters,
  }) async {
    if (kDebugMode) {
      print('Analytics: Button click - $buttonName');
    }
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        'screen': screen ?? 'unknown',
        ...?parameters,
      },
    );
  }

  // Transaction events
  static Future<void> logTransactionCreated({
    required String type, // income or expense
    required double amount,
    required String currency,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'transaction_created',
      parameters: {
        'transaction_type': type,
        'amount': amount,
        'currency': currency,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Also log as revenue/expense for monetary tracking
    if (type == 'income') {
      await _analytics.logEvent(
        name: 'income_recorded',
        parameters: {
          'value': amount,
          'currency': currency,
        },
      );
    } else {
      await _analytics.logEvent(
        name: 'expense_recorded',
        parameters: {
          'value': amount,
          'currency': currency,
        },
      );
    }
  }

  // Wallet events
  static Future<void> logWalletCreated({
    required String currency,
    required double initialBalance,
  }) async {
    await _analytics.logEvent(
      name: 'wallet_created',
      parameters: {
        'currency': currency,
        'initial_balance': initialBalance,
      },
    );
  }

  static Future<void> logWalletSwitched({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    await _analytics.logEvent(
      name: 'wallet_switched',
      parameters: {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
      },
    );
  }

  // Budget events
  static Future<void> logBudgetCreated({
    required String category,
    required double amount,
    required String period,
  }) async {
    await _analytics.logEvent(
      name: 'budget_created',
      parameters: {
        'category': category,
        'amount': amount,
        'period': period,
      },
    );
  }

  // AI Chat events
  static Future<void> logAIChatMessage({
    required String messageType, // user or ai
    required int messageLength,
    String? action, // if AI performed an action
  }) async {
    await _analytics.logEvent(
      name: 'ai_chat_message',
      parameters: {
        'message_type': messageType,
        'message_length': messageLength,
        if (action != null) 'action': action,
      },
    );
  }

  static Future<void> logAIChatAction({
    required String action,
    required bool success,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'ai_chat_action',
      parameters: {
        'action': action,
        'success': success,
        if (errorMessage != null) 'error': errorMessage,
      },
    );
  }

  // Feature usage
  static Future<void> logFeatureUsed({
    required String feature,
    Map<String, Object?>? parameters,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': feature,
        ...?parameters,
      },
    );
  }

  // User properties
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  static Future<void> updateUserProperties({
    String? preferredCurrency,
    String? preferredLanguage,
    int? walletCount,
    bool? hasEnabledNotifications,
  }) async {
    if (preferredCurrency != null) {
      await setUserProperty(name: 'preferred_currency', value: preferredCurrency);
    }
    if (preferredLanguage != null) {
      await setUserProperty(name: 'preferred_language', value: preferredLanguage);
    }
    if (walletCount != null) {
      await setUserProperty(name: 'wallet_count', value: walletCount.toString());
    }
    if (hasEnabledNotifications != null) {
      await setUserProperty(
        name: 'notifications_enabled',
        value: hasEnabledNotifications.toString(),
      );
    }
  }

  // Login/Signup events
  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // App lifecycle
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Session tracking
  static Future<void> logSessionStart() async {
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logSessionEnd({required Duration duration}) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'duration_seconds': duration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Error tracking
  static Future<void> logError({
    required String error,
    required String? stackTrace,
    String? context,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error': error,
        'stack_trace': stackTrace?.substring(0, 100) ?? 'none',
        'context': context ?? 'unknown',
      },
    );
  }
}