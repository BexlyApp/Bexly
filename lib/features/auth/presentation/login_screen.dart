import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/services/sync/supabase_sync_service.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart';
import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart' as local_auth;
import 'package:bexly/core/components/form_fields/custom_input_border.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final obscurePassword = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final supabase = SupabaseInitService.client;
    final packageInfoService = ref.watch(packageInfoServiceProvider);

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        // Sign in with Supabase
        final response = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.session == null || response.user == null) {
          throw Exception('Login failed - no session created');
        }

        final user = response.user!;
        Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

        // Sync user profile to local database
        final authProvider = ref.read(local_auth.authStateProvider.notifier);
        final currentUser = authProvider.getUser();

        authProvider.setUser(currentUser.copyWith(
          name: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name,
          email: user.email ?? currentUser.email,
          profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
        ));

        Log.i('✅ Synced profile from Supabase Auth (Email)', label: 'auth');

        // Trigger initial Supabase sync to pull data from cloud
        if (context.mounted) {
          try {
            Log.i('🔄 Pulling data from Supabase...', label: 'auth');
            final syncService = ref.read(supabaseSyncServiceProvider);

            // Pull data from cloud (pull-first mode)
            await syncService.performFullSync(pushFirst: false);

            Log.i('✅ Initial sync completed', label: 'auth');
          } catch (e) {
            Log.e('⚠️ Failed to sync from cloud: $e', label: 'auth');
            // Continue anyway - user might be offline or have no cloud data
          }

          // Check if user has any wallets (either from cloud or existing local)
          final db = ref.read(databaseProvider);
          final wallets = await db.walletDao.getAllWallets();

          if (wallets.isEmpty) {
            // No wallets in local DB and cloud - new user, show onboarding
            Log.i('No wallets found, showing onboarding', label: 'auth');
            context.go('/onboarding');
          } else {
            // Has wallets (synced from cloud or existing local) - go to home
            Log.i('Found ${wallets.length} wallets, going to home', label: 'auth');
            context.go('/');
          }
        }
      } on AuthException catch (e) {
        Log.e('Supabase auth error: ${e.message}', label: 'auth');
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Login Failed'),
            description: Text(e.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
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
        // Check if user has wallet
        final db = ref.read(databaseProvider);
        final wallets = await db.walletDao.getAllWallets();

        if (wallets.isEmpty) {
          context.go('/onboarding');
        } else {
          context.go('/');
        }
      }
    }

    Future<void> handleGoogleSignIn() async {
      isLoading.value = true;
      try {
        if (kIsWeb) {
          // Web: Use Supabase signInWithOAuth
          await supabase.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb ? null : 'com.joy.bexly://login-callback/',
          );
        } else {
          // Mobile: Use native Google Sign-In SDK (initialized in main.dart with serverClientId)
          final googleSignIn = GoogleSignIn.instance;

          Log.i('📱 Starting native Google Sign In flow', label: 'auth');
          Log.i('🔑 Expected client ID: ${SupabaseConfig.googleWebClientId}', label: 'auth');
          Log.i('🔍 Debug mode: ${kDebugMode}', label: 'auth');

          // Sign out first to show account picker
          try {
            await googleSignIn.signOut();
            Log.i('🔓 Signed out from previous session', label: 'auth');
          } catch (e) {
            Log.w('Sign out error (safe to ignore): $e', label: 'auth');
          }

          // Show native Google account picker and authenticate
          // Note: authenticate() replaced signIn() in google_sign_in v7.0
          // It throws exception if user cancels (doesn't return null)
          Log.i('👤 Showing Google account picker...', label: 'auth');
          final googleUser = await googleSignIn.authenticate();

          Log.i('✅ User authenticated: ${googleUser.email}', label: 'auth');

          // Get ID token from authentication
          Log.i('🔐 Getting ID token...', label: 'auth');
          final googleAuth = googleUser.authentication;
          final idToken = googleAuth.idToken;

          if (idToken == null) {
            throw Exception('Failed to get Google ID token');
          }
          Log.i('✅ Got ID token (length: ${idToken.length})', label: 'auth');

          // Get access token from authorization client (google_sign_in v7.0 API)
          // Request email scope to get access token (required by Google SDK)
          Log.i('🔐 Getting access token via authorizationClient...', label: 'auth');
          const scopes = ['email'];
          var clientAuth = await googleUser.authorizationClient.authorizationForScopes(scopes);

          if (clientAuth == null) {
            // No cached token, request authorization (may show consent screen on first use)
            Log.i('📝 No cached token, requesting authorization...', label: 'auth');
            clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);
          }

          final accessToken = clientAuth.accessToken;
          Log.i('✅ Got access token (length: ${accessToken.length})', label: 'auth');

          // Exchange Google tokens with Supabase (BOTH tokens required!)
          Log.i('🔄 Exchanging tokens with Supabase...', label: 'auth');
          final response = await supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

          if (response.session == null || response.user == null) {
            throw Exception('Supabase authentication failed');
          }

          final user = response.user!;
          Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

          // Sync profile from Supabase to local (only update empty fields)
          // Keep existing local data to support offline usage
          final authProvider = ref.read(local_auth.authStateProvider.notifier);
          final currentUser = authProvider.getUser();

          authProvider.setUser(currentUser.copyWith(
            // Only update name if local is empty/default
            name: currentUser.name.isEmpty || currentUser.name == 'User'
                ? (user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name)
                : currentUser.name,  // Keep existing local name
            email: user.email ?? currentUser.email,  // Always update email
            // Only update avatar if local is empty
            profilePicture: currentUser.profilePicture == null || currentUser.profilePicture!.isEmpty
                ? (user.userMetadata?['avatar_url'] ?? currentUser.profilePicture)
                : currentUser.profilePicture,  // Keep existing local avatar
          ));

          Log.i('✅ Synced profile from Supabase (kept existing local data)', label: 'auth');

          // Trigger initial Supabase sync to pull data from cloud
          if (context.mounted) {
            try {
              Log.i('🔄 Pulling data from Supabase...', label: 'auth');
              final syncService = ref.read(supabaseSyncServiceProvider);

              // Pull data from cloud (pull-first mode)
              await syncService.performFullSync(pushFirst: false);

              Log.i('✅ Initial sync completed', label: 'auth');
            } catch (e) {
              Log.e('⚠️ Failed to sync from cloud: $e', label: 'auth');
              // Continue anyway - user might be offline or have no cloud data
            }

            // Check if user has any wallets (either from cloud or existing local)
            final db = ref.read(databaseProvider);
            final wallets = await db.walletDao.getAllWallets();

            if (wallets.isEmpty) {
              // No wallets in local DB and cloud - new user, show onboarding
              Log.i('No wallets found, showing onboarding', label: 'auth');
              context.go('/onboarding');
            } else {
              // Has wallets (synced from cloud or existing local) - go to home
              Log.i('Found ${wallets.length} wallets, going to home', label: 'auth');
              context.go('/');
            }
          }
        }
      } on AuthException catch (e) {
        Log.e('Supabase auth error: ${e.message}', label: 'auth');
        if (context.mounted) {
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
        debugPrint('Google Sign In PlatformException: code=${e.code}, message=${e.message}');
        if (context.mounted) {
          String message = e.message ?? 'Google Sign-In failed';
          toastification.show(
            context: context,
            title: const Text('Google Login Failed'),
            description: Text('[${e.code}] $message'),
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
        // Facebook Sign In using native SDK
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (result.status == LoginStatus.success) {
          final AccessToken? accessToken = result.accessToken;

          if (accessToken != null) {
            debugPrint('Facebook Sign In successful');

            // Exchange Facebook token with Supabase
            final response = await supabase.auth.signInWithIdToken(
              provider: OAuthProvider.facebook,
              idToken: accessToken.tokenString,
            );

            if (response.session == null || response.user == null) {
              throw Exception('Supabase authentication failed');
            }

            final user = response.user!;
            Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

            // Sync user profile to local database
            final authProvider = ref.read(local_auth.authStateProvider.notifier);
            final currentUser = authProvider.getUser();

            authProvider.setUser(currentUser.copyWith(
              name: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? currentUser.name,
              email: user.email ?? currentUser.email,
              profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
            ));

            Log.i('✅ Synced profile from Supabase Auth (Facebook)', label: 'auth');

            // TODO: Trigger initial Supabase sync
            if (context.mounted) {
              final db = ref.read(databaseProvider);
              final wallets = await db.walletDao.getAllWallets();

              if (wallets.isEmpty) {
                context.go('/onboarding');
              } else {
                context.go('/');
              }
            }
          }
        } else if (result.status == LoginStatus.cancelled) {
          debugPrint('Facebook Sign In cancelled by user');
        } else if (result.status == LoginStatus.failed) {
          throw Exception('Facebook Sign In failed: ${result.message}');
        }
      } on AuthException catch (e) {
        Log.e('Supabase auth error: ${e.message}', label: 'auth');
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Facebook Login Failed'),
            description: Text('${e.message}'),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        debugPrint('Facebook Sign In Error: $e');
        if (context.mounted) {
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
        isLoading.value = false;
      }
    }

    Future<void> handleAppleSignIn() async {
      isLoading.value = true;
      try {
        // Request Apple ID credential
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.joy.bexly.service',
            redirectUri: Uri.parse(
              'https://dos.supabase.co/auth/v1/callback',
            ),
          ),
        );

        debugPrint('Apple Sign In successful');

        // Exchange Apple token with Supabase
        final response = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: credential.identityToken!,
        );

        if (response.session == null || response.user == null) {
          throw Exception('Supabase authentication failed');
        }

        final user = response.user!;
        Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

        // Sync user profile to local database
        final authProvider = ref.read(local_auth.authStateProvider.notifier);
        final currentUser = authProvider.getUser();

        // For Apple, combine givenName and familyName if full_name is null
        String? displayName = user.userMetadata?['full_name'];
        if (displayName == null && credential.givenName != null) {
          displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        }

        authProvider.setUser(currentUser.copyWith(
          name: displayName ?? user.email?.split('@').first ?? currentUser.name,
          email: user.email ?? credential.email ?? currentUser.email,
          profilePicture: user.userMetadata?['avatar_url'] ?? currentUser.profilePicture,
        ));

        Log.i('✅ Synced profile from Supabase Auth (Apple)', label: 'auth');

        // TODO: Trigger initial Supabase sync
        if (context.mounted) {
          final db = ref.read(databaseProvider);
          final wallets = await db.walletDao.getAllWallets();

          if (wallets.isEmpty) {
            context.go('/onboarding');
          } else {
            context.go('/');
          }
        }
      } on AuthException catch (e) {
        Log.e('Supabase auth error: ${e.message}', label: 'auth');
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Apple Login Failed'),
            description: Text(e.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/icon/Bexly-logo-no-bg.png',
                      width: 80,
                      height: 80,
                    ),
                    const Gap(16),
                    Text(
                      'Sign in to sync across devices',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const Gap(24),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.body3,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(
                          0,
                          AppSpacing.spacing16,
                          0,
                          AppSpacing.spacing16,
                        ),
                        border: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.neutral600),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        enabledBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.neutral600),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        focusedBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.purple),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        errorBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.red),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        focusedErrorBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.red),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
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
                      style: AppTextStyles.body3,
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
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(
                          0,
                          AppSpacing.spacing16,
                          0,
                          AppSpacing.spacing16,
                        ),
                        border: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.neutral600),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        enabledBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.neutral600),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        focusedBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.purple),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        errorBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.red),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
                        focusedErrorBorder: CustomInputBorder(
                          borderSide: const BorderSide(color: AppColors.red),
                          borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                        ),
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
                          // TODO: Implement forgot password with Supabase
                          toastification.show(
                            context: context,
                            title: const Text('Coming Soon'),
                            description: const Text('Password reset will be available soon'),
                            type: ToastificationType.info,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
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
                              // TODO: Implement signup with Supabase
                              toastification.show(
                                context: context,
                                title: const Text('Coming Soon'),
                                description: const Text('Account creation will be available soon'),
                                type: ToastificationType.info,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
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
                    const Gap(16),
                    // Social Login Buttons
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
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
                            minimumSize: const Size(100, 44),
                          ),
                        ),
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
                            minimumSize: const Size(100, 44),
                          ),
                        ),
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
                            minimumSize: const Size(100, 44),
                          ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
