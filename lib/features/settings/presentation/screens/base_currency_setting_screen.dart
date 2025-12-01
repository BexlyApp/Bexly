import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';

class BaseCurrencySettingScreen extends ConsumerWidget {
  const BaseCurrencySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    return CustomScaffold(
      context: context,
      title: context.l10n.baseCurrency,
      showBalance: false,
      body: currenciesAsync.when(
        data: (currencies) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing20,
              vertical: AppSpacing.spacing20,
            ),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = currency.isoCode == baseCurrency;

              return InkWell(
                onTap: () {
                  ref
                      .read(baseCurrencyProvider.notifier)
                      .setBaseCurrency(currency.isoCode);

                  // Clear exchange rate cache when changing base currency
                  ref.read(exchangeRateCacheProvider.notifier).clearCache();

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${context.l10n.baseCurrency}: ${currency.name}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacing8,
                    horizontal: AppSpacing.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: context.purpleBackground,
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                    border: Border.all(
                      color: isSelected
                          ? context.purpleButtonBorder
                          : context.purpleBorderLighter,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              padding: const EdgeInsets.all(AppSpacing.spacing8),
                              decoration: BoxDecoration(
                                color: context.purpleButtonBackground,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.radius4,
                                ),
                                border: Border.all(
                                  color: context.purpleButtonBorder,
                                ),
                              ),
                              child: Text(
                                currency.symbol,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body3.copyWith(
                                  color: context.purpleText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Gap(AppSpacing.spacing8),
                            Text(currency.name, style: AppTextStyles.body2),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.spacing8,
                              ),
                              child: Icon(
                                HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: context.purpleText,
                                size: 24,
                              ),
                            ),
                          currency.countryCode.isEmpty
                              ? const SizedBox(height: 32)
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radius4,
                                    ),
                                    border: Border.all(
                                      color: context.purpleBorderLighter,
                                    ),
                                  ),
                                  child: CountryFlag.fromCountryCode(
                                    currency.countryCode,
                                    theme: const ImageTheme(
                                      width: 44,
                                      height: 32,
                                      shape: RoundedRectangle(AppRadius.radius4),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Gap(AppSpacing.spacing8),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
