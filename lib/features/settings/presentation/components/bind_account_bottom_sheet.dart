import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';
import 'package:bexly/core/services/sync/sync_trigger_service.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart' as local_auth;

class BindAccountBottomSheet extends ConsumerStatefulWidget {
  const BindAccountBottomSheet({super.key});

  @override
  ConsumerState<BindAccountBottomSheet> createState() => _BindAccountBottomSheetState();
}

class _BindAccountBottomSheetState extends ConsumerState<BindAccountBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In was cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Missing ID token from Google. Please try again.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final bexlyApp = FirebaseInitService.bexlyApp;
      if (bexlyApp == null) {
        throw Exception('Bexly Firebase not initialized');
      }

      final bexlyAuth = FirebaseAuth.instanceFor(app: bexlyApp);
      await bexlyAuth.signInWithCredential(credential);

      Log.i('Firebase authentication successful', label: 'auth');

      // Sync user profile
      final firebaseUser = bexlyAuth.currentUser;
      if (firebaseUser != null) {
        final authProvider = ref.read(local_auth.authStateProvider.notifier);
        final currentUser = authProvider.getUser();

        authProvider.setUser(currentUser.copyWith(
          name: firebaseUser.displayName ?? currentUser.name,
          email: firebaseUser.email ?? currentUser.email,
          profilePicture: firebaseUser.photoURL ?? currentUser.profilePicture,
        ));
      }

      // Trigger initial sync
      if (mounted) {
        final syncService = ref.read(cloudSyncServiceProvider);
        final localDb = ref.read(databaseProvider);
        final userId = bexlyAuth.currentUser?.uid;

        if (userId != null) {
          await SyncTriggerService.triggerInitialSyncIfNeeded(
            syncService,
            context: context,
            localDb: localDb,
            userId: userId,
            ref: ref,
          );
        }
      }

      if (mounted) {
        context.pop(); // Close bottom sheet
        context.go('/'); // Navigate to main
      }
    } on PlatformException catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Google Login Failed'),
          description: Text('[${e.code}] ${e.message ?? "Unknown error"}'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Google Login Failed'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          final OAuthCredential credential = FacebookAuthProvider.credential(
            accessToken.tokenString,
          );

          final bexlyApp = FirebaseInitService.bexlyApp;
          if (bexlyApp == null) {
            throw Exception('Bexly Firebase not initialized');
          }

          final bexlyAuth = FirebaseAuth.instanceFor(app: bexlyApp);
          await bexlyAuth.signInWithCredential(credential);

          // Sync user profile
          final firebaseUser = bexlyAuth.currentUser;
          if (firebaseUser != null) {
            final authProvider = ref.read(local_auth.authStateProvider.notifier);
            final currentUser = authProvider.getUser();

            authProvider.setUser(currentUser.copyWith(
              name: firebaseUser.displayName ?? currentUser.name,
              email: firebaseUser.email ?? currentUser.email,
              profilePicture: firebaseUser.photoURL ?? currentUser.profilePicture,
            ));
          }

          // Trigger initial sync
          if (mounted) {
            final syncService = ref.read(cloudSyncServiceProvider);
            final localDb = ref.read(databaseProvider);
            final userId = bexlyAuth.currentUser?.uid;

            if (userId != null) {
              await SyncTriggerService.triggerInitialSyncIfNeeded(
                syncService,
                context: context,
                localDb: localDb,
                userId: userId,
                ref: ref,
              );
            }
          }

          if (mounted) {
            context.pop();
            context.go('/');
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled
      } else if (result.status == LoginStatus.failed) {
        throw Exception('Facebook Sign In failed: ${result.message}');
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Facebook Login Failed'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.DOS.Service',
          redirectUri: Uri.parse('https://dos-me.firebaseapp.com/__/auth/handler'),
        ),
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final bexlyApp = FirebaseInitService.bexlyApp;
      if (bexlyApp == null) {
        throw Exception('Bexly Firebase not initialized');
      }

      final bexlyAuth = FirebaseAuth.instanceFor(app: bexlyApp);
      await bexlyAuth.signInWithCredential(authCredential);

      // Sync user profile
      final firebaseUser = bexlyAuth.currentUser;
      if (firebaseUser != null) {
        final authProvider = ref.read(local_auth.authStateProvider.notifier);
        final currentUser = authProvider.getUser();

        String? displayName = firebaseUser.displayName;
        if (displayName == null && credential.givenName != null) {
          displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        }

        authProvider.setUser(currentUser.copyWith(
          name: displayName ?? currentUser.name,
          email: firebaseUser.email ?? credential.email ?? currentUser.email,
          profilePicture: firebaseUser.photoURL ?? currentUser.profilePicture,
        ));
      }

      // Trigger initial sync
      if (mounted) {
        final syncService = ref.read(cloudSyncServiceProvider);
        final localDb = ref.read(databaseProvider);
        final userId = bexlyAuth.currentUser?.uid;

        if (userId != null) {
          await SyncTriggerService.triggerInitialSyncIfNeeded(
            syncService,
            context: context,
            localDb: localDb,
            userId: userId,
            ref: ref,
          );
        }
      }

      if (mounted) {
        context.pop();
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Apple sign in failed';
        if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }

        toastification.show(
          context: context,
          title: const Text('Apple Login Failed'),
          description: Text(errorMessage),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bind Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(8),
          Text(
            'Link your account to sync data across devices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          // Google Sign In
          FilledButton.tonalIcon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: const FaIcon(FontAwesomeIcons.google, size: 20),
            label: const Text('Continue with Google'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const Gap(12),
          // Facebook Sign In
          FilledButton.tonalIcon(
            onPressed: _isLoading ? null : _handleFacebookSignIn,
            icon: const FaIcon(
              FontAwesomeIcons.facebookF,
              size: 20,
              color: Color(0xFF1877F2),
            ),
            label: const Text('Continue with Facebook'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const Gap(12),
          // Apple Sign In
          FilledButton.tonalIcon(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: FaIcon(
              FontAwesomeIcons.apple,
              size: 22,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            label: const Text('Continue with Apple'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const Gap(24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
