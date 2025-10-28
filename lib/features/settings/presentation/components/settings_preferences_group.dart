part of '../screens/settings_screen.dart';

class SettingsPreferencesGroup extends ConsumerWidget {
  const SettingsPreferencesGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    final l10n = AppLocalizations.of(context)!;

    return SettingsGroupHolder(
      title: l10n.preferences,
      settingTiles: [
        ListTile(
          onTap: () => _showLanguageDialog(context, ref),
          tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          leading: Icon(
            HugeIcons.strokeRoundedTranslation,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            l10n.language,
            style: AppTextStyles.body3.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLanguage.flag,
                style: const TextStyle(fontSize: 20),
              ),
              const Gap(8),
              Text(
                currentLanguage.name,
                style: AppTextStyles.body3.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const Gap(8),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
        MenuTileButton(
          label: l10n.notifications,
          icon: HugeIcons.strokeRoundedNotification01,
          onTap: () => context.push(Routes.comingSoon),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing20,
          AppSpacing.spacing12,
          AppSpacing.spacing20,
          AppSpacing.spacing32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(AppSpacing.spacing20),

            // Language options
            ...availableLanguages.map((language) {
              return RadioListTile<Language>(
                title: Row(
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(language.name),
                        if (language.nativeName != language.name)
                          Text(
                            language.nativeName,
                            style: AppTextStyles.body4.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                value: language,
                groupValue: currentLanguage,
                onChanged: (Language? value) {
                  if (value != null) {
                    ref.read(languageProvider.notifier).setLanguage(value);
                    Navigator.of(context).pop();

                    // Show confirmation snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.languageChanged(value.name)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
