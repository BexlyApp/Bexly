import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
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
                PopupMenuButton<String>(
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical as dynamic),
                  onSelected: (value) async {
                    final db = ref.read(databaseProvider);
                    if (value == 'mark_all_read') {
                      await db.notificationDao.markAllAsRead();
                    } else if (value == 'delete_all') {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        builder: (dialogContext) => AlertBottomSheet(
                          context: dialogContext,
                          title: l10n.clearAllNotifications,
                          content: Text(
                            l10n.areYouSureDeleteAllNotifications,
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                          cancelText: l10n.cancel,
                          confirmText: l10n.clearAll,
                          onConfirm: () async {
                            final navigator = Navigator.of(dialogContext);
                            await db.notificationDao.deleteAllNotifications();
                            navigator.pop();
                          },
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01 as dynamic, size: 18),
                          const Gap(8),
                          Text(l10n.markAllAsRead),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedDelete02 as dynamic, size: 18, color: AppColors.red),
                          const Gap(8),
                          Text(l10n.clearAll, style: TextStyle(color: AppColors.red)),
                        ],
                      ),
                    ),
                  ],
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
            HugeIcon(
              icon: HugeIcons.strokeRoundedNotificationOff02 as dynamic,
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
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02 as dynamic,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRead
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(notification.type as String)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: HugeIcon(
                  icon: _getNotificationTypeIcon(notification.type as String),
                  color: _getNotificationTypeColor(notification.type as String),
                  size: 16,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title as String,
                            style: AppTextStyles.body3.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _formatNotificationDate(notification.scheduledFor as DateTime?),
                          style: AppTextStyles.body5.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const Gap(2),
                    Text(
                      notification.body as String,
                      style: AppTextStyles.body4.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  dynamic _getNotificationTypeIcon(String type) {
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
      return '';
    }

    final now = DateTime.now();
    final difference = date.difference(now);

    // If in the past
    if (difference.isNegative) {
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 1) {
        return 'Now';
      } else if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes}m ago';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours}h ago';
      } else if (absDifference.inDays < 7) {
        return '${absDifference.inDays}d ago';
      } else {
        return _capitalizeDate(DateFormat('MMM d').format(date));
      }
    } else {
      // If in the future
      if (difference.inMinutes < 60) {
        return 'In ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return 'In ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays}d';
      } else {
        return _capitalizeDate(DateFormat('MMM d').format(date));
      }
    }
  }

  /// Capitalize the first letter of date string (fixes "thg" -> "Thg" for Vietnamese)
  String _capitalizeDate(String date) {
    if (date.isEmpty) return date;
    return date[0].toUpperCase() + date.substring(1);
  }
}
