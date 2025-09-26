import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bexly/core/services/firebase_init_service.dart';

enum TenantType {
  public('public'),
  organization('org');

  final String prefix;
  const TenantType(this.prefix);
}

class DOSMeAuthService {
  FirebaseAuth? _auth;

  DOSMeAuthService() {
    final app = FirebaseInitService.dosmeApp;
    if (app != null) {
      _auth = FirebaseAuth.instanceFor(app: app);
    } else {
      debugPrint('DOS-Me Firebase app not initialized, using default auth');
      _auth = FirebaseAuth.instance; // Fallback to default Firebase app
    }
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  User? get currentUser => _auth?.currentUser;

  String? get currentUserId => _auth?.currentUser?.uid;

  void setTenant(TenantType type, [String? accountId]) {
    if (_auth == null) return;

    if (type == TenantType.public) {
      _auth!.tenantId = 'public';
    } else if (type == TenantType.organization && accountId != null) {
      _auth!.tenantId = 'org_$accountId';
    } else {
      _auth!.tenantId = null;
    }
    debugPrint('Tenant set to: ${_auth!.tenantId}');
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
    TenantType tenantType = TenantType.public,
    String? accountId,
  }) async {
    try {
      setTenant(tenantType, accountId);

      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('User signed in: ${credential.user?.uid}');
      await _extractCustomClaims();

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    TenantType tenantType = TenantType.public,
    String? accountId,
  }) async {
    try {
      setTenant(tenantType, accountId);

      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('User created: ${credential.user?.uid}');
      await _extractCustomClaims();

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth!.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
        debugPrint('Profile updated');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.delete();
        debugPrint('Account deleted');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('Re-authentication required');
        rethrow;
      }
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth?.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('Email verification sent');
      }
    } catch (e) {
      debugPrint('Email verification error: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      final user = _auth?.currentUser;
      await user?.reload();
      debugPrint('User reloaded');
    } catch (e) {
      debugPrint('Reload user error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCustomClaims() async {
    try {
      final user = _auth?.currentUser;
      if (user == null) return null;

      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims;
    } catch (e) {
      debugPrint('Get custom claims error: $e');
      return null;
    }
  }

  Future<void> _extractCustomClaims() async {
    final claims = await getCustomClaims();
    if (claims != null) {
      final joyUid = claims['joy_uid'];
      final accountId = claims['account_id'];
      final tenantId = claims['tenant_id'];

      debugPrint('Custom claims - joy_uid: $joyUid, account_id: $accountId, tenant_id: $tenantId');
    }
  }

  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      final user = _auth?.currentUser;
      if (user == null) return null;

      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('Get ID token error: $e');
      return null;
    }
  }
}