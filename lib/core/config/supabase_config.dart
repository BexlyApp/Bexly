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
  static String get publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

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
}
