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
          onTap: () => context.push(Routes.languageSettings),
          tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedTranslation,
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
        MenuTileButton(
          label: l10n.notifications,
          icon: HugeIcons.strokeRoundedNotification01,
          onTap: () => context.push(Routes.notificationSettings),
        ),
        if (Platform.isAndroid)
          MenuTileButton(
            label: l10n.autoTransaction,
            icon: HugeIcons.strokeRoundedMessage01,
            onTap: () => context.push(Routes.autoTransactionSettings),
          ),
      ],
    );
  }
}
