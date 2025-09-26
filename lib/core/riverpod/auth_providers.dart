import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/auth/dos_me_auth_service.dart';

final dosmeAuthServiceProvider = Provider<DOSMeAuthService>((ref) {
  return DOSMeAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(dosmeAuthServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser != null;
});

final userIdProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.uid;
});

final userEmailProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.email;
});

final userDisplayNameProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.displayName;
});

final userPhotoUrlProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.photoURL;
});

final customClaimsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(dosmeAuthServiceProvider);
  return await authService.getCustomClaims();
});

final joyUidProvider = Provider<String?>((ref) {
  final claims = ref.watch(customClaimsProvider);
  return claims.when(
    data: (data) => data?['joy_uid'] as String?,
    loading: () => null,
    error: (_, __) => null,
  );
});

final accountIdProvider = Provider<String?>((ref) {
  final claims = ref.watch(customClaimsProvider);
  return claims.when(
    data: (data) => data?['account_id'] as String?,
    loading: () => null,
    error: (_, __) => null,
  );
});

final tenantIdProvider = Provider<String?>((ref) {
  final claims = ref.watch(customClaimsProvider);
  return claims.when(
    data: (data) => data?['tenant_id'] as String?,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Guest mode tracking
final isGuestModeProvider = StateProvider<bool>((ref) {
  // User is in guest mode when not authenticated
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  return !isAuthenticated;
});

// Provider to check if a feature requires authentication
final requiresAuthProvider = Provider.family<bool, String>((ref, feature) {
  // Define which features require auth
  const authRequiredFeatures = [
    'sync',
    'backup',
    'restore',
    'cloud_sync',
    'multi_device',
  ];

  return authRequiredFeatures.contains(feature);
});