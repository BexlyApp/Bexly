import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service for linking/unlinking Telegram bot to Bexly account
class TelegramBotService {
  static const String _label = 'TelegramBotService';

  /// Get Supabase Functions URL base
  static String get _functionsUrl {
    return '${SupabaseConfig.url}/functions/v1';
  }

  /// Link Telegram account to current Bexly user
  ///
  /// Call this after user initiates link from Telegram bot
  /// Pass the telegram_id from Telegram bot
  static Future<bool> linkTelegramAccount(String telegramId) async {
    try {
      if (!SupabaseInitService.isInitialized) {
        Log.w('Cannot link Telegram: Supabase not initialized', label: _label);
        return false;
      }
      final supabase = SupabaseInitService.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        Log.w('Cannot link Telegram: User not authenticated', label: _label);
        return false;
      }

      final accessToken = session.accessToken;

      // Call Supabase Edge Function
      final response = await supabase.functions.invoke(
        'link-telegram',
        body: {
          'telegram_id': telegramId,
        },
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.status == 200) {
        Log.i('Telegram account linked successfully', label: _label);
        return true;
      } else {
        Log.e(
          'Failed to link Telegram account: ${response.status} - ${response.data}',
          label: _label,
        );
        return false;
      }
    } catch (e, stack) {
      Log.e('Error linking Telegram account: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return false;
    }
  }

  /// Unlink Telegram account from current Bexly user
  static Future<bool> unlinkTelegramAccount() async {
    try {
      if (!SupabaseInitService.isInitialized) {
        Log.w('Cannot unlink Telegram: Supabase not initialized', label: _label);
        return false;
      }
      final supabase = SupabaseInitService.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        Log.w('Cannot unlink Telegram: User not authenticated', label: _label);
        return false;
      }

      final accessToken = session.accessToken;

      // Call Supabase Edge Function
      final response = await supabase.functions.invoke(
        'unlink-telegram',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.status == 200) {
        Log.i('Telegram account unlinked successfully', label: _label);
        return true;
      } else {
        Log.e(
          'Failed to unlink Telegram account: ${response.status} - ${response.data}',
          label: _label,
        );
        return false;
      }
    } catch (e, stack) {
      Log.e('Error unlinking Telegram account: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return false;
    }
  }

  /// Check if Telegram is linked
  ///
  /// Returns true if current user has linked Telegram account
  static Future<bool> isLinked() async {
    try {
      if (!SupabaseInitService.isInitialized) return false;
      final supabase = SupabaseInitService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        return false;
      }

      final response = await supabase
          .schema('bexly')
          .from('user_integrations')
          .select()
          .eq('user_id', userId)
          .eq('platform', 'telegram')
          .maybeSingle();

      return response != null;
    } catch (e) {
      Log.e('Error checking Telegram link status: $e', label: _label);
      return false;
    }
  }

  /// Get Telegram user ID if linked
  ///
  /// Returns null if not linked
  static Future<String?> getLinkedTelegramId() async {
    try {
      if (!SupabaseInitService.isInitialized) return null;
      final supabase = SupabaseInitService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        return null;
      }

      final response = await supabase
          .schema('bexly')
          .from('user_integrations')
          .select('platform_user_id')
          .eq('user_id', userId)
          .eq('platform', 'telegram')
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response['platform_user_id'] as String?;
    } catch (e) {
      Log.e('Error getting linked Telegram ID: $e', label: _label);
      return null;
    }
  }
}
