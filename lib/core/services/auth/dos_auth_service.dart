import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/auth/dos_me_api_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class DOSAuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final String? joyUid;
  final Map<String, dynamic>? customClaims;

  DOSAuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.joyUid,
    this.customClaims,
  });

  DOSAuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    String? joyUid,
    Map<String, dynamic>? customClaims,
  }) {
    return DOSAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      joyUid: joyUid ?? this.joyUid,
      customClaims: customClaims ?? this.customClaims,
    );
  }
}

class DOSAuthService extends Notifier<DOSAuthState> {
  late final FirebaseAuth _auth;
  final DosMeApiService _dosMeApi = DosMeApiService();

  @override
  DOSAuthState build() {
    _auth = ref.watch(dosAuthProvider);
    _init();
    return DOSAuthState();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _updateAuthState(user);
      } else {
        state = DOSAuthState(
          status: AuthStatus.unauthenticated,
        );
        Log.i('User unauthenticated', label: 'dos-auth');
      }
    });
  }

  Future<void> _updateAuthState(User user) async {
    try {
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims ?? {};
      final idToken = idTokenResult.token;

      final joyUid = claims['joy_uid'] as String?;

      // Sync with DOS-Me API (fire and forget, don't block auth)
      if (idToken != null) {
        _syncWithDosMeApi(idToken);
      }

      state = DOSAuthState(
        status: AuthStatus.authenticated,
        user: user,
        joyUid: joyUid ?? user.uid,
        customClaims: claims,
      );

      Log.i('User authenticated: ${user.uid} [JoyUID: ${joyUid ?? user.uid}]', label: 'dos-auth');
    } catch (e) {
      Log.e('Failed to get ID token claims: $e', label: 'dos-auth');
      state = DOSAuthState(
        status: AuthStatus.authenticated,
        user: user,
        joyUid: user.uid,
      );
    }
  }

  /// Sync user data with DOS-Me API and sign in with custom token
  Future<void> _syncWithDosMeApi(String idToken) async {
    try {
      final result = await _dosMeApi.login(idToken);
      if (result.success) {
        Log.i('DOS-Me sync successful: ${result.user?.uid}', label: 'dos-auth');

        // Sign in with custom token if returned (updates claims)
        if (result.customToken != null) {
          try {
            await _auth.signInWithCustomToken(result.customToken!);
            Log.i('Signed in with DOS-Me custom token', label: 'dos-auth');
          } catch (e) {
            Log.w('Failed to sign in with custom token: $e', label: 'dos-auth');
            // Continue anyway, initial sign-in is still valid
          }
        }
      } else {
        Log.w('DOS-Me sync failed: ${result.message}', label: 'dos-auth');
      }
    } catch (e) {
      Log.e('DOS-Me sync error: $e', label: 'dos-auth');
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateAuthState(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Sign in failed: ${e.code}', label: 'dos-auth');
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      if (_auth.currentUser != null) {
        await _updateAuthState(_auth.currentUser!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Sign up failed: ${e.code}', label: 'dos-auth');
    }
  }

  Future<void> signInAnonymously() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final credential = await _auth.signInAnonymously();

      if (credential.user != null) {
        await _updateAuthState(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Anonymous sign in failed: ${e.code}', label: 'dos-auth');
    }
  }

  Future<void> signInWithCredential(AuthCredential credential) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _updateAuthState(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Credential sign in failed: ${e.code}', label: 'dos-auth');
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await user.getIdToken(forceRefresh);
    } catch (e) {
      Log.e('Failed to get ID token: $e', label: 'dos-auth');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getIdTokenClaims({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final idTokenResult = await user.getIdTokenResult(forceRefresh);
      return idTokenResult.claims;
    } catch (e) {
      Log.e('Failed to get ID token claims: $e', label: 'dos-auth');
      return null;
    }
  }

  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _updateAuthState(user);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = DOSAuthState(
        status: AuthStatus.unauthenticated,
      );
      Log.i('Sign out successful', label: 'dos-auth');
    } catch (e) {
      Log.e('Sign out failed: $e', label: 'dos-auth');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Log.i('Password reset email sent to $email', label: 'dos-auth');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _getAuthErrorMessage(e.code));
      Log.e('Password reset failed: ${e.code}', label: 'dos-auth');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        state = DOSAuthState(
          status: AuthStatus.unauthenticated,
        );
        Log.i('Account deleted successfully', label: 'dos-auth');
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _getAuthErrorMessage(e.code));
      Log.e('Account deletion failed: ${e.code}', label: 'dos-auth');
      rethrow;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'requires-recent-login':
        return 'Please login again to complete this action.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  bool get isAuthenticated => state.status == AuthStatus.authenticated;
  User? get currentUser => state.user;
  String? get userId => state.joyUid ?? state.user?.uid;
  String? get firebaseUid => state.user?.uid;
  String? get joyUid => state.joyUid;
}

// Providers
final dosAuthProvider = Provider<FirebaseAuth>((ref) {
  // Use DOS-Me Firebase app for authentication (matches google-services.json)
  final dosmeApp = FirebaseInitService.dosmeApp;
  if (dosmeApp == null) {
    throw Exception('DOS-Me Firebase not initialized');
  }
  return FirebaseAuth.instanceFor(app: dosmeApp);
});

final dosAuthServiceProvider = NotifierProvider<DOSAuthService, DOSAuthState>(
  DOSAuthService.new,
);

final currentDOSUserProvider = Provider<User?>((ref) {
  return ref.watch(dosAuthServiceProvider).user;
});

final isDOSAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(dosAuthServiceProvider).status == AuthStatus.authenticated;
});

final dosUserContextProvider = Provider<Map<String, dynamic>>((ref) {
  final authState = ref.watch(dosAuthServiceProvider);
  return {
    'joy_uid': authState.joyUid,
    'firebase_uid': authState.user?.uid,
    'email': authState.user?.email,
    'display_name': authState.user?.displayName,
    'claims': authState.customClaims,
  };
});