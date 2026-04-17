import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
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
import 'package:bexly/core/utils/logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart' as local_auth;
import 'package:bexly/core/components/form_fields/custom_input_border.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/services/demo_data_service.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  /// Shared post-login flow: clear stale data (only for different user),
  /// sync profile, sync data from cloud, navigate to main or onboarding.
  static Future<void> _postLoginFlow({
    required BuildContext context,
    required WidgetRef ref,
    required User user,
    required SupabaseClient supabase,
    String? displayNameOverride,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUserId = prefs.getString('lastSupabaseUserId');
    final db = ref.read(databaseProvider);
    final isDemoUser = DemoPersonaInfo.fromEmail(user.email) != null;

    // Clear local data if:
    // (1) a DIFFERENT Supabase user is logging in, OR
    // (2) this is a demo account login (must always start fresh to avoid mixing
    //     guest/previous-user data with seeded demo data), OR
    // (3) lastUserId is null but local DB has data (guest mode leftovers)
    final shouldClear = (lastUserId != null && lastUserId != user.id) ||
        isDemoUser ||
        (lastUserId == null && (await db.walletDao.getAllWallets()).isNotEmpty);

    if (shouldClear) {
      Log.i('⚠️ Clearing stale data (lastUserId: $lastUserId, newUserId: ${user.id}, demo: $isDemoUser)', label: 'auth');
      await db.clearAllTables();
    }

    // Save current user ID for future comparison
    await prefs.setString('lastSupabaseUserId', user.id);

    // Sync user profile to local database
    final authProvider = ref.read(local_auth.authStateProvider.notifier);
    final currentUser = authProvider.getUser();

    // Get avatar URL: try metadata first, then fallback to Storage URL
    String? avatarUrl = user.userMetadata?['avatar_url'] as String?;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final storagePath = 'Avatars/${user.id}/avatar.jpg';
      avatarUrl = supabase.storage.from('Assets').getPublicUrl(storagePath);
    }

    final name = displayNameOverride
        ?? user.userMetadata?['full_name']
        ?? user.email?.split('@').first
        ?? currentUser.name;

    authProvider.setUser(currentUser.copyWith(
      name: name,
      email: user.email ?? currentUser.email,
      profilePicture: avatarUrl ?? currentUser.profilePicture,
    ));

    Log.i('✅ Synced profile (${user.email}), avatar: $avatarUrl', label: 'auth');

    // Trigger initial Supabase sync to pull data from cloud
    if (!context.mounted) return;

    try {
      final syncService = ref.read(supabaseSyncServiceProvider);
      Log.i('🔄 Pulling data from Supabase... (userId: ${user.id})', label: 'auth');
      await syncService.performFullSync(pushFirst: false);
      Log.i('✅ Initial sync completed', label: 'auth');
    } catch (e, stackTrace) {
      Log.e('⚠️ Failed to sync from cloud: $e', label: 'auth');
      Log.e('⚠️ Stack trace: $stackTrace', label: 'auth');
    }

    if (!context.mounted) return;

    // Auto-seed demo data for test accounts
    final demoPersona = DemoPersonaInfo.fromEmail(user.email);
    if (demoPersona != null) {
      Log.i('Demo account detected (${user.email}), seeding ${demoPersona.displayName}...', label: 'auth');
      try {
        final demoService = ref.read(demoDataServiceProvider);
        final txCount = await demoService.seedPersona(demoPersona);
        Log.i('Demo data seeded: $txCount transactions, pushing to cloud...', label: 'auth');

        // Push demo data to cloud so Telegram bot can see it
        final syncService = ref.read(supabaseSyncServiceProvider);
        await syncService.performFullSync(pushFirst: true);
        Log.i('Demo data pushed to cloud', label: 'auth');
      } catch (e) {
        Log.e('Failed to seed demo data: $e', label: 'auth');
      }
    }

    if (!context.mounted) return;

    // Check if user has any wallets locally
    final wallets = await db.walletDao.getAllWallets();
    Log.i('📊 Wallet check after sync: found ${wallets.length} wallets', label: 'auth');

    if (wallets.isNotEmpty) {
      Log.i('Found ${wallets.length} wallets, going to home', label: 'auth');
      context.go('/');
      return;
    }

    // Wallets empty - sync may have failed. Query cloud directly as fallback.
    try {
      Log.i('🔍 No local wallets, checking cloud directly...', label: 'auth');
      final cloudWallets = await supabase
          .schema('bexly')
          .from('wallets')
          .select('cloud_id')
          .eq('user_id', user.id)
          .eq('is_active', true);

      if ((cloudWallets as List).isNotEmpty) {
        Log.i('☁️ Found ${cloudWallets.length} wallets on cloud, retrying wallet sync...', label: 'auth');
        // Retry pulling wallets only
        final syncService = ref.read(supabaseSyncServiceProvider);
        await syncService.pullWalletsFromCloud();

        final retryWallets = await db.walletDao.getAllWallets();
        if (retryWallets.isNotEmpty && context.mounted) {
          Log.i('✅ Retry succeeded, ${retryWallets.length} wallets pulled', label: 'auth');
          context.go('/');
          return;
        }
      }
    } catch (e) {
      Log.e('⚠️ Failed to check cloud wallets: $e', label: 'auth');
    }

    // Genuinely no wallets anywhere - show onboarding
    if (context.mounted) {
      Log.i('No wallets found anywhere, showing onboarding', label: 'auth');
      context.go('/onboarding');
    }
  }

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

        if (context.mounted) {
          await _postLoginFlow(
            context: context,
            ref: ref,
            user: user,
            supabase: supabase,
          );
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

    Future<void> handleForgotPassword() async {
      final email = emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        toastification.show(
          context: context,
          title: const Text('Enter Email First'),
          description: const Text('Please enter your email address above'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
      isLoading.value = true;
      try {
        await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: 'bexly://reset-password',
        );
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Email Sent'),
            description: const Text('Check your inbox for password reset instructions'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      } on AuthException catch (e) {
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Reset Failed'),
            description: Text(e.message),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Reset Failed'),
            description: Text(e.toString()),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSignUp() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      try {
        final response = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.user == null) {
          throw Exception('Sign up failed — no user returned');
        }

        final user = response.user!;

        if (response.session == null) {
          // Email confirmation required
          if (context.mounted) {
            toastification.show(
              context: context,
              title: const Text('Check Your Email'),
              description: const Text('A confirmation link has been sent to your email address'),
              type: ToastificationType.success,
              autoCloseDuration: const Duration(seconds: 6),
            );
          }
          return;
        }

        // Auto-confirmed (e.g. test/dev mode) — go to main flow
        if (context.mounted) {
          await _postLoginFlow(
            context: context,
            ref: ref,
            user: user,
            supabase: supabase,
          );
        }
      } on AuthException catch (e) {
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Sign Up Failed'),
            description: Text(e.message),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Sign Up Failed'),
            description: Text(e.toString()),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    String generateRawNonce([int length = 32]) {
      const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final random = Random.secure();
      return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
    }

    String sha256ofString(String input) {
      final bytes = utf8.encode(input);
      return sha256.convert(bytes).toString();
    }

    Future<void> handleGoogleSignIn() async {
      isLoading.value = true;
      try {
        if (kIsWeb) {
          // Web: Use Supabase signInWithOAuth
          // Must set redirectTo to current origin so Supabase redirects back here
          // instead of defaulting to id.dos.me
          final webRedirectUrl = Uri.base.origin;
          await supabase.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: webRedirectUrl,
          );
        } else {
          // Mobile: Use native Google Sign-In SDK (initialized in main.dart with serverClientId)
          final googleSignIn = GoogleSignIn.instance;

          Log.i('📱 Starting native Google Sign In flow', label: 'auth');
          Log.i('🔍 Debug mode: ${kDebugMode}', label: 'auth');

          // google_sign_in v7: authenticate() shows account picker or
          // re-uses previous account. No need to signOut() first.
          // Generate nonce for Supabase token verification
          final rawNonce = generateRawNonce();
          final hashedNonce = sha256ofString(rawNonce);

          // Re-initialize with nonce (required for iOS to embed nonce in ID token)
          await googleSignIn.initialize(
            clientId: defaultTargetPlatform == TargetPlatform.iOS
                ? '368090586626-jp6s7eerkn9v7279dvgrluaf6jep8kku.apps.googleusercontent.com'
                : null,
            serverClientId: '368090586626-ch5cd0afri6pilfipeersbtqkpf6huj6.apps.googleusercontent.com',
            nonce: hashedNonce,
          );

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
            nonce: rawNonce,
          );

          if (response.session == null || response.user == null) {
            throw Exception('Supabase authentication failed');
          }

          final user = response.user!;
          Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

          if (context.mounted) {
            await _postLoginFlow(
              context: context,
              ref: ref,
              user: user,
              supabase: supabase,
            );
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
        // Generate nonce for iOS Limited Login (OIDC token verification)
        final rawNonce = generateRawNonce();
        final hashedNonce = sha256ofString(rawNonce);

        // Facebook Sign In using native SDK
        // iOS 17+: Uses Limited Login when ATT not granted → returns LimitedToken
        // Android: Uses classic login → returns ClassicToken
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
          loginBehavior: LoginBehavior.nativeWithFallback,
          nonce: hashedNonce,
        );

        if (result.status == LoginStatus.success) {
          final AccessToken? accessToken = result.accessToken;

          if (accessToken != null) {
            Log.i('Facebook Sign In successful, token type: ${accessToken.type}', label: 'auth');

            AuthResponse response;

            if (accessToken is LimitedToken) {
              // iOS Limited Login: tokenString IS the OIDC token
              Log.i('Facebook Limited Login: using tokenString as OIDC token', label: 'auth');
              response = await supabase.auth.signInWithIdToken(
                provider: OAuthProvider.facebook,
                idToken: accessToken.tokenString,
                nonce: rawNonce,
              );
            } else if (accessToken is ClassicToken) {
              // Classic Login: use authenticationToken (OIDC) if available, else tokenString
              final oidcToken = accessToken.authenticationToken ?? accessToken.tokenString;
              Log.i('Facebook Classic Login: hasOIDC=${accessToken.authenticationToken != null}', label: 'auth');
              response = await supabase.auth.signInWithIdToken(
                provider: OAuthProvider.facebook,
                idToken: oidcToken,
              );
            } else {
              // Fallback: use tokenString directly
              response = await supabase.auth.signInWithIdToken(
                provider: OAuthProvider.facebook,
                idToken: accessToken.tokenString,
              );
            }

            if (response.session == null || response.user == null) {
              throw Exception('Supabase authentication failed');
            }

            final user = response.user!;
            Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

            if (context.mounted) {
              await _postLoginFlow(
                context: context,
                ref: ref,
                user: user,
                supabase: supabase,
              );
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
        // Generate nonce for Supabase token verification
        final rawNonce = generateRawNonce();
        final hashedNonce = sha256ofString(rawNonce);

        // Request Apple ID credential
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
          // webAuthenticationOptions only needed for Android/Web
          webAuthenticationOptions: defaultTargetPlatform == TargetPlatform.iOS
              ? null
              : WebAuthenticationOptions(
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
          nonce: rawNonce,
        );

        if (response.session == null || response.user == null) {
          throw Exception('Supabase authentication failed');
        }

        final user = response.user!;
        Log.i('✅ Supabase authentication successful: ${user.email}', label: 'auth');

        // For Apple, combine givenName and familyName if full_name is null
        String? displayName = user.userMetadata?['full_name'];
        if (displayName == null && credential.givenName != null) {
          displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        }

        if (context.mounted) {
          await _postLoginFlow(
            context: context,
            ref: ref,
            user: user,
            supabase: supabase,
            displayNameOverride: displayName,
          );
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
        Log.e('Apple Sign In Error: $e', label: 'auth');
        if (context.mounted) {
          String errorMessage = e.toString().length > 120
              ? e.toString().substring(0, 120)
              : e.toString();
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
                    const Gap(8),
                    Text(
                      'Bexly',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(4),
                    Text(
                      'Your AI-powered financial coach',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
                    const Gap(12),
                    _DemoAccountButton(
                      isLoading: isLoading,
                      supabase: supabase,
                      ref: ref,
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

/// Demo account button that shows persona selector and auto-logs in
class _DemoAccountButton extends StatefulWidget {
  final ValueNotifier<bool> isLoading;
  final SupabaseClient supabase;
  final WidgetRef ref;

  const _DemoAccountButton({
    required this.isLoading,
    required this.supabase,
    required this.ref,
  });

  @override
  State<_DemoAccountButton> createState() => _DemoAccountButtonState();
}

class _DemoAccountButtonState extends State<_DemoAccountButton> {
  bool _isDemoLoading = false;
  DemoPersona? _loadingPersona;

  Future<void> _loginWithDemoAccount(DemoPersona persona) async {
    setState(() {
      _isDemoLoading = true;
      _loadingPersona = persona;
    });
    widget.isLoading.value = true;

    try {
      // Sign in with demo email + password
      final response = await widget.supabase.auth.signInWithPassword(
        email: persona.demoEmail,
        password: demoPasswordForEmail(persona.demoEmail),
      );

      if (response.session == null || response.user == null) {
        throw Exception('Demo login failed - no session created');
      }

      final user = response.user!;
      Log.i('Demo login successful: ${user.email} (${persona.displayName})', label: 'auth');

      if (mounted) {
        // Close the persona selector bottom sheet
        Navigator.of(context).pop();

        await LoginScreen._postLoginFlow(
          context: context,
          ref: widget.ref,
          user: user,
          supabase: widget.supabase,
          displayNameOverride: persona.displayName,
        );
      }
    } on AuthException catch (e) {
      Log.e('Demo auth error: ${e.message}', label: 'auth');
      if (mounted) {
        Navigator.of(context).pop();
        toastification.show(
          context: context,
          title: const Text('Demo Login Failed'),
          description: Text(e.message),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Log.e('Demo login error: $e', label: 'auth');
      if (mounted) {
        Navigator.of(context).pop();
        toastification.show(
          context: context,
          title: const Text('Demo Login Failed'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDemoLoading = false;
          _loadingPersona = null;
        });
      }
      widget.isLoading.value = false;
    }
  }

  void _showPersonaSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Try Demo Account',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Choose a persona to explore Bexly with pre-built financial data',
                    style: AppTextStyles.body4.copyWith(
                      color: AppColors.neutral500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: DemoPersona.values.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (_, index) {
                        final persona = DemoPersona.values[index];
                        final isThisLoading = _isDemoLoading && _loadingPersona == persona;
                        final isDisabled = _isDemoLoading && _loadingPersona != persona;

                        return _DemoPersonaCard(
                          persona: persona,
                          isLoading: isThisLoading,
                          isDisabled: isDisabled,
                          onTap: _isDemoLoading
                              ? null
                              : () {
                                  // Update parent state for loading indicator
                                  setState(() {
                                    _isDemoLoading = true;
                                    _loadingPersona = persona;
                                  });
                                  setSheetState(() {});
                                  _loginWithDemoAccount(persona);
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: widget.isLoading.value ? null : _showPersonaSelector,
      icon: const Icon(Icons.people_outline, size: 20),
      label: const Text('Try Demo Account'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Card showing a demo persona with name, role, and feature tags
class _DemoPersonaCard extends StatelessWidget {
  final DemoPersona persona;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _DemoPersonaCard({
    required this.persona,
    this.isLoading = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(persona.icon, style: const TextStyle(fontSize: 20)),
              ),
              const Gap(AppSpacing.spacing12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.displayName,
                      style: AppTextStyles.body3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      persona.subtitle,
                      style: AppTextStyles.body5.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(4),
                    // Feature tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: persona.demoFeatures
                          .take(3)
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  f,
                                  style: AppTextStyles.body5.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Loading or arrow
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
