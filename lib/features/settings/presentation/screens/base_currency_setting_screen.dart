import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/menu_tile_button.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';

class BaseCurrencySettingScreen extends ConsumerWidget {
  const BaseCurrencySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Base Currency'),
        leading: IconButton(
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => context.pop(),
        ),
      ),
      body: currenciesAsync.when(
        data: (currencies) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            children: [
              Text(
                'Select your base currency for Total Balance calculation. All wallets will be converted to this currency.',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: AppSpacing.spacing16),
              ...currencies.map((currency) {
                final isSelected = currency.isoCode == baseCurrency;

                return MenuTileButton(
                  label: '${currency.name} (${currency.isoCode})',
                  icon: HugeIcons.strokeRoundedMoney02,
                  suffixIcon: isSelected
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedArrowRight01,
                  onTap: () {
                    ref
                        .read(baseCurrencyProvider.notifier)
                        .setBaseCurrency(currency.isoCode);

                    // Clear exchange rate cache when changing base currency
                    ref.read(exchangeRateCacheProvider.notifier).clearCache();

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Base currency changed to ${currency.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
