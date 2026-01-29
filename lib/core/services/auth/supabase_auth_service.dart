import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Auth status for Supabase authentication.
enum SupabaseAuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

/// Auth state for Supabase authentication.
class SupabaseAuthState {
  final SupabaseAuthStatus status;
  final User? user;
  final Session? session;
  final String? error;
  final bool isNew;
  final bool requiresEmailConfirmation;

  SupabaseAuthState({
    this.status = SupabaseAuthStatus.uninitialized,
    this.user,
    this.session,
    this.error,
    this.isNew = false,
    this.requiresEmailConfirmation = false,
  });

  SupabaseAuthState copyWith({
    SupabaseAuthStatus? status,
    User? user,
    Session? session,
    String? error,
    bool? isNew,
    bool? requiresEmailConfirmation,
  }) {
    return SupabaseAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      error: error,
      isNew: isNew ?? this.isNew,
      requiresEmailConfirmation: requiresEmailConfirmation ?? this.requiresEmailConfirmation,
    );
  }

  bool get isAuthenticated => status == SupabaseAuthStatus.authenticated;
  bool get isLoading => status == SupabaseAuthStatus.loading;
  String? get userId => user?.id;
  String? get email => user?.email;
  String? get fullName => user?.userMetadata?['full_name'] as String?;
  String? get avatarUrl => user?.userMetadata?['avatar_url'] as String?;
}

/// Supabase Authentication Service using Riverpod.
class SupabaseAuthService extends Notifier<SupabaseAuthState> {
  static const _label = 'SupabaseAuth';

  late final SupabaseClient _supabase;

  @override
  SupabaseAuthState build() {
    if (!SupabaseInitService.isInitialized) {
      Log.w('Supabase not initialized', label: _label);
      return SupabaseAuthState(status: SupabaseAuthStatus.unauthenticated);
    }

    _supabase = SupabaseInitService.client;
    _init();

    // Check if already authenticated
    final session = _supabase.auth.currentSession;
    if (session != null) {
      return SupabaseAuthState(
        status: SupabaseAuthStatus.authenticated,
        user: _supabase.auth.currentUser,
        session: session,
      );
    }

    return SupabaseAuthState(status: SupabaseAuthStatus.unauthenticated);
  }

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      Log.d('Auth state changed: $event', label: _label);

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          state = state.copyWith(
            status: SupabaseAuthStatus.authenticated,
            user: session?.user,
            session: session,
            error: null,
          );
          Log.i('User authenticated: ${session?.user.id}', label: _label);
          break;

        case AuthChangeEvent.signedOut:
          state = state.copyWith(
            status: SupabaseAuthStatus.unauthenticated,
            user: null,
            session: null,
            error: null,
          );
          Log.i('User signed out', label: _label);
          break;

        case AuthChangeEvent.userUpdated:
          state = state.copyWith(
            user: session?.user,
            session: session,
          );
          Log.d('User updated', label: _label);
          break;

        case AuthChangeEvent.passwordRecovery:
          Log.d('Password recovery event', label: _label);
          break;

