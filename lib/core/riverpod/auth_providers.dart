import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart';

/// Guest mode notifier - tracks whether user is in offline/guest mode
class GuestModeNotifier extends Notifier<bool> {
  static const _key = 'guest_mode';

  @override
  bool build() {
    _loadFromPrefs();
    return true; // Default to guest mode (with offline support)
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isGuest);
    state = isGuest;
  }
}

/// Provider for guest mode state
final isGuestModeProvider = NotifierProvider<GuestModeNotifier, bool>(
  GuestModeNotifier.new,
);

/// Provider for checking if user is authenticated with Supabase
final isSupabaseAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(supabaseAuthServiceProvider).isAuthenticated;
});

/// Alias for backward compatibility
final isAuthenticatedProvider = isSupabaseAuthenticatedProvider;
