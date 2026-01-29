import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service for initializing Supabase client.
class SupabaseInitService {
  static const _label = 'SupabaseInit';
  static bool _initialized = false;

  /// Initialize Supabase with DOS-Me configuration.
  static Future<void> initialize() async {
    if (_initialized) {
      Log.d('Supabase already initialized, skipping', label: _label);
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      Log.w('Supabase not configured (missing SUPABASE_PUBLISHABLE_KEY)', label: _label);
      debugPrint('⚠️ Supabase not configured - auth features will be limited');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // Note: Supabase Flutter SDK uses "anonKey" parameter name,
        // but we use publishable key (same thing, different naming)
        anonKey: SupabaseConfig.publishableKey,
        debug: kDebugMode,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _initialized = true;
      Log.i('Supabase initialized successfully', label: _label);
      Log.d('Supabase URL: ${SupabaseConfig.url}', label: _label);
    } catch (e) {
      Log.e('Failed to initialize Supabase: $e', label: _label);
      debugPrint('❌ Supabase initialization failed: $e');
    }
  }

  /// Get the Supabase client instance.
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase not initialized. Call SupabaseInitService.initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Check if Supabase is initialized and ready.
  static bool get isInitialized => _initialized;

  /// Get current user from Supabase auth.
  static User? get currentUser => _initialized ? client.auth.currentUser : null;

  /// Get current session from Supabase auth.
  static Session? get currentSession => _initialized ? client.auth.currentSession : null;

  /// Stream of auth state changes.
  static Stream<AuthState>? get authStateChanges =>
      _initialized ? client.auth.onAuthStateChange : null;
}
