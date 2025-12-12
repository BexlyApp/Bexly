import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

enum ZitadelAuthStatus {
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
  final ZitadelAuthStatus status;
  final ZitadelUser? user;
  final String? error;
  final String? accessToken;
  final String? refreshToken;

  ZitadelAuthState({
    this.status = ZitadelAuthStatus.uninitialized,
    this.user,
    this.error,
    this.accessToken,
    this.refreshToken,
  });

  ZitadelAuthState copyWith({
    ZitadelAuthStatus? status,
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

/// Zitadel Auth Service - Placeholder implementation
/// TODO: Add oidc package and implement OIDC flow when needed
class ZitadelAuthService extends Notifier<ZitadelAuthState> {
  @override
  ZitadelAuthState build() {
    Log.i('ZitadelAuthService: Not implemented yet', label: 'zitadel');
    return ZitadelAuthState(status: ZitadelAuthStatus.unauthenticated);
  }

  Future<void> signIn() async {
    Log.w('ZitadelAuthService.signIn: Not implemented', label: 'zitadel');
    state = state.copyWith(
      status: ZitadelAuthStatus.unauthenticated,
      error: 'Zitadel auth not implemented yet',
    );
  }

  Future<void> signOut() async {
    Log.i('ZitadelAuthService.signOut', label: 'zitadel');
    state = ZitadelAuthState(status: ZitadelAuthStatus.unauthenticated);
  }

  Future<void> refreshToken() async {
    Log.w('ZitadelAuthService.refreshToken: Not implemented', label: 'zitadel');
  }

  Future<String?> getValidAccessToken() async {
    return state.accessToken;
  }

  bool get isAuthenticated => state.status == ZitadelAuthStatus.authenticated;
  ZitadelUser? get currentUser => state.user;
  String? get userId => state.user?.id;
}

// Providers
final zitadelAuthServiceProvider = NotifierProvider<ZitadelAuthService, ZitadelAuthState>(
  ZitadelAuthService.new,
);

final currentZitadelUserProvider = Provider<ZitadelUser?>((ref) {
  return ref.watch(zitadelAuthServiceProvider).user;
});

final isZitadelAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(zitadelAuthServiceProvider).status == ZitadelAuthStatus.authenticated;
});

final zitadelAccessTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.read(zitadelAuthServiceProvider.notifier);
  return await authService.getValidAccessToken();
});
