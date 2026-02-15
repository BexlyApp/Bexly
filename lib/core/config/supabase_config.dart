import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loaded from environment variables.
///
/// NOTE: Supabase uses "publishable key" (NOT "anon key") for client-side auth.
/// The publishable key is safe to expose in client apps.
class SupabaseConfig {
  /// Supabase project URL (e.g., https://dos.supabase.co)
  static String get url =>
      dotenv.env['SUPABASE_URL'] ?? 'https://dos.supabase.co';

  /// Supabase publishable key for client-side authentication.
  /// This is the public key from Supabase Dashboard > Settings > API.
  /// Safe to expose in client apps - NOT a secret key.
  /// Hardcoded fallback ensures Supabase works even if .env is incomplete (e.g. CI builds).
  static const _defaultPublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1bHB0d2R1Y2hzamNzYm5kbXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1OTI4NzQsImV4cCI6MjA4MjE2ODg3NH0.rRf1P8DhC_iK9KM2TSOU0XnjwoXmlBgZymGuhUdPazs';

  static String get publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? _defaultPublishableKey;

  /// DOS-Me API base URL
  static String get dosMeApiUrl =>
      dotenv.env['DOSME_API_URL'] ?? 'https://api.dos.me';

  /// Product ID for DOS-Me API
  static String get productId =>
      dotenv.env['DOSME_PRODUCT_ID'] ?? 'bexly';

  /// Deep link scheme for OAuth callbacks
  static const String deepLinkScheme = 'bexly';

  /// OAuth callback URL
  static String get oauthCallbackUrl => '$deepLinkScheme://callback';

  /// Google OAuth Android Client ID for native Google Sign In
  /// Required for Google Sign In SDK to work without Firebase
  /// Returns debug or release client ID based on build mode
  static String get googleWebClientId {
    // Debug build uses debug client ID with debug SHA-1
    if (kDebugMode) {
      return dotenv.env['GOOGLE_ANDROID_CLIENT_ID_DEBUG'] ?? '';
    }
    // Release/profile builds use release client ID with release SHA-1
    return dotenv.env['GOOGLE_ANDROID_CLIENT_ID_RELEASE'] ?? '';
  }

  /// Check if Supabase is properly configured
  static bool get isConfigured =>
      publishableKey.isNotEmpty &&
      publishableKey != 'your_supabase_publishable_key_here';

  /// Use dos.me ID for OAuth token storage
  /// When enabled, Gmail tokens are stored/retrieved from dos.me ID API
  /// When disabled, tokens are stored locally (default, for backward compatibility)
  static bool get useDosmeOAuth {
    final envValue = dotenv.env['USE_DOSME_OAUTH']?.toLowerCase();
    return envValue == 'true' || envValue == '1';
  }
}
