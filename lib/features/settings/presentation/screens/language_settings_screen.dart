import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/features/settings/presentation/riverpod/language_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    return CustomScaffold(
      context: context,
      title: l10n.selectLanguage,
      showBalance: false,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing20,
          AppSpacing.spacing0,
          AppSpacing.spacing20,
          AppSpacing.spacing20,
        ),
        itemCount: availableLanguages.length,
        separatorBuilder: (context, index) => const Gap(AppSpacing.spacing12),
        itemBuilder: (context, index) {
          final language = availableLanguages[index];
          final isSelected = language.code == currentLanguage.code;

          return InkWell(
            onTap: () {
              if (language.code != currentLanguage.code) {
                ref.read(languageProvider.notifier).setLanguage(language);

                // Show confirmation snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.languageChanged(language.name)),
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Go back after selection
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : AppColors.purple50,
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.purpleAlpha10,
                ),
              ),
              child: Row(
                children: [
                  // Flag container
                  Container(
                    height: 50,
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple50,
                      borderRadius: BorderRadius.circular(AppRadius.radius8),
                      border: Border.all(color: AppColors.purpleAlpha10),
                    ),
                    child: Text(
                      language.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),
                  // Language name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          language.name,
                          style: AppTextStyles.body3.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (language.nativeName != language.name)
                          Text(
                            language.nativeName,
                            style: AppTextStyles.body4.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.neutral500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Checkmark icon
                  if (isSelected)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
