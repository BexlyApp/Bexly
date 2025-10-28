import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/auth/dos_me_auth_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';
import 'package:bexly/core/services/sync/sync_trigger_service.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final obscurePassword = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final authService = ref.read(dosmeAuthServiceProvider);
    final packageInfoService = ref.watch(packageInfoServiceProvider);

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        await authService.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
          tenantType: TenantType.public,
        );

        if (context.mounted) {
          context.go('/');
        }
      } catch (e) {
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Login Failed'),
            description: Text(e.toString()),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSkip() async {
      // Save skip preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSkippedAuth', true);

      // Set guest mode state
      ref.read(isGuestModeProvider.notifier).state = true;

      if (context.mounted) {
        // Navigate to onboarding screen for initial wallet setup
        context.go('/onboarding');
      }
    }

    Future<void> handleGoogleSignIn() async {
      isLoading.value = true;
      try {
        // Auto-detect OAuth client from google-services.json
        // Android: Uses android_client_info with matching SHA-1 (client_type: 1)
        // iOS: Needs explicit clientId
        final googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS
              ? '368090586626-po4m5b4jbtvpfg7ubv622qq3phiq7pmp.apps.googleusercontent.com'
              : null,
        );
        // Sign out any cached session to force re-consent/account chooser on first attempt
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google Sign In was cancelled by user');
        }

        debugPrint('Google Sign In successful for: ${googleUser.email}');

        // Get authentication tokens
        final googleAuth = await googleUser.authentication;

        // Create Firebase credential (require idToken; accessToken optional but helpful)
        if (googleAuth.idToken == null) {
          throw Exception('Missing ID token from Google. Please try again.');
        }
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        // Sign in to Firebase using DOS-Me app
        final dosmeApp = FirebaseInitService.dosmeApp;
        if (dosmeApp == null) {
          throw Exception('DOS-Me Firebase not initialized');
        }

        final dosmeAuth = FirebaseAuth.instanceFor(app: dosmeApp);
        await dosmeAuth.signInWithCredential(credential);

        debugPrint('Firebase authentication successful');

        // Trigger initial sync if first time login
        if (context.mounted) {
          final syncService = ref.read(cloudSyncServiceProvider);
          final localDb = ref.read(databaseProvider);
          final userId = dosmeAuth.currentUser?.uid;

          if (userId != null) {
            await SyncTriggerService.triggerInitialSyncIfNeeded(
              syncService,
              context: context,
              localDb: localDb,
              userId: userId,
            );
          }
        }

        if (context.mounted) {
          context.go('/');
        }
      } on PlatformException catch (e) {
        debugPrint('Google Sign In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
        if (context.mounted) {
          final code = e.code;
          String message = e.message ?? 'Google Sign-In failed';
          if (code == 'sign_in_failed' && (message.contains('10') || (e.details?.toString().contains('10') ?? false))) {
            message = 'Configuration error (code 10). Kiểm tra SHA-1/SHA-256 và OAuth client.';
          }
          toastification.show(
            context: context,
            title: const Text('Google Login Failed'),
            description: Text('[$code] $message'),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        debugPrint('Google Sign In Error: $e');
        if (context.mounted) {
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
        isLoading.value = false;
      }
    }

    Future<void> handleFacebookSignIn() async {
      isLoading.value = true;
      try {
        // Facebook Sign In using Firebase Auth
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (result.status == LoginStatus.success) {
          // Get the access token
          final AccessToken? accessToken = result.accessToken;

          if (accessToken != null) {
            debugPrint('Facebook Sign In successful');

            // Create a credential from the access token
            final OAuthCredential credential = FacebookAuthProvider.credential(
              accessToken.tokenString,
            );

            // Sign in to Firebase using DOS-Me app
            final dosmeApp = FirebaseInitService.dosmeApp;
            if (dosmeApp == null) {
              throw Exception('DOS-Me Firebase not initialized');
            }

            final dosmeAuth = FirebaseAuth.instanceFor(app: dosmeApp);
            await dosmeAuth.signInWithCredential(credential);

            debugPrint('Firebase authentication with Facebook successful');

            // Trigger initial sync if first time login
            if (context.mounted) {
              final syncService = ref.read(cloudSyncServiceProvider);
              final localDb = ref.read(databaseProvider);
              final userId = dosmeAuth.currentUser?.uid;

              if (userId != null) {
                await SyncTriggerService.triggerInitialSyncIfNeeded(
                  syncService,
                  context: context,
                  localDb: localDb,
                  userId: userId,
                );
              }
            }

            if (context.mounted) {
              context.go('/');
            }
          }
        } else if (result.status == LoginStatus.cancelled) {
          debugPrint('Facebook Sign In cancelled by user');
        } else if (result.status == LoginStatus.failed) {
          throw Exception('Facebook Sign In failed: ${result.message}');
        }
      } catch (e) {
        debugPrint('Facebook Sign In Error: $e');
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Facebook Login Failed'),
            description: Text('${e.toString()}'),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleAppleSignIn() async {
      isLoading.value = true;
      try {
        // Request Apple ID credential
        // On Android, this will use web-based authentication
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.DOS.Service', // Service ID from Apple Developer
            redirectUri: Uri.parse(
              'https://dos-me.firebaseapp.com/__/auth/handler', // Firebase auth handler URL
            ),
          ),
        );

        debugPrint('Apple Sign In successful');
        debugPrint('User: ${credential.givenName} ${credential.familyName}');
        debugPrint('Email: ${credential.email}');

        // Create OAuth credential for Firebase
        final oAuthProvider = OAuthProvider('apple.com');
        final authCredential = oAuthProvider.credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );

        // Sign in to Firebase using DOS-Me app
        final dosmeApp = FirebaseInitService.dosmeApp;
        if (dosmeApp == null) {
          throw Exception('DOS-Me Firebase not initialized');
        }

        final dosmeAuth = FirebaseAuth.instanceFor(app: dosmeApp);
        final userCredential = await dosmeAuth.signInWithCredential(authCredential);

        // If this is the first time, save the user info
        if (credential.email != null || credential.givenName != null) {
          // You can save user details to Firestore here if needed
          debugPrint('New Apple user: ${userCredential.user?.uid}');
        }

        debugPrint('Firebase authentication with Apple successful');

        // Trigger initial sync if first time login
        if (context.mounted) {
          final syncService = ref.read(cloudSyncServiceProvider);
          final localDb = ref.read(databaseProvider);
          final userId = dosmeAuth.currentUser?.uid;

          if (userId != null) {
            await SyncTriggerService.triggerInitialSyncIfNeeded(
              syncService,
              context: context,
              localDb: localDb,
              userId: userId,
            );
          }
        }

        if (context.mounted) {
          context.go('/');
        }
      } catch (e) {
        debugPrint('Apple Sign In Error: $e');
        if (context.mounted) {
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
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(24),
                  Text(
                    'Welcome to Bexly',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Sign in to sync across devices',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(32),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword.value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          obscurePassword.value = !obscurePassword.value;
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const Gap(8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const Gap(24),
                  FilledButton(
                    onPressed: isLoading.value ? null : handleLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                  const Gap(12),
                  FilledButton.tonal(
                    onPressed: isLoading.value
                        ? null
                        : () {
                            context.push('/signup');
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                  ),
                  const Gap(24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const Gap(20),
                  // Social Login Buttons
                  Column(
                    children: [
                      Text(
                        'Or continue with',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Sign In
                          FilledButton.tonalIcon(
                            onPressed: isLoading.value ? null : handleGoogleSignIn,
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              size: 18,
                            ),
                            label: const Text('Google'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(100, 48),
                            ),
                          ),
                          const Gap(12),
                          // Facebook Sign In
                          FilledButton.tonalIcon(
                            onPressed: isLoading.value ? null : handleFacebookSignIn,
                            icon: const FaIcon(
                              FontAwesomeIcons.facebookF,
                              size: 18,
                              color: Color(0xFF1877F2),
                            ),
                            label: const Text('Facebook'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(100, 48),
                            ),
                          ),
                          const Gap(12),
                          // Apple Sign In
                          FilledButton.tonalIcon(
                            onPressed: isLoading.value ? null : handleAppleSignIn,
                            icon: FaIcon(
                              FontAwesomeIcons.apple,
                              size: 20,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            label: const Text('Apple'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(100, 48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: isLoading.value ? null : handleSkip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Skip for now',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(24),
                  // Version number
                  Text(
                    'v${packageInfoService.version}+${packageInfoService.buildNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}