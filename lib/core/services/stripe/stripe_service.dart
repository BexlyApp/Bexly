import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service for Stripe initialization and Financial Connections
class StripeService {
  static bool _initialized = false;

  /// Initialize Stripe SDK with publishable key
  static Future<void> initialize() async {
    if (_initialized) {
      Log.d('Stripe already initialized', label: 'Stripe');
      return;
    }

    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    Log.d('STRIPE_PUBLISHABLE_KEY length: ${publishableKey.length}, isEmpty: ${publishableKey.isEmpty}', label: 'Stripe');

    if (publishableKey.isEmpty || publishableKey.contains('your_')) {
      Log.w('Stripe publishable key not configured or invalid', label: 'Stripe');
      return;
    }

    try {
      Log.d('Setting Stripe publishable key...', label: 'Stripe');
      Stripe.publishableKey = publishableKey;

      Log.d('Applying Stripe settings...', label: 'Stripe');
      await Stripe.instance.applySettings();

      _initialized = true;
      Log.i('Stripe initialized successfully', label: 'Stripe');
    } catch (e, stackTrace) {
      Log.e('Failed to initialize Stripe: $e', label: 'Stripe');
      Log.e('Stack trace: $stackTrace', label: 'Stripe');
      // Still mark as initialized so we can show proper error
      _initialized = true;
    }
  }

  /// Check if Stripe is initialized
  static bool get isInitialized => _initialized;

  /// Ensure Stripe is initialized (lazy init)
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      throw Exception('Stripe not configured. Please add STRIPE_PUBLISHABLE_KEY to .env');
    }
  }

  /// Collect Financial Connections accounts
  /// Automatically initializes Stripe if not already done (lazy init)
  /// Returns the session result with linked accounts
  static Future<FinancialConnectionSessionResult?> collectBankAccounts({
    required String clientSecret,
  }) async {
    await _ensureInitialized();

    try {
      Log.d('Starting Financial Connections flow...', label: 'Stripe');

      final result = await Stripe.instance.collectFinancialConnectionsAccounts(
        clientSecret: clientSecret,
      );

      Log.d('Financial Connections completed: ${result.session.accounts.length} accounts linked', label: 'Stripe');
      return result;
    } on StripeException catch (e) {
      Log.e('Stripe error: ${e.error.localizedMessage}', label: 'Stripe');
      rethrow;
    } catch (e) {
      Log.e('Failed to collect bank accounts: $e', label: 'Stripe');
      rethrow;
    }
  }
}
