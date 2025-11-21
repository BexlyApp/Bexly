import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

class NotificationListScreen extends HookConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingNotifications = useState<List<PendingNotificationRequest>>([]);
    final isLoading = useState(true);

    // Load pending notifications
    useEffect(() {
      Future<void> loadNotifications() async {
        isLoading.value = true;
        final pending = await NotificationService.getPendingNotifications();
        pendingNotifications.value = pending;
        isLoading.value = false;
      }

      loadNotifications();
      return null;
    }, []);

    return CustomScaffold(
      context: context,
      title: 'Notifications',
      showBalance: false,
      body: isLoading.value
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : pendingNotifications.value.isEmpty
              ? _buildEmptyState(context)
              : _buildNotificationList(context, pendingNotifications.value, ref),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedNotificationOff02,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const Gap(AppSpacing.spacing24),
            Text(
              'No pending notifications',
              style: AppTextStyles.body1.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              'You\'ll see notifications and reminders here',
              style: AppTextStyles.body3.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<PendingNotificationRequest> notifications,
    WidgetRef ref,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Gap(AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, notification, ref);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    PendingNotificationRequest notification,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing8),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedNotification02,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Notification',
                  style: AppTextStyles.heading3.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Gap(AppSpacing.spacing4),
                Text(
                  notification.body ?? '',
                  style: AppTextStyles.body2.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.spacing8),
                Text(
                  'Scheduled',
                  style: AppTextStyles.body4.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              HugeIcons.strokeRoundedDelete02,
              color: AppColors.red,
              size: 20,
            ),
            onPressed: () async {
              await NotificationService.cancelNotification(notification.id);
              // Reload notifications after deletion
              // Trigger rebuild via useState
            },
          ),
        ],
      ),
    );
  }
}
