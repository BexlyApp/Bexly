import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/category_picker/presentation/components/category_icon.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';

class RecurringCard extends StatelessWidget {
  final RecurringModel recurring;
  final VoidCallback? onTap;

  const RecurringCard({
    super.key,
    required this.recurring,
    this.onTap,
  });

  /// Get short currency symbol (e.g., VND -> đ, USD -> $)
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'VND':
        return 'đ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      case 'MYR':
        return 'RM';
      case 'SGD':
        return 'S\$';
      case 'PHP':
        return '₱';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = recurring.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final isDueToday = daysUntilDue == 0;

    // Color scheme based on due status
    final backgroundColor = isOverdue
        ? AppColors.red.withAlpha(15)
        : isDueToday
            ? AppColors.red400.withAlpha(15)
            : AppColors.purple.withAlpha(10);

    final borderColor = isOverdue
        ? AppColors.red.withAlpha(50)
        : isDueToday
            ? AppColors.red400.withAlpha(50)
            : AppColors.purple.withAlpha(30);

    final iconBgColor = isOverdue
        ? AppColors.red.withAlpha(25)
        : isDueToday
            ? AppColors.red400.withAlpha(25)
            : AppColors.purple.withAlpha(20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.only(right: AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Category Icon - flush with left/top/bottom border
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.radius12 - 1),
                  bottomLeft: Radius.circular(AppRadius.radius12 - 1),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CategoryIcon(
                    iconType: recurring.category.iconType,
                    icon: recurring.category.icon,
                    iconBackground: recurring.category.iconBackground,
                  ),
                ),
              ),
            ),
            const Gap(AppSpacing.spacing8),

            // Title, Category
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          recurring.name,
                          style: AppTextStyles.body3.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(AppSpacing.spacing2),
                        Row(
                          children: [
                            Flexible(
                              child: AutoSizeText(
                                recurring.category.title,
                                style: AppTextStyles.body4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(AppSpacing.spacing8),
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const Gap(AppSpacing.spacing4),
                            Flexible(
                              child: AutoSizeText(
                                recurring.frequency.displayName,
                                style: AppTextStyles.body4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount and Due Status
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Due status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? AppColors.red.withAlpha(25)
                              : isDueToday
                                  ? AppColors.red400.withAlpha(25)
                                  : AppColors.green200.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOverdue
                              ? 'Overdue'
                              : isDueToday
                                  ? 'Due Today'
                                  : 'Due in $daysUntilDue days',
                          style: AppTextStyles.body5.copyWith(
                            color: isOverdue
                                ? AppColors.red
                                : isDueToday
                                    ? AppColors.red400
                                    : AppColors.green200,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const Gap(AppSpacing.spacing4),

                      // Amount with +/- sign based on transaction type
                      AutoSizeText(
                        '${recurring.category.transactionType == 'income' ? '+' : '-'}${formatCurrency(recurring.amount.toPriceFormat(), _getCurrencySymbol(recurring.currency), recurring.currency)}',
                        style: AppTextStyles.numericRegular.copyWith(
                          color: recurring.category.transactionType == 'income'
                              ? AppColors.green200
                              : AppColors.red700,
                          height: 1.12,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
