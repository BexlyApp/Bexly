part of '../screens/settings_screen.dart';

class SettingsPreferencesGroup extends ConsumerWidget {
  const SettingsPreferencesGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return SettingsGroupHolder(
      title: 'Preferences',
      settingTiles: [
        MenuTileButton(
          label: 'Language',
          icon: HugeIcons.strokeRoundedTranslation,
          onTap: () => _showLanguageDialog(context, ref),
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
            ],
          ),
        ),
        MenuTileButton(
          label: 'Notifications',
          icon: HugeIcons.strokeRoundedNotification01,
          onTap: () => context.push(Routes.comingSoon),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(languageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLanguages.map((language) {
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
                      content: Text('Language changed to ${value.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
