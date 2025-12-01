import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/features/notification/presentation/riverpod/notification_providers.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(allNotificationsProvider);

    return CustomScaffold(
      context: context,
      title: l10n.notifications,
      showBalance: false,
      actions: notificationsAsync.maybeWhen(
        data: (notifications) => notifications.isNotEmpty
            ? [
                TextButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.clearAllNotifications),
                        content: Text(l10n.areYouSureDeleteAllNotifications),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.clearAll),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final db = ref.read(databaseProvider);
                      await db.notificationDao.deleteAllNotifications();
                    }
                  },
                  icon: const Icon(HugeIcons.strokeRoundedDelete02, size: 18),
                  label: Text(l10n.clearAll),
                ),
              ]
            : null,
        orElse: () => null,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildNotificationList(context, notifications, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${l10n.errorLoadingNotifications}: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              l10n.noNotifications,
              style: AppTextStyles.body1.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              l10n.notificationsSubtitle,
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
    List notifications,
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
    dynamic notification,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isRead = notification.isRead as bool;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.spacing20),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          HugeIcons.strokeRoundedDelete02,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) async {
        final db = ref.read(databaseProvider);
        await db.notificationDao.deleteNotification(notification.id as int);
      },
      child: GestureDetector(
        onTap: () async {
          // Mark as read when tapped
          if (!isRead) {
            final db = ref.read(databaseProvider);
            await db.notificationDao.markAsRead(notification.id as int);
          }
          // TODO: Navigate to related screen based on notification type
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(notification.type as String)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationTypeIcon(notification.type as String),
                  color: _getNotificationTypeColor(notification.type as String),
                  size: 20,
                ),
              ),
              const Gap(AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title as String,
                      style: AppTextStyles.body1.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    const Gap(AppSpacing.spacing4),
                    Text(
                      notification.body as String,
                      style: AppTextStyles.body3.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(AppSpacing.spacing8),
                    Text(
                      _formatNotificationDate(notification.scheduledFor as DateTime?),
                      style: AppTextStyles.body4.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (!isRead)
                    IconButton(
                      icon: Icon(
                        HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        await db.notificationDao.markAsRead(notification.id as int);
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      HugeIcons.strokeRoundedDelete02,
                      color: AppColors.red,
                      size: 20,
                    ),
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await db.notificationDao.deleteNotification(notification.id as int);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'daily_reminder':
        return HugeIcons.strokeRoundedCalendar03;
      case 'weekly_report':
        return HugeIcons.strokeRoundedChart;
      case 'monthly_report':
        return HugeIcons.strokeRoundedCalendar04;
      case 'goal_milestone':
        return HugeIcons.strokeRoundedTarget01;
      case 'recurring_payment':
        return HugeIcons.strokeRoundedRepeat;
      default:
        return HugeIcons.strokeRoundedNotification02;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'daily_reminder':
        return AppColors.primary500;
      case 'weekly_report':
        return AppColors.purple;
      case 'monthly_report':
        return AppColors.secondary500;
      case 'goal_milestone':
        return AppColors.primary700;
      case 'recurring_payment':
        return AppColors.red;
      default:
        return AppColors.neutral500;
    }
  }

  String _formatNotificationDate(DateTime? date) {
    if (date == null) {
      return 'No date';
    }

    final now = DateTime.now();
    final difference = date.difference(now);

    // If in the past
    if (difference.isNegative) {
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes} minutes ago';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours} hours ago';
      } else if (absDifference.inDays < 7) {
        return '${absDifference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    } else {
      // If in the future
      if (difference.inMinutes < 60) {
        return 'In ${difference.inMinutes} minutes';
      } else if (difference.inHours < 24) {
        return 'In ${difference.inHours} hours';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return 'Scheduled for ${DateFormat('MMM d, y').format(date)}';
      }
    }
  }
}
