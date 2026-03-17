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
import 'package:bexly/core/extensions/localization_extension.dart';
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
        padding: const EdgeInsets.only(right: AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          border: Border.all(color: borderColor),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Icon - flush with left/top/bottom border
              Container(
                width: 70,
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

              // Content: 3 rows
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Name only (can be long)
                      AutoSizeText(
                        recurring.name,
                        style: AppTextStyles.body3.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(AppSpacing.spacing2),

                      // Row 2: Category + Amount
                      Row(
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              recurring.category.title,
                              style: AppTextStyles.body4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      const Gap(AppSpacing.spacing2),

                      // Row 3: Frequency + Due badge
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const Gap(AppSpacing.spacing4),
                          Text(
                            recurring.frequency.localizedName(context),
                            style: AppTextStyles.body5.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
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
                                  ? context.l10n.overdue
                                  : isDueToday
                                      ? context.l10n.dueToday
                                      : context.l10n.dueInDays(daysUntilDue),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
