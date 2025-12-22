import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/developer_portal/presentation/screens/developer_portal_screen.dart';
import 'package:bexly/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:bexly/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:bexly/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/auto_transaction_settings_screen.dart';
import 'package:bexly/features/email_sync/presentation/screens/email_sync_settings_screen.dart';
import 'package:bexly/features/email_sync/presentation/screens/email_review_screen.dart';
import 'package:bexly/features/bank_connections/presentation/screens/bank_connections_screen.dart';
import 'package:bexly/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/personal_details_screen.dart';
import 'package:bexly/features/settings/presentation/screens/settings_screen.dart';
import 'package:bexly/features/settings/presentation/screens/ai_model_settings_screen.dart';
import 'package:bexly/features/subscription/presentation/screens/subscription_screen.dart';

class SettingsRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.personalDetails,
      builder: (context, state) => const PersonalDetailsScreen(),
    ),
    GoRoute(
      path: Routes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: Routes.autoTransactionSettings,
      builder: (context, state) => const AutoTransactionSettingsScreen(),
    ),
    GoRoute(
      path: Routes.emailSyncSettings,
      builder: (context, state) => const EmailSyncSettingsScreen(),
    ),
    GoRoute(
      path: Routes.emailReview,
      builder: (context, state) => const EmailReviewScreen(),
    ),
    GoRoute(
      path: Routes.bankConnections,
      builder: (context, state) => const BankConnectionsScreen(),
    ),
    GoRoute(
      path: Routes.languageSettings,
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: Routes.aiModelSettings,
      builder: (context, state) => const AIModelSettingsScreen(),
    ),
    GoRoute(
      path: Routes.backupAndRestore,
      builder: (context, state) => const BackupRestoreScreen(),
    ),
    GoRoute(
      path: Routes.accountDeletion,
      builder: (context, state) => const AccountDeletionScreen(),
    ),
    GoRoute(
      path: Routes.subscription,
      builder: (context, state) => const SubscriptionScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: Routes.developerPortal,
        builder: (context, state) => const DeveloperPortalScreen(),
      ),
  ];
}
