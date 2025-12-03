import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oidc/oidc.dart';
import 'package:bexly/core/utils/logger.dart';

// Zitadel configuration
class ZitadelConfig {
  static const String domain = 'your-instance.zitadel.cloud'; // TODO: Replace with your Zitadel domain
  static const String clientId = 'your-client-id'; // TODO: Replace with your client ID
  static const String redirectUrl = 'com.joy.bexly://callback';
  static const String postLogoutRedirectUrl = 'com.joy.bexly://logout';

  static Uri get issuer => Uri.https(domain, '');
  static List<String> get scopes => ['openid', 'profile', 'email', 'offline_access'];
}

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class ZitadelUser {
  final String id;
  final String? email;
  final String? name;
  final String? picture;
  final Map<String, dynamic> claims;

  ZitadelUser({
    required this.id,
    this.email,
    this.name,
    this.picture,
    required this.claims,
  });

  factory ZitadelUser.fromClaims(Map<String, dynamic> claims) {
    return ZitadelUser(
      id: claims['sub'] as String,
      email: claims['email'] as String?,
      name: claims['name'] as String?,
      picture: claims['picture'] as String?,
      claims: claims,
    );
  }
}

class ZitadelAuthState {
  final AuthStatus status;
  final ZitadelUser? user;
  final String? error;
  final String? accessToken;
  final String? refreshToken;

  ZitadelAuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.accessToken,
    this.refreshToken,
  });

  ZitadelAuthState copyWith({
    AuthStatus? status,
    ZitadelUser? user,
    String? error,
    String? accessToken,
    String? refreshToken,
  }) {
    return ZitadelAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class ZitadelAuthService extends StateNotifier<ZitadelAuthState> {
  OidcPlatformSpecificOptions? _platformSpecificOptions;
  late OidcManager _manager;

  ZitadelAuthService() : super(ZitadelAuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      Log.i('Initializing Zitadel auth', label: 'zitadel');

      // Platform-specific options
      _platformSpecificOptions = OidcPlatformSpecificOptions(
        web: OidcPlatformSpecificOptions_Web(
          clientId: ZitadelConfig.clientId,
          redirectUri: Uri.parse(ZitadelConfig.redirectUrl),
          postLogoutRedirectUri: Uri.parse(ZitadelConfig.postLogoutRedirectUrl),
        ),
      );

      // Initialize OIDC manager
      _manager = OidcManager.lazy(
        discoveryDocumentUri: Uri.parse('${ZitadelConfig.issuer}/.well-known/openid-configuration'),
        clientId: ZitadelConfig.clientId,
        redirectUri: Uri.parse(ZitadelConfig.redirectUrl),
        postLogoutRedirectUri: Uri.parse(ZitadelConfig.postLogoutRedirectUrl),
        scopes: ZitadelConfig.scopes,
        platformSpecificOptions: _platformSpecificOptions,
      );

      // Check for existing session
      await _checkExistingSession();
    } catch (e) {
      Log.e('Failed to initialize Zitadel auth: $e', label: 'zitadel');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Failed to initialize authentication',
      );
    }
  }

  Future<void> _checkExistingSession() async {
    try {
      final credential = await _manager.currentCredential;

      if (credential != null && !credential.isExpired) {
        final userInfo = await _manager.getUserInfo(credential);

        if (userInfo != null) {
          final user = ZitadelUser.fromClaims(userInfo.claims);
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            accessToken: credential.accessToken,
            refreshToken: credential.refreshToken,
          );
          Log.i('Restored session for user: ${user.id}', label: 'zitadel');
        }
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      Log.e('Failed to restore session: $e', label: 'zitadel');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signIn() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      Log.i('Starting Zitadel sign in', label: 'zitadel');

      // Start the authorization flow
      final result = await _manager.loginAuthorizationCodeFlow();

      if (result != null) {
        // Get user info
        final userInfo = await _manager.getUserInfo(result);

        if (userInfo != null) {
          final user = ZitadelUser.fromClaims(userInfo.claims);

          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            error: null,
          );

          Log.i('Sign in successful: ${user.id}', label: 'zitadel');
        } else {
          throw Exception('Failed to get user info');
        }
      } else {
        // User cancelled
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Sign in cancelled',
        );
      }
    } catch (e) {
      Log.e('Sign in failed: $e', label: 'zitadel');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      Log.i('Signing out', label: 'zitadel');

      // Perform logout
      await _manager.logout();

      state = ZitadelAuthState(status: AuthStatus.unauthenticated);

      Log.i('Sign out successful', label: 'zitadel');
    } catch (e) {
      Log.e('Sign out failed: $e', label: 'zitadel');
      // Even if logout fails, clear local state
      state = ZitadelAuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> refreshToken() async {
    try {
      Log.i('Refreshing token', label: 'zitadel');

      final credential = await _manager.currentCredential;

      if (credential != null && credential.refreshToken != null) {
        final newCredential = await _manager.refreshToken(credential.refreshToken!);

        if (newCredential != null) {
          state = state.copyWith(
            accessToken: newCredential.accessToken,
            refreshToken: newCredential.refreshToken,
          );

          Log.i('Token refreshed successfully', label: 'zitadel');
        }
      }
    } catch (e) {
      Log.e('Token refresh failed: $e', label: 'zitadel');
      // If refresh fails, user needs to sign in again
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Session expired. Please sign in again.',
      );
    }
  }

  Future<String?> getValidAccessToken() async {
    try {
      final credential = await _manager.currentCredential;

      if (credential == null) {
        return null;
      }

      // Check if token is expired
      if (credential.isExpired) {
        // Try to refresh
        if (credential.refreshToken != null) {
          await refreshToken();
          return state.accessToken;
        }
        return null;
      }

      return credential.accessToken;
    } catch (e) {
      Log.e('Failed to get valid access token: $e', label: 'zitadel');
      return null;
    }
  }

  bool get isAuthenticated => state.status == AuthStatus.authenticated;
  ZitadelUser? get currentUser => state.user;
  String? get userId => state.user?.id;
}

// Providers
final zitadelAuthServiceProvider = StateNotifierProvider<ZitadelAuthService, ZitadelAuthState>((ref) {
  return ZitadelAuthService();
});

final currentZitadelUserProvider = Provider<ZitadelUser?>((ref) {
  return ref.watch(zitadelAuthServiceProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(zitadelAuthServiceProvider).status == AuthStatus.authenticated;
});

final accessTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.read(zitadelAuthServiceProvider.notifier);
  return await authService.getValidAccessToken();
});