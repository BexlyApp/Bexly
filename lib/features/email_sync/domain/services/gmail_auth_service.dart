import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Result of Gmail connection attempt
sealed class GmailConnectResult {
  const GmailConnectResult();
}

class GmailConnectSuccess extends GmailConnectResult {
  final String email;

  const GmailConnectSuccess({
    required this.email,
  });
}

class GmailConnectCancelled extends GmailConnectResult {
  const GmailConnectCancelled();
}

class GmailConnectError extends GmailConnectResult {
  final String message;
  final Object? error;

  const GmailConnectError(this.message, [this.error]);
}

/// Service for Gmail OAuth authentication for email sync feature.
///
/// This service handles:
/// - Gmail OAuth with gmail.readonly scope
/// - Disconnecting Gmail access
///
/// Note: google_sign_in 7.x removed isSignedIn() and currentUser getter.
/// We track the connected email separately in local storage/Firestore.
class GmailAuthService {
  static const _label = 'GmailAuth';

  // Gmail readonly scope - we only need to read emails, not modify
  static const List<String> _gmailScopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  // GoogleSignIn instance for Gmail (uses singleton pattern in 7.x)
  GoogleSignIn get _signIn => GoogleSignIn.instance;

  /// Connect Gmail account for email sync.
  ///
  /// This will:
  /// 1. Show Google sign-in with gmail.readonly scope
  /// 2. Return the email on success
  Future<GmailConnectResult> connectGmail() async {
    try {
      Log.i('Starting Gmail connection for email sync', label: _label);

      // Sign out first to ensure clean state
      try {
        await _signIn.signOut();
      } catch (_) {}

      // Authenticate with Google using gmail.readonly scope
      final googleUser = await _signIn.authenticate(
        scopeHint: _gmailScopes,
      );

      Log.i('Gmail connected: ${googleUser.email}', label: _label);

      return GmailConnectSuccess(
        email: googleUser.email,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        Log.i('Gmail connection cancelled by user', label: _label);
        return const GmailConnectCancelled();
      }
      Log.e('Gmail connection failed: [${e.code}] ${e.message}', label: _label);
      return GmailConnectError('[${e.code}] ${e.message ?? "Unknown error"}', e);
    } catch (e) {
      Log.e('Gmail connection failed: $e', label: _label);
      return GmailConnectError(e.toString(), e);
    }
  }

  /// Disconnect Gmail account.
  ///
  /// This will:
  /// 1. Sign out from Google
  /// 2. Revoke the OAuth token (if possible)
  Future<void> disconnectGmail() async {
    try {
      Log.i('Disconnecting Gmail', label: _label);

      // Disconnect will also revoke the token
      await _signIn.disconnect();

      Log.i('Gmail disconnected successfully', label: _label);
    } catch (e) {
      Log.e('Gmail disconnect failed: $e', label: _label);
      // Even if disconnect fails, try to sign out
      try {
        await _signIn.signOut();
      } catch (_) {}
    }
  }

  /// Try to authenticate silently (lightweight auth).
  /// Returns the email if successful, null otherwise.
  ///
  /// Note: In google_sign_in 7.x, this replaces signInSilently().
  Future<String?> tryLightweightAuth() async {
    try {
      final result = await _signIn.attemptLightweightAuthentication();
      return result?.email;
    } catch (_) {
      return null;
    }
  }

  /// Get the current user's Firebase UID (for storing email sync settings).
  String? getCurrentUserId() {
    final bexlyApp = FirebaseInitService.bexlyApp;
    if (bexlyApp == null) return null;

    final auth = FirebaseAuth.instanceFor(app: bexlyApp);
    return auth.currentUser?.uid;
  }
}
