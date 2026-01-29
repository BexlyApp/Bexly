import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Log.d('🚀 SplashScreen build() called', label: 'SplashScreen');

    // Use useState to track theme after loading from SharedPreferences
    final isDark = useState<bool?>(null);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    useEffect(() {
      // Load theme from SharedPreferences directly
      SharedPreferences.getInstance().then((prefs) {
        final savedThemeMode = prefs.getString('themeMode');
        if (savedThemeMode != null) {
          if (savedThemeMode == 'ThemeMode.dark') {
            isDark.value = true;
          } else if (savedThemeMode == 'ThemeMode.system') {
            isDark.value = systemBrightness == Brightness.dark;
          } else {
            isDark.value = false;
          }
        } else {
          isDark.value = false; // Default to light
        }
      });
      return null;
    }, const []);

    useEffect(() {
      Log.d('📍 useEffect registered, scheduling postFrameCallback', label: 'SplashScreen');

      // Schedule navigation after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Log.d('⏰ postFrameCallback executing', label: 'SplashScreen');

        // Load currencies first
        try {
          final currencyList = await ref.read(currenciesProvider.future);
          ref.read(currenciesStaticProvider.notifier).setCurrencies(currencyList);
          Log.d('Loaded ${currencyList.length} currencies', label: 'SplashScreen');
        } catch (e) {
          Log.e('Failed to load currencies: $e', label: 'SplashScreen');
        }

        // Validate and repair category integrity
        try {
          Log.d('Starting category integrity validation...', label: 'SplashScreen');
          await ref.read(categoryIntegrityProvider.future);
          Log.d('Category integrity validated', label: 'SplashScreen');
        } catch (e) {
          Log.e('Failed to validate category integrity: $e', label: 'SplashScreen');
        }

        // Clean up orphaned transactions (missing category or wallet)
        try {
          Log.d('Starting transaction integrity check...', label: 'SplashScreen');
          final deletedCount = await ref.read(transactionIntegrityProvider.future);
          if (deletedCount > 0) {
            Log.w('Cleaned up $deletedCount orphaned transactions', label: 'SplashScreen');
          }
        } catch (e) {
          Log.e('Failed to clean up orphaned transactions: $e', label: 'SplashScreen');
        }

        // Create transactions for due recurring payments
        try {
          final recurringService = ref.read(recurringChargeServiceProvider);
          await recurringService.createDueTransactions();
          Log.d('Created due transactions', label: 'SplashScreen');
        } catch (e) {
          Log.e('Failed to create due transactions: $e', label: 'SplashScreen');
        }

        if (!context.mounted) return;

        try {
          // Check Supabase auth state (DOS-Me auth server)
          final supabaseAuthState = ref.read(supabaseAuthServiceProvider);
          final isAuthenticated = supabaseAuthState.isAuthenticated;
          final currentUser = supabaseAuthState.user;

          // Check if user has skipped auth before
          final prefs = await SharedPreferences.getInstance();
          final hasSkippedAuth = prefs.getBool('hasSkippedAuth') ?? false;

          if (!context.mounted) return;

          // Remove native splash before navigating
          FlutterNativeSplash.remove();

          if (isAuthenticated && currentUser != null) {
            // User is authenticated with Supabase (DOS-Me)
            Log.d('User authenticated (${currentUser.email}), checking wallet...', label: 'SplashScreen');

            // Trigger background sync (don't await - let it run in background)
            try {
              final syncService = ref.read(supabaseSyncServiceProvider);
              if (syncService.isAuthenticated) {
                syncService.performFullSync(pushFirst: true).catchError((e) {
                  Log.e('Background sync failed on app start: $e', label: 'SplashScreen');
                });
                Log.d('Background sync triggered on app start', label: 'SplashScreen');
              }
            } catch (e) {
              Log.e('Failed to trigger background sync: $e', label: 'SplashScreen');
            }

            // Check if user has any wallets
            final db = ref.read(databaseProvider);
            final wallets = await db.walletDao.getAllWallets();

            if (wallets.isEmpty) {
              // No wallet yet - go to onboarding to setup first wallet
              Log.d('No wallets found, navigating to onboarding', label: 'SplashScreen');
              ref.read(isGuestModeProvider.notifier).setGuestMode(false);
              await prefs.setBool('hasSkippedAuth', false);

              if (context.mounted) {
                context.go(Routes.onboarding);
              }
            } else {
              // Has wallet - go to main
              Log.d('User has ${wallets.length} wallet(s), navigating to main', label: 'SplashScreen');
              ref.read(isGuestModeProvider.notifier).setGuestMode(false);
              await prefs.setBool('hasSkippedAuth', false);

              if (context.mounted) {
                context.go('/');
              }
            }
          } else if (hasSkippedAuth) {
            // User has used guest mode before - check if has wallet
            Log.d('Guest mode active, checking wallet...', label: 'SplashScreen');
            ref.read(isGuestModeProvider.notifier).setGuestMode(true);

            final db = ref.read(databaseProvider);
            final wallets = await db.walletDao.getAllWallets();

            if (wallets.isEmpty) {
              // No wallet - go to onboarding
              Log.d('Guest mode but no wallet, navigating to onboarding', label: 'SplashScreen');
              if (context.mounted) {
                context.go(Routes.onboarding);
              }
            } else {
              // Has wallet - go to main
              Log.d('Guest mode with ${wallets.length} wallet(s), navigating to main', label: 'SplashScreen');
              if (context.mounted) {
                context.go('/');
              }
            }
          } else {
            // First time user OR logged out, show login
            Log.d('No auth state, navigating to login', label: 'SplashScreen');

            if (context.mounted) {
              context.go('/login');
            }
          }
        } catch (e) {
          Log.e('Navigation error: $e', label: 'SplashScreen');
          // Remove splash and go to login on error
          FlutterNativeSplash.remove();
          if (context.mounted) {
            context.go('/login');
          }
        }
      });

      return null;
    }, const []);

    // Show splash UI (needed for web where native splash doesn't persist)
    final darkMode = isDark.value ?? false;
    final bgColor = darkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = darkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/icon-transparent-full.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Bexly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED), // Primary purple
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personal Finance Manager',
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }
}
