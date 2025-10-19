import 'package:flutter/material.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';

class RecurringCard extends StatelessWidget {
  final RecurringModel recurring;
  final VoidCallback? onTap;

  const RecurringCard({
    super.key,
    required this.recurring,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = recurring.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final isDueToday = daysUntilDue == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      recurring.name,
                      style: AppTextStyles.heading4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${recurring.amount.toPriceFormat()} ${recurring.currency}',
                    style: AppTextStyles.heading4.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing8),

              // Category and Wallet
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recurring.category.title,
                    style: AppTextStyles.body4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recurring.wallet.name,
                    style: AppTextStyles.body4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing8),

              // Frequency and Next Due Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Frequency
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recurring.frequency.displayName,
                        style: AppTextStyles.body4.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Next Due Date with status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withOpacity(0.1)
                          : isDueToday
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOverdue
                          ? 'Overdue'
                          : isDueToday
                              ? 'Due Today'
                              : 'Due in $daysUntilDue days',
                      style: AppTextStyles.body5.copyWith(
                        color: isOverdue
                            ? Colors.red
                            : isDueToday
                                ? Colors.orange
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Status badge if not active
              if (recurring.status != RecurringStatus.active) ...[
                const SizedBox(height: AppSpacing.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(recurring.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recurring.status.displayName.toUpperCase(),
                    style: AppTextStyles.body5.copyWith(
                      color: _getStatusColor(recurring.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RecurringStatus status) {
    switch (status) {
      case RecurringStatus.active:
        return Colors.green;
      case RecurringStatus.paused:
        return Colors.orange;
      case RecurringStatus.cancelled:
        return Colors.red;
      case RecurringStatus.expired:
        return Colors.grey;
    }
  }
}
