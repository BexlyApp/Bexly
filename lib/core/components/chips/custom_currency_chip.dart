import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class CustomCurrencyChip extends StatelessWidget {
  final String currencyCode;
  final String label;
  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final IconData? icon;
  final Color? iconColor;
  final String? countryCodeOverride; // Override to use country code instead of currency code
  const CustomCurrencyChip({
    super.key,
    required this.currencyCode,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
    this.iconColor,
    this.borderColor,
    this.countryCodeOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: background ?? AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          countryCodeOverride != null
              ? CountryFlag.fromCountryCode(
                  countryCodeOverride!,
                  theme: ImageTheme(
                    width: 20,
                    height: 14,
                    shape: RoundedRectangle(AppRadius.radius4),
                  ),
                )
              : CountryFlag.fromCurrencyCode(
                  currencyCode,
                  theme: ImageTheme(
                    width: 20,
                    height: 14,
                    shape: RoundedRectangle(AppRadius.radius4),
                  ),
                ),
          const Gap(AppSpacing.spacing4),
          Text(label, style: AppTextStyles.body4.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
