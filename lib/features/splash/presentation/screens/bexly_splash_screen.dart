import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class BexlySplashScreen extends HookConsumerWidget {
  const BexlySplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('BexlySplashScreen - build called');

    useEffect(() {
      print('BexlySplashScreen - useEffect started');

      // Schedule navigation after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('BexlySplashScreen - Post frame callback started');

        // Load currencies first
        try {
          Log.d('Loading currencies...', label: 'BexlySplashScreen');
          final currencyList = await ref.read(currenciesProvider.future);
          ref.read(currenciesStaticProvider.notifier).state = currencyList;
          Log.d('Loaded ${currencyList.length} currencies', label: 'BexlySplashScreen');
        } catch (e) {
          Log.e('Failed to load currencies: $e', label: 'BexlySplashScreen');
        }

        // Small delay for splash screen visibility
        await Future.delayed(const Duration(seconds: 2));
        print('BexlySplashScreen - delay finished');

        if (!context.mounted) {
          print('Context not mounted, aborting navigation');
          return;
        }

        try {
          // Check authentication state
          final authState = ref.read(authStateProvider);

          if (authState != null) {
            // User is authenticated
            print('User is authenticated, navigating to main screen');
            if (context.mounted) {
              context.go('/');
            }
          } else {
            // Check if user has skipped auth before
            final prefs = await SharedPreferences.getInstance();
            final hasSkippedAuth = prefs.getBool('hasSkippedAuth') ?? false;

            if (hasSkippedAuth) {
              // User has used guest mode before
              print('User has skipped auth before, navigating to main screen');
              ref.read(isGuestModeProvider.notifier).state = true;
              if (context.mounted) {
                context.go('/');
              }
            } else {
              // First time user, show login
              print('First time user, navigating to login screen');
              if (context.mounted) {
                context.go('/login');
              }
            }
          }
        } catch (e) {
          print('Error during navigation: $e');
          // Error during initialization, go to login
          if (context.mounted) {
            print('Navigating to login due to error');
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