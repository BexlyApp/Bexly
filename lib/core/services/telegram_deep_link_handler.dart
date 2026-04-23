import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/supabase_init_service.dart';

/// Handler for Telegram deep link tokens
class TelegramDeepLinkHandler {
  static const String _label = 'TelegramDeepLinkHandler';

  /// Verify JWT token and link Telegram account
  ///
  /// Returns telegram_id if successful, null otherwise
  static Future<String?> linkWithToken(String token) async {
    try {
      if (!SupabaseInitService.isInitialized) {
        Log.w('Cannot link: Supabase not initialized', label: _label);
        return null;
      }
      final supabase = SupabaseInitService.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        Log.w('Cannot link: User not authenticated', label: _label);
        return null;
      }

      // Call Edge Function to verify token and link account
      final response = await supabase.functions.invoke(
        'link-telegram',
        body: {
          'telegram_token': token, // Send JWT token for backend to verify
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        final telegramId = data?['telegram_id'] as String?;

        Log.i('Telegram account linked via deep link: $telegramId', label: _label);
        return telegramId;
      } else {
        Log.e(
          'Failed to link via deep link: ${response.status} - ${response.data}',
          label: _label,
        );
        return null;
      }
    } catch (e, stack) {
      Log.e('Error linking with token: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return null;
    }
  }
}

