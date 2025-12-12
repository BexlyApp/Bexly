import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/firebase_init_service.dart';

// Provider for Bexly Firebase Auth instance
final bexlyAuthProvider = Provider<FirebaseAuth>((ref) {
  final bexlyApp = FirebaseInitService.bexlyApp;
  if (bexlyApp == null) {
    throw Exception('Bexly Firebase not initialized');
  }
  return FirebaseAuth.instanceFor(app: bexlyApp);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(bexlyAuthProvider);
  return auth.authStateChanges();
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
  final auth = ref.watch(bexlyAuthProvider);
  final user = auth.currentUser;
  if (user == null) return null;

  final idTokenResult = await user.getIdTokenResult();
  return idTokenResult.claims;
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

// Guest mode tracking using NotifierProvider
class GuestModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // User is in guest mode when not authenticated
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    return !isAuthenticated;
  }

  void setGuestMode(bool value) => state = value;
}

final isGuestModeProvider = NotifierProvider<GuestModeNotifier, bool>(
  GuestModeNotifier.new,
);

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