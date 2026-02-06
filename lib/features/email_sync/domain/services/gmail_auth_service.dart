import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';

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

/// Indicates user needs to complete OAuth in browser (dos.me ID mode)
class GmailConnectPendingBrowser extends GmailConnectResult {
  final String connectUrl;

  const GmailConnectPendingBrowser({required this.connectUrl});
}

class GmailConnectError extends GmailConnectResult {
  final String message;
  final Object? error;

  const GmailConnectError(this.message, [this.error]);
}

/// Result with auth code for server exchange (dos.me ID mode)
class GmailConnectWithAuthCode extends GmailConnectResult {
  final String email;
  final String authCode;

  const GmailConnectWithAuthCode({
    required this.email,
    required this.authCode,
  });
}

/// Service for Gmail OAuth authentication for email sync feature.
///
/// This service handles:
/// - Gmail OAuth with gmail.readonly scope
/// - Disconnecting Gmail access
///
/// Note: google_sign_in 7.x removed isSignedIn() and currentUser getter.
/// We track the connected email separately in local storage.
class GmailAuthService {
  static const _label = 'GmailAuth';

  // Gmail readonly scope - we only need to read emails, not modify
  static const List<String> _gmailScopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  // GoogleSignIn instance for Gmail (uses singleton pattern in 7.x)
  GoogleSignIn get _signIn => GoogleSignIn.instance;

  // Reference to GmailApiService for caching token
  GmailApiService? _gmailApiService;

  /// Set the GmailApiService reference for token caching
  void setGmailApiService(GmailApiService service) {
    _gmailApiService = service;
  }

  /// Connect Gmail account for email sync.
  ///
  /// This will:
  /// 1. Show Google sign-in with gmail.readonly scope
  /// 2. Authorize scopes and cache access token
  /// 3. Return the email on success
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

      Log.i('Gmail authenticated: ${googleUser.email}', label: _label);

      // Now authorize scopes to get access token
      // This ensures we have the token cached for later use
      final authorization = await googleUser.authorizationClient.authorizeScopes(_gmailScopes);

      // Cache the token in GmailApiService if available
      if (_gmailApiService != null) {
        _gmailApiService!.cacheAccessToken(authorization.accessToken);
        Log.i('Access token cached in GmailApiService', label: _label);
      }

      Log.i('Gmail connected with scopes: ${googleUser.email}', label: _label);

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

  /// Connect Gmail and get authorization code for server exchange.
  ///
  /// This is used for dos.me ID mode where:
  /// 1. Native Google Sign In gets auth code via authorizeServer()
  /// 2. Auth code is sent to dos.me ID for exchange
  /// 3. dos.me ID stores refresh token securely
  ///
  /// Requires serverClientId to be configured in GoogleSignIn.
  ///
  /// Note: We intentionally DO NOT sign out before authenticate because:
  /// - We want to keep the local session as a fallback
  /// - If dos.me ID token refresh fails, local session can still work
  /// - authorizeServer() will still return a fresh auth code
  Future<GmailConnectResult> connectGmailWithAuthCode() async {
    try {
      Log.i('Starting Gmail connection with auth code for dos.me ID', label: _label);

      // Authenticate with Google (don't sign out - keep local session as fallback)
      final googleUser = await _signIn.authenticate(
        scopeHint: _gmailScopes,
      );

      Log.i('Gmail authenticated: ${googleUser.email}', label: _label);

      // Request server authorization code using authorizeServer()
      // This is the google_sign_in 7.x way to get serverAuthCode
      Log.i('Requesting server authorization code...', label: _label);
      final serverAuth = await googleUser.authorizationClient.authorizeServer(_gmailScopes);

      if (serverAuth != null && serverAuth.serverAuthCode.isNotEmpty) {
        Log.i('Got server auth code for dos.me ID exchange', label: _label);

        // Also get local access token as fallback in case dos.me exchange fails
        try {
          final authorization = await googleUser.authorizationClient.authorizeScopes(_gmailScopes);
          if (_gmailApiService != null) {
            _gmailApiService!.cacheAccessToken(authorization.accessToken);
            Log.i('Access token cached as fallback', label: _label);
          }
        } catch (e) {
          Log.w('Could not cache fallback access token: $e', label: _label);
        }

        return GmailConnectWithAuthCode(
          email: googleUser.email,
          authCode: serverAuth.serverAuthCode,
        );
      }

      // No serverAuthCode - serverClientId might not be configured
      // Fall back to getting authorization which gives access token
      Log.w('No serverAuthCode returned - serverClientId may not be configured', label: _label);
      Log.w('Falling back to access token flow', label: _label);

      final authorization = await googleUser.authorizationClient.authorizeScopes(_gmailScopes);

      // Cache the token in GmailApiService if available
      if (_gmailApiService != null) {
        _gmailApiService!.cacheAccessToken(authorization.accessToken);
      }

      return GmailConnectSuccess(email: googleUser.email);
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

  /// Get the current user's ID (for storing email sync settings).
  /// Supports both Supabase and Firebase authentication.
  String? getCurrentUserId() {
    // Try Supabase first (preferred)
    if (SupabaseInitService.isInitialized) {
      final supabaseUser = SupabaseInitService.currentUser;
      if (supabaseUser != null) {
        return supabaseUser.id;
      }
    }

    // No Supabase user - return null
    return null;
  }
}
