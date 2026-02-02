import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:intl/intl.dart';

/// Tile widget for displaying a pending transaction with source tag
class PendingTransactionTile extends ConsumerWidget {
  final PendingTransactionModel pending;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const PendingTransactionTile({
    super.key,
    required this.pending,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('pending_${pending.id}'),
      background: _buildSwipeBackground(
        context,
        isApprove: true,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        isApprove: false,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove?.call();
        } else {
          onReject?.call();
        }
        return false; // Don't auto-dismiss, let the callback handle it
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.neutral800 : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
            border: Border.all(
              color: isDark ? AppColors.neutral700 : AppColors.neutral200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Source tag + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSourceTag(context),
                  Text(
                    DateFormat('dd/MM/yyyy').format(pending.transactionDate),
                    style: AppTextStyles.body5.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.spacing8),

              // Main content row
              Row(
                children: [
                  // Source icon
                  _buildSourceIcon(context, isDark),
                  const Gap(AppSpacing.spacing12),

                  // Title and source name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoSizeText(
                          pending.title,
                          style: AppTextStyles.body3.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Flexible(
                              child: AutoSizeText(
                                pending.sourceDisplayName,
                                style: AppTextStyles.body4.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pending.accountIdentifier != null) ...[
                              Text(
                                ' • ',
                                style: AppTextStyles.body5.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                pending.accountIdentifier!,
                                style: AppTextStyles.body5.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${pending.isIncome ? '+' : '-'} ${pending.amount.toPriceFormat()}',
                        style: AppTextStyles.numericMedium.copyWith(
                          color: pending.isIncome
                              ? AppColors.green200
                              : AppColors.red600,
                          height: 1.12,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        pending.currency,
                        style: AppTextStyles.body5.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action buttons row
              const Gap(AppSpacing.spacing12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedCancel01,
                      label: 'Reject',
                      color: AppColors.red600,
                      onTap: onReject,
                    ),
                  ),
                  const Gap(AppSpacing.spacing8),
                  Expanded(
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      label: 'Approve',
                      color: AppColors.green200,
                      isPrimary: true,
                      onTap: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTag(BuildContext context) {
    final (color, bgColor) = _getSourceColors(pending.source);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: _getSourceIcon(pending.source),
            color: color,
            size: 12,
          ),
          const Gap(4),
          Text(
            pending.source.displayName,
            style: AppTextStyles.body5.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceIcon(BuildContext context, bool isDark) {
    final (color, _) = _getSourceColors(pending.source);

    // Try to use source icon URL if available
    if (pending.sourceIconUrl != null && pending.sourceIconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          pending.sourceIconUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(context, isDark, color),
        ),
      );
    }

    return _buildFallbackIcon(context, isDark, color);
  }

  Widget _buildFallbackIcon(BuildContext context, bool isDark, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: HugeIcon(
          icon: _getSourceIcon(pending.source),
          color: color,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required bool isApprove,
    required Alignment alignment,
  }) {
    final color = isApprove ? AppColors.green200 : AppColors.red600;
    final icon = isApprove
        ? HugeIcons.strokeRoundedCheckmarkCircle02
        : HugeIcons.strokeRoundedCancel01;
    final label = isApprove ? 'Approve' : 'Reject';

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isApprove) ...[
            Text(
              label,
              style: AppTextStyles.body3.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
          ],
          HugeIcon(icon: icon, color: color, size: 24),
          if (isApprove) ...[
            const Gap(8),
            Text(
              label,
              style: AppTextStyles.body3.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  dynamic _getSourceIcon(PendingTxSource source) {
    switch (source) {
      case PendingTxSource.email:
        return HugeIcons.strokeRoundedMail01;
      case PendingTxSource.bank:
        return HugeIcons.strokeRoundedBank;
      case PendingTxSource.sms:
        return HugeIcons.strokeRoundedMessage01;
      case PendingTxSource.notification:
        return HugeIcons.strokeRoundedNotification02;
    }
  }

  (Color, Color) _getSourceColors(PendingTxSource source) {
    switch (source) {
      case PendingTxSource.email:
        return (const Color(0xFFEA4335), const Color(0xFFEA4335).withValues(alpha: 0.1));
      case PendingTxSource.bank:
        return (const Color(0xFF635BFF), const Color(0xFF635BFF).withValues(alpha: 0.1));
      case PendingTxSource.sms:
        return (const Color(0xFF34A853), const Color(0xFF34A853).withValues(alpha: 0.1));
      case PendingTxSource.notification:
        return (const Color(0xFFFBBC04), const Color(0xFFFBBC04).withValues(alpha: 0.1));
    }
  }
}

/// Action button for approve/reject
class _ActionButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isPrimary
          ? color
          : (isDark ? AppColors.neutral700 : AppColors.neutral100),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 18,
                color: isPrimary ? Colors.white : color,
              ),
              const Gap(6),
              Text(
                label,
                style: AppTextStyles.body4.copyWith(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