        default:
          break;
      }
    });
  }

  /// Sign in with Google using native SDK (google_sign_in 7.x).
  /// Shows native Google account picker popup, then exchanges ID token with Supabase.
  Future<SupabaseAuthState> signInWithGoogle() async {
    try {
      state = state.copyWith(status: SupabaseAuthStatus.loading);

      // google_sign_in 7.x uses singleton pattern
      final googleSignIn = GoogleSignIn.instance;

      // Sign out first to show account picker
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // Show native Google account picker popup
      final googleUser = await googleSignIn.authenticate();

      // google_sign_in 7.x: .authentication is sync, no accessToken
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        Log.e('Failed to get Google ID token', label: _label);
        state = state.copyWith(
          status: SupabaseAuthStatus.unauthenticated,
          error: 'Không thể lấy token từ Google',
        );
        return state;
      }

      Log.d('Got Google ID token, exchanging with Supabase...', label: _label);

      // Exchange Google ID token with Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.session == null) {
        Log.e('Supabase signInWithIdToken returned no session', label: _label);
        state = state.copyWith(
          status: SupabaseAuthStatus.unauthenticated,
          error: 'Đăng nhập thất bại',
        );
        return state;
      }

      state = state.copyWith(
        status: SupabaseAuthStatus.authenticated,
        user: response.user,
        session: response.session,
        error: null,
      );

      Log.i('Google sign in successful: ${response.user?.id}', label: _label);
      return state;
    } on AuthException catch (e) {
      Log.e('Google sign in failed: ${e.message}', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.message),
      );
      return state;
    } catch (e) {
      Log.e('Google sign in error: $e', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: e.toString(),
      );
      return state;
    }
  }

  /// Sign in with email and password.
  Future<SupabaseAuthState> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: SupabaseAuthStatus.loading);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        state = state.copyWith(
          status: SupabaseAuthStatus.unauthenticated,
          error: 'Login failed',
        );
        return state;
      }

      state = state.copyWith(
        status: SupabaseAuthStatus.authenticated,
        user: response.user,
        session: response.session,
        error: null,
      );

      Log.i('Email sign in successful: ${response.user?.id}', label: _label);
      return state;
    } on AuthException catch (e) {
      Log.e('Email sign in failed: ${e.message}', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.message),
      );
      return state;
    } catch (e) {
      Log.e('Email sign in error: $e', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: e.toString(),
      );
      return state;
    }
  }

  /// Sign up with email and password.
  Future<SupabaseAuthState> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      state = state.copyWith(status: SupabaseAuthStatus.loading);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user == null) {
        state = state.copyWith(
          status: SupabaseAuthStatus.unauthenticated,
          error: 'Signup failed',
        );
        return state;
      }

      // Check if email confirmation is required
      final requiresConfirmation = response.session == null;

      state = state.copyWith(
        status: requiresConfirmation
            ? SupabaseAuthStatus.unauthenticated
            : SupabaseAuthStatus.authenticated,
        user: response.user,
        session: response.session,
        isNew: true,
        requiresEmailConfirmation: requiresConfirmation,
        error: null,
      );

      if (requiresConfirmation) {
        Log.i('Email confirmation required for: ${response.user?.id}', label: _label);
      } else {
        Log.i('Email sign up successful: ${response.user?.id}', label: _label);
      }

      return state;
    } on AuthException catch (e) {
      Log.e('Email sign up failed: ${e.message}', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.message),
      );
      return state;
    } catch (e) {
      Log.e('Email sign up error: $e', label: _label);
      state = state.copyWith(
        status: SupabaseAuthStatus.unauthenticated,
        error: e.toString(),
      );
      return state;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      state = SupabaseAuthState(status: SupabaseAuthStatus.unauthenticated);
      Log.i('Sign out successful', label: _label);
    } catch (e) {
      Log.e('Sign out error: $e', label: _label);
    }
  }

  /// Reset password for the given email.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Log.i('Password reset email sent to $email', label: _label);
    } on AuthException catch (e) {
      Log.e('Password reset failed: ${e.message}', label: _label);
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Get the current access token for API calls.
  String? getAccessToken() {
    return _supabase.auth.currentSession?.accessToken;
  }

  /// Refresh the current session.
  Future<void> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        state = state.copyWith(
          session: response.session,
          user: response.user,
        );
        Log.d('Session refreshed', label: _label);
      }
    } catch (e) {
      Log.e('Session refresh failed: $e', label: _label);
    }
  }

  /// Get user-friendly error message.
  String _getAuthErrorMessage(String message) {
    final lowered = message.toLowerCase();

    if (lowered.contains('invalid login credentials') ||
        lowered.contains('invalid email or password')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (lowered.contains('email not confirmed')) {
      return 'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư';
    }
    if (lowered.contains('user already registered')) {
      return 'Email đã được sử dụng';
    }
    if (lowered.contains('weak password') || lowered.contains('password should be')) {
      return 'Mật khẩu quá yếu (cần ít nhất 6 ký tự)';
    }
    if (lowered.contains('rate limit') || lowered.contains('too many requests')) {
      return 'Quá nhiều lần thử. Vui lòng đợi một lát';
    }
    if (lowered.contains('network')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
    }

    return message;
  }

  /// Update user profile (display name and avatar URL) in Supabase.
  /// Updates user metadata which will be synced across sessions.
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) {
        updates['full_name'] = fullName;
      }
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      if (updates.isEmpty) {
        Log.w('No profile updates to apply', label: _label);
        return;
      }

      Log.i('Updating user profile: $updates', label: _label);

      // Update Supabase user metadata
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );

      if (response.user == null) {
        throw Exception('Failed to update profile');
      }

      // Update state with new user data
      state = state.copyWith(
        user: response.user,
      );

      Log.i('✅ Profile updated successfully', label: _label);
    } catch (e, stack) {
      Log.e('Failed to update profile: $e\nStack trace: $stack', label: _label);
      rethrow;
    }
  }

  // Convenience getters
  bool get isAuthenticated => state.isAuthenticated;
  User? get currentUser => state.user;
  String? get userId => state.userId;
  Session? get currentSession => state.session;
}

// ============================================================================
// Riverpod Providers
// ============================================================================

/// Provider for SupabaseClient instance.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseInitService.isInitialized) return null;
  return SupabaseInitService.client;
});

/// Main auth service provider.
final supabaseAuthServiceProvider = NotifierProvider<SupabaseAuthService, SupabaseAuthState>(
  SupabaseAuthService.new,
);

/// Current Supabase user.
final supabaseCurrentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseAuthServiceProvider).user;
});

/// Whether user is authenticated via Supabase.
final isSupabaseAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(supabaseAuthServiceProvider).isAuthenticated;
});

/// Current user ID from Supabase.
final supabaseUserIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseAuthServiceProvider).userId;
});

/// Stream of Supabase auth state changes.
final supabaseAuthStateStreamProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseInitService.isInitialized) {
    return const Stream.empty();
  }
  return SupabaseInitService.client.auth.onAuthStateChange;
});
