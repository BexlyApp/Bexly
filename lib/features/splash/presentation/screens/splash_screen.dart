import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/database/database_provider.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // Schedule navigation after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Load currencies first
        try {
          final currencyList = await ref.read(currenciesProvider.future);
          ref.read(currenciesStaticProvider.notifier).state = currencyList;
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

        // Process due recurring payments
        try {
          final recurringService = ref.read(recurringChargeServiceProvider);
          await recurringService.processDueRecurringPayments();
          Log.d('Processed recurring payments', label: 'SplashScreen');
        } catch (e) {
          Log.e('Failed to process recurring payments: $e', label: 'SplashScreen');
        }

        // Small delay for splash screen visibility
        await Future.delayed(const Duration(seconds: 2));

        if (!context.mounted) return;

        try {
          // Check authentication state - read the actual User value from AsyncValue
          final authAsyncValue = ref.read(authStateProvider);
          final currentUser = authAsyncValue.valueOrNull;

          // Check if user has skipped auth before
          final prefs = await SharedPreferences.getInstance();
          final hasSkippedAuth = prefs.getBool('hasSkippedAuth') ?? false;

          if (!context.mounted) return;

          if (currentUser != null) {
            // User is authenticated with Firebase
            Log.d('User authenticated (${currentUser.email}), checking wallet...', label: 'SplashScreen');

            // Check if user has any wallets
            final db = ref.read(databaseProvider);
            final wallets = await db.walletDao.getAllWallets();

            if (wallets.isEmpty) {
              // No wallet yet - go to onboarding to setup first wallet
              Log.d('No wallets found, navigating to onboarding', label: 'SplashScreen');
              ref.read(isGuestModeProvider.notifier).state = false;
              await prefs.setBool('hasSkippedAuth', false);

              if (context.mounted) {
                context.go(Routes.onboarding);
              }
            } else {
              // Has wallet - go to main
              Log.d('User has ${wallets.length} wallet(s), navigating to main', label: 'SplashScreen');
              ref.read(isGuestModeProvider.notifier).state = false;
              await prefs.setBool('hasSkippedAuth', false);

              if (context.mounted) {
                context.go('/');
              }
            }
          } else if (hasSkippedAuth) {
            // User has used guest mode before - check if has wallet
            Log.d('Guest mode active, checking wallet...', label: 'SplashScreen');
            ref.read(isGuestModeProvider.notifier).state = true;

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
          // Error during initialization, go to login
          if (context.mounted) {
            context.go('/login');
          }
        }
      });

      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Bexly',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personal Finance Manager',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}