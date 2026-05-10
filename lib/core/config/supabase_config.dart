import 'package:flutter/foundation.dart' show kDebugMode;

/// Supabase configuration loaded from compile-time environment variables
/// (--dart-define-from-file=.env at build time).
///
/// NOTE: Supabase uses "publishable key" (NOT "anon key") for client-side auth.
/// The publishable key is safe to expose in client apps.
class SupabaseConfig {
  /// Supabase project URL (e.g., https://dos.supabase.co)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dos.supabase.co',
  );

  /// Supabase publishable key for client-side authentication.
  /// CI injects via GitHub Secrets passed as --dart-define-from-file=.env.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// DOS-Me API base URL
  static const String dosMeApiUrl = String.fromEnvironment(
    'DOSME_API_URL',
    defaultValue: 'https://api.dos.me',
  );

  /// Product ID for DOS-Me API
  static const String productId = String.fromEnvironment(
    'DOSME_PRODUCT_ID',
    defaultValue: 'bexly',
  );

  /// Deep link scheme for OAuth callbacks
  static const String deepLinkScheme = 'bexly';

  /// OAuth callback URL
  static String get oauthCallbackUrl => '$deepLinkScheme://callback';

  static const String _googleClientIdDebug = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID_DEBUG',
  );
  static const String _googleClientIdRelease = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID_RELEASE',
  );

  /// Google OAuth Android Client ID for native Google Sign In.
  /// Returns debug or release client ID based on build mode.
  static String get googleWebClientId =>
      kDebugMode ? _googleClientIdDebug : _googleClientIdRelease;

  /// Check if Supabase is properly configured
  static bool get isConfigured =>
      publishableKey.isNotEmpty &&
      publishableKey != 'your_supabase_publishable_key_here';

  static const String _useDosmeOAuth = String.fromEnvironment(
    'USE_DOSME_OAUTH',
  );

  /// Use dos.me ID for OAuth token storage.
  /// When enabled, Gmail tokens are stored/retrieved from dos.me ID API.
  /// When disabled, tokens are stored locally (default, for backward compatibility).
  static bool get useDosmeOAuth {
    final v = _useDosmeOAuth.toLowerCase();
    return v == 'true' || v == '1';
  }
}
