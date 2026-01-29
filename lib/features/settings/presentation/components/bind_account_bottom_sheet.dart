import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';
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
      final supabase = SupabaseInitService.client;

      // Use native Google Sign-In SDK (google_sign_in 7.x)
      final googleSignIn = GoogleSignIn.instance;

      // Sign out first to show account picker
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // Show native Google account picker popup
      Log.i('Showing Google account picker...', label: 'auth');
      final googleUser = await googleSignIn.authenticate();

      // Get ID token (google_sign_in 7.x: .authentication is sync, no accessToken)
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      Log.i('Got Google ID token, exchanging with Supabase...', label: 'auth');

      // Exchange Google ID token with Supabase
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.session == null || response.user == null) {
        throw Exception('Supabase authentication failed');
      }

      final user = response.user!;
      Log.i('Supabase authentication successful: ${user.email}', label: 'auth');

      // Update local user profile
      final authProvider = ref.read(local_auth.authStateProvider.notifier);
      final currentUser = authProvider.getUser();

      authProvider.setUser(currentUser.copyWith(
        name: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name,
        email: user.email ?? currentUser.email,
        profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
      ));

      // TODO: Trigger initial Supabase sync
      // Note: SyncTriggerService still uses Firebase, need to create Supabase version
      // For now, skip initial sync - will be handled by manual sync or realtime
      Log.i('Google login successful, skipping initial sync for now', label: 'auth');

      if (mounted) {
        context.pop(); // Close bottom sheet
        context.go('/'); // Navigate to main
      }
    } on AuthException catch (e) {
      Log.e('Supabase auth error: ${e.message}', label: 'auth');
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Google Login Failed'),
          description: Text('${e.message} (${e.statusCode})'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    } on PlatformException catch (e) {
      Log.e('Platform error: [${e.code}] ${e.message}', label: 'auth');
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
      Log.e('Google sign in error: $e', label: 'auth');
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Google Login Failed'),
          description: Text('Error: $e'),
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
      final supabase = SupabaseInitService.client;

      // Use native Facebook Sign-In SDK
      Log.i('Initiating Facebook login...', label: 'auth');
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login cancelled or failed: ${result.status}');
      }

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      Log.i('Got Facebook access token, exchanging with Supabase...', label: 'auth');

      // Exchange Facebook access token with Supabase
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken,
      );

      if (response.session == null || response.user == null) {
        throw Exception('Supabase authentication failed');
      }

      final user = response.user!;
      Log.i('Supabase authentication successful: ${user.email}', label: 'auth');

      // Update local user profile
      final authProvider = ref.read(local_auth.authStateProvider.notifier);
      final currentUser = authProvider.getUser();

      authProvider.setUser(currentUser.copyWith(
        name: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name,
        email: user.email ?? currentUser.email,
        profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
      ));

      // TODO: Trigger initial Supabase sync (Facebook)
      Log.i('Facebook login successful, skipping initial sync for now', label: 'auth');

      if (mounted) {
        context.pop();
        context.go('/');
      }
    } on AuthException catch (e) {
      Log.e('Supabase auth error: ${e.message}', label: 'auth');
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Facebook Login Failed'),
          description: Text('${e.message} (${e.statusCode})'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Log.e('Facebook sign in error: $e', label: 'auth');
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Facebook Login Failed'),
          description: Text('Error: $e'),
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
      final supabase = SupabaseInitService.client;

      // Use native Apple Sign-In SDK
      Log.i('Initiating Apple Sign In...', label: 'auth');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      Log.i('Got Apple ID token, exchanging with Supabase...', label: 'auth');

      // Exchange Apple ID token with Supabase
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      if (response.session == null || response.user == null) {
        throw Exception('Supabase authentication failed');
      }

      final user = response.user!;
      Log.i('Supabase authentication successful: ${user.email}', label: 'auth');

      // Update local user profile
      final authProvider = ref.read(local_auth.authStateProvider.notifier);
      final currentUser = authProvider.getUser();

      authProvider.setUser(currentUser.copyWith(
        name: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name,
        email: user.email ?? currentUser.email,
        profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
      ));

      // TODO: Trigger initial Supabase sync (Apple)
      Log.i('Apple login successful, skipping initial sync for now', label: 'auth');

      if (mounted) {
        context.pop();
        context.go('/');
      }
    } on AuthException catch (e) {
      Log.e('Supabase auth error: ${e.message}', label: 'auth');
      if (mounted) {
        String errorMessage = e.message;
        if (errorMessage.contains('canceled') || errorMessage.contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }

        toastification.show(
          context: context,
          title: const Text('Apple Login Failed'),
          description: Text('$errorMessage (${e.statusCode})'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Log.e('Apple sign in error: $e', label: 'auth');
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Apple Login Failed'),
          description: Text('Error: $e'),
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
          const Gap(16),
          const Divider(),
          const Gap(8),
          TextButton.icon(
            onPressed: _isLoading ? null : _handleSwitchAccount,
            icon: const Icon(Icons.swap_horiz, size: 20),
            label: const Text('Switch to another account'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwitchAccount() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Switch Account?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            Text(
              'This will delete all your local data and return to the login screen. '
              'Make sure you have synced your data before switching accounts.\n\n'
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Gap(24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            const Gap(12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Switch Account'),
            ),
            const Gap(16),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Sign out from Supabase
        await SupabaseInitService.client.auth.signOut();

        // Sign out from Google
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}

        // Sign out from Facebook
        try {
          await FacebookAuth.instance.logOut();
        } catch (_) {}

        // Clear local database
        final db = ref.read(databaseProvider);
        await db.clearAllDataAndReset();

        if (mounted) {
          context.pop(); // Close bottom sheet
          context.go('/login'); // Navigate to login
        }
      } catch (e) {
        if (mounted) {
          toastification.show(
            context: context,
            title: const Text('Error'),
            description: Text('Failed to switch account: $e'),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
