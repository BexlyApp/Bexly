part of '../screens/settings_screen.dart';

class SettingsPreferencesGroup extends ConsumerWidget {
  const SettingsPreferencesGroup({super.key});

  void _showNumberFormatPicker(BuildContext context, WidgetRef ref) {
    final currentFormat = ref.read(numberFormatProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        final options = [
          ('auto', 'Auto (${ref.read(languageProvider).name})', NumberFormatConfig.previewText),
          ('en_US', '1,000.50', 'English / US'),
          ('vi_VN', '1.000,50', 'Vietnamese / EU'),
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.numberFormat,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...options.map((option) {
                final (value, title, subtitle) = option;
                final isSelected = currentFormat == value;
                return ListTile(
                  onTap: () {
                    ref.read(numberFormatProvider.notifier).setFormat(value);
                    Navigator.pop(ctx);
                  },
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(title, style: AppTextStyles.body3),
                  subtitle: Text(subtitle, style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral600,
                  )),
                );
              }),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final currentNumberFormat = ref.watch(numberFormatProvider);

    final l10n = AppLocalizations.of(context)!;

    // Number format display label
    final numberFormatLabel = currentNumberFormat == 'auto'
        ? 'Auto'
        : currentNumberFormat == 'en_US'
            ? '1,000.50'
            : '1.000,50';

    return SettingsGroupHolder(
      title: l10n.preferences,
      settingTiles: [
        ListTile(
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.languageSettings,
            desktopWidget: const LanguageSettingsScreen(),
          ),
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
          label: l10n.numberFormat,
          icon: HugeIcons.strokeRoundedAbacus,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                numberFormatLabel,
                style: AppTextStyles.body3.copyWith(color: AppColors.neutral600),
              ),
              const Gap(8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          onTap: () => _showNumberFormatPicker(context, ref),
        ),
        MenuTileButton(
          label: l10n.notifications,
          icon: HugeIcons.strokeRoundedNotification01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.notificationSettings,
            desktopWidget: const NotificationSettingsScreen(),
          ),
        ),
        MenuTileButton(
          label: 'AI Model',
          icon: HugeIcons.strokeRoundedAiBrain01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.aiModelSettings,
            desktopWidget: const AIModelSettingsScreen(),
          ),
        ),
        // Auto Transaction - hub for all auto import features
        // Available on all platforms, but some sub-features are platform-specific
        MenuTileButton(
          label: l10n.autoTransaction,
          icon: HugeIcons.strokeRoundedMessage01,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.autoTransactionSettings,
            desktopWidget: const AutoTransactionSettingsScreen(),
          ),
        ),
        // Bot Integration - Telegram & Messenger
        MenuTileButton(
          label: 'Bot Integration',
          icon: HugeIcons.strokeRoundedTelegram,
          onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
            context,
            route: Routes.botIntegration,
            desktopWidget: const BotIntegrationScreen(),
          ),
        ),
      ],
    );
  }
}
