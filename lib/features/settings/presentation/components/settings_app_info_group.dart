part of '../screens/settings_screen.dart';

final logoutKey = GlobalKey<NavigatorState>();

class SettingsAppInfoGroup extends ConsumerWidget {
  const SettingsAppInfoGroup({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return SettingsGroupHolder(
      title: context.l10n.appInfo,
      settingTiles: [
        MenuTileButton(
          label: context.l10n.privacyPolicy,
          icon: HugeIcons.strokeRoundedLegalHammer,
          suffixIcon: HugeIcons.strokeRoundedSquareArrowUpRight,
          onTap: () {
            LinkLauncher.launch(AppConstants.privacyPolicyUrl);
          },
        ),
        MenuTileButton(
          label: context.l10n.termsAndConditions,
          icon: HugeIcons.strokeRoundedFileExport,
          suffixIcon: HugeIcons.strokeRoundedSquareArrowUpRight,
          onTap: () {
            LinkLauncher.launch(AppConstants.termsAndConditionsUrl);
          },
        ),
        MenuTileButton(
          label: context.l10n.reportLogFile,
          icon: HugeIcons.strokeRoundedFileCorrupt,
          onTap: () => context.openBottomSheet(child: ReportLogFileDialog()),
        ),
        if (kDebugMode)
          MenuTileButton(
            label: context.l10n.developerPortal,
            icon: HugeIcons.strokeRoundedCode,
            onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
              context,
              route: Routes.developerPortal,
              desktopWidget: const DeveloperPortalScreen(),
            ),
          ),
      ],
    );
  }
}
