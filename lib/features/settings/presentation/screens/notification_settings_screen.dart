import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/services/scheduled_notifications_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Notification settings providers
final notificationRecurringPaymentsProvider = StateProvider<bool>((ref) => true);
final notificationDailyReminderProvider = StateProvider<bool>((ref) => false);
final notificationWeeklyReportProvider = StateProvider<bool>((ref) => false);
final notificationMonthlyReportProvider = StateProvider<bool>((ref) => false);
final notificationGoalMilestonesProvider = StateProvider<bool>((ref) => true);

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
      ref.read(notificationRecurringPaymentsProvider.notifier).state =
          prefs.getBool('notif_recurring_payments') ?? true;
      ref.read(notificationDailyReminderProvider.notifier).state =
          prefs.getBool('notif_daily_reminder') ?? false;
      ref.read(notificationWeeklyReportProvider.notifier).state =
          prefs.getBool('notif_weekly_report') ?? false;
      ref.read(notificationMonthlyReportProvider.notifier).state =
          prefs.getBool('notif_monthly_report') ?? false;
      ref.read(notificationGoalMilestonesProvider.notifier).state =
          prefs.getBool('notif_goal_milestones') ?? true;

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

  Future<void> _toggleSetting(String key, StateProvider<bool> provider, bool value) async {
    if (value) {
      // Request permission when enabling any notification
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        // Permission denied, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission denied. Please enable in system settings.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Update state and save
    ref.read(provider.notifier).state = value;
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
        title: 'Notifications',
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
      title: 'Notifications',
      showBalance: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        children: [
          // Payments & Bills
          _buildSectionTitle('Payments & Bills'),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: 'Recurring Payment Reminders',
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
          _buildSectionTitle('Daily & Weekly'),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: 'Daily Reminder',
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
            title: 'Weekly Report',
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
          _buildSectionTitle('Monthly & Goals'),
          const SizedBox(height: AppSpacing.spacing12),

          _buildNotificationCard(
            title: 'Monthly Report',
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
            title: 'Goal Milestones',
            subtitle: '',
            icon: Icons.emoji_events,
            value: goalMilestones,
            onChanged: (value) => _toggleSetting(
              'notif_goal_milestones',
              notificationGoalMilestonesProvider,
              value,
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
