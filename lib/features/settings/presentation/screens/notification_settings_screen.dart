import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/services/scheduled_notifications_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

/// Notification settings notifiers
class NotificationSettingNotifier extends Notifier<bool> {
  final bool defaultValue;

  NotificationSettingNotifier({this.defaultValue = false});

  @override
  bool build() => defaultValue;

  void setValue(bool value) => state = value;
}

final notificationRecurringPaymentsProvider = NotifierProvider<NotificationSettingNotifier, bool>(
  () => NotificationSettingNotifier(defaultValue: true),
);
final notificationDailyReminderProvider = NotifierProvider<NotificationSettingNotifier, bool>(
  () => NotificationSettingNotifier(defaultValue: false),
);
final notificationWeeklyReportProvider = NotifierProvider<NotificationSettingNotifier, bool>(
  () => NotificationSettingNotifier(defaultValue: false),
);
final notificationMonthlyReportProvider = NotifierProvider<NotificationSettingNotifier, bool>(
  () => NotificationSettingNotifier(defaultValue: false),
);
final notificationGoalMilestonesProvider = NotifierProvider<NotificationSettingNotifier, bool>(
  () => NotificationSettingNotifier(defaultValue: true),
);

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load all notification settings
      ref.read(notificationRecurringPaymentsProvider.notifier).setValue(
          prefs.getBool('notif_recurring_payments') ?? true);
      ref.read(notificationDailyReminderProvider.notifier).setValue(
          prefs.getBool('notif_daily_reminder') ?? false);
      ref.read(notificationWeeklyReportProvider.notifier).setValue(
          prefs.getBool('notif_weekly_report') ?? false);
      ref.read(notificationMonthlyReportProvider.notifier).setValue(
          prefs.getBool('notif_monthly_report') ?? false);
      ref.read(notificationGoalMilestonesProvider.notifier).setValue(
          prefs.getBool('notif_goal_milestones') ?? true);

      setState(() => _isLoading = false);
    } catch (e) {
      Log.e('Failed to load notification settings: $e', label: 'notification');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      Log.d('Saved $key: $value', label: 'notification');
    } catch (e) {
      Log.e('Failed to save notification setting: $e', label: 'notification');
    }
  }

  Future<void> _toggleSetting(String key, NotifierProvider<NotificationSettingNotifier, bool> provider, bool value) async {
    if (value) {
      // Request permission when enabling any notification
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        // Permission denied, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.notificationPermissionDenied),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Update state and save
    ref.read(provider.notifier).setValue(value);
    await _saveSetting(key, value);

    // Schedule/cancel notifications based on type
    if (key == 'notif_daily_reminder') {
      await ScheduledNotificationsService.scheduleDailyReminder();
    } else if (key == 'notif_weekly_report') {
      await ScheduledNotificationsService.scheduleWeeklyReport();
    } else if (key == 'notif_monthly_report') {
      await ScheduledNotificationsService.scheduleMonthlyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CustomScaffold(
        context: context,
        title: context.l10n.notifications,
        showBalance: false,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recurringPayments = ref.watch(notificationRecurringPaymentsProvider);
    final dailyReminder = ref.watch(notificationDailyReminderProvider);
    final weeklyReport = ref.watch(notificationWeeklyReportProvider);
    final monthlyReport = ref.watch(notificationMonthlyReportProvider);
    final goalMilestones = ref.watch(notificationGoalMilestonesProvider);

    return CustomScaffold(
      context: context,
      title: context.l10n.notifications,
      showBalance: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        children: [
          // Payments & Bills
          _buildSectionTitle(context.l10n.paymentsAndBills),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: context.l10n.recurringPaymentReminders,
            subtitle: '',
            icon: Icons.event_repeat,
            value: recurringPayments,
            onChanged: (value) => _toggleSetting(
              'notif_recurring_payments',
              notificationRecurringPaymentsProvider,
              value,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing24),

          // Daily & Weekly
          _buildSectionTitle(context.l10n.dailyAndWeekly),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: context.l10n.dailyReminder,
            subtitle: '',
            icon: Icons.today,
            value: dailyReminder,
            onChanged: (value) => _toggleSetting(
              'notif_daily_reminder',
              notificationDailyReminderProvider,
              value,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: context.l10n.weeklyReport,
            subtitle: '',
            icon: Icons.assessment,
            value: weeklyReport,
            onChanged: (value) => _toggleSetting(
              'notif_weekly_report',
              notificationWeeklyReportProvider,
              value,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing24),

          // Monthly & Goals
          _buildSectionTitle(context.l10n.monthlyAndGoals),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: context.l10n.monthlyReport,
            subtitle: '',
            icon: Icons.calendar_month,
            value: monthlyReport,
            onChanged: (value) => _toggleSetting(
              'notif_monthly_report',
              notificationMonthlyReportProvider,
              value,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: context.l10n.goalMilestones,
            subtitle: '',
            icon: Icons.emoji_events,
            value: goalMilestones,
            onChanged: (value) => _toggleSetting(
              'notif_goal_milestones',
              notificationGoalMilestonesProvider,
              value,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing24),

          // Test notification button
          ElevatedButton.icon(
            onPressed: () async {
              await NotificationService.showInstantNotification(
                id: 99999,
                title: context.l10n.testNotification,
                body: context.l10n.testNotificationBody,
              );
            },
            icon: const Icon(Icons.notifications_active),
            label: Text(context.l10n.testNotification),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading5.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool comingSoon = false,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).colorScheme.primary : AppColors.neutral400,
        ),
        title: Text(
          title,
          style: AppTextStyles.body3.copyWith(
            fontWeight: FontWeight.w600,
            color: comingSoon ? AppColors.neutral400 : null,
          ),
        ),
        value: value,
        onChanged: comingSoon ? null : onChanged,
      ),
    );
  }
}
