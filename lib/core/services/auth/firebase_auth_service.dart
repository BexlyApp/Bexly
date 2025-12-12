import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/utils/logger.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class FirebaseAuthService extends Notifier<AuthState> {
  late final FirebaseAuth _auth;

  @override
  AuthState build() {
    _auth = ref.watch(firebaseAuthProvider);
    _init();
    return AuthState();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        Log.i('User authenticated: ${user.uid}', label: 'auth');
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
        Log.i('User unauthenticated', label: 'auth');
      }
    });
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

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: credential.user,
        error: null,
      );

      Log.i('Sign in successful: ${credential.user?.uid}', label: 'auth');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Sign in failed: ${e.code}', label: 'auth');
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

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: _auth.currentUser,
        error: null,
      );

      Log.i('Sign up successful: ${credential.user?.uid}', label: 'auth');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Sign up failed: ${e.code}', label: 'auth');
    }
  }

  Future<void> signInAnonymously() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final credential = await _auth.signInAnonymously();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: credential.user,
        error: null,
      );

      Log.i('Anonymous sign in successful: ${credential.user?.uid}', label: 'auth');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _getAuthErrorMessage(e.code),
      );
      Log.e('Anonymous sign in failed: ${e.code}', label: 'auth');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        error: null,
      );
      Log.i('Sign out successful', label: 'auth');
    } catch (e) {
      Log.e('Sign out failed: $e', label: 'auth');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Log.i('Password reset email sent to $email', label: 'auth');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _getAuthErrorMessage(e.code));
      Log.e('Password reset failed: ${e.code}', label: 'auth');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          error: null,
        );
        Log.i('Account deleted successfully', label: 'auth');
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _getAuthErrorMessage(e.code));
      Log.e('Account deletion failed: ${e.code}', label: 'auth');
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
  String? get userId => state.user?.uid;
}

// Providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = NotifierProvider<FirebaseAuthService, AuthState>(
  FirebaseAuthService.new,
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).status == AuthStatus.authenticated;
});