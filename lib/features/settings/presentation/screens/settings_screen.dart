import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/circle_button.dart';
import 'package:bexly/core/components/buttons/menu_tile_button.dart';
import 'package:bexly/core/components/chips/custom_currency_chip.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_constants.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:bexly/core/services/url_launcher/url_launcher.dart';
import 'package:bexly/core/utils/desktop_dialog_helper.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/core/riverpod/auth_providers.dart' as firebase_auth;
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/category_picker/presentation/screens/category_picker_screen.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/developer_portal/presentation/screens/developer_portal_screen.dart';
import 'package:bexly/features/settings/presentation/components/report_log_file_dialog.dart';
import 'package:bexly/features/settings/presentation/components/settings_group_holder.dart';
import 'package:bexly/features/settings/presentation/riverpod/language_provider.dart';
import 'package:bexly/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:bexly/features/settings/presentation/screens/ai_model_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/auto_transaction_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:bexly/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/personal_details_screen.dart';
import 'package:bexly/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:bexly/features/theme_switcher/presentation/components/theme_mode_switcher.dart';
import 'package:bexly/features/wallet/screens/wallets_screen.dart';
import 'package:bexly/core/services/sync/sync_trigger_service.dart';
import 'package:bexly/features/settings/presentation/components/bind_account_bottom_sheet.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/components/ads/native_ad_widget.dart';

part '../components/app_version_info.dart';
part '../components/profile_card.dart';
part '../components/settings_app_info_group.dart';
part '../components/settings_data_group.dart';
part '../components/settings_finance_group.dart';
part '../components/settings_preferences_group.dart';
part '../components/settings_profile_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      context: context,
      title: context.l10n.settings,
      showBackButton: true,
      showBalance: false,
      actions: [ThemeModeSwitcher()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          children: const [
            ProfileCard(),
            SettingsProfileGroup(),
            SettingsPreferencesGroup(),
            NativeAdWidget(),
            SettingsFinanceGroup(),
            SettingsDataGroup(),
            SettingsAppInfoGroup(),
            AppVersionInfo(),
          ],
        ),
      ),
    );
  }
}
