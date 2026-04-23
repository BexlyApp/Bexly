import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/recurring/data/model/recurring_suggestion.dart';

/// Card widget displaying an AI-detected recurring pattern suggestion.
///
/// Shows: AI icon, suggested name, amount, frequency badge, "Add" and "Dismiss" buttons.
class RecurringSuggestionCard extends StatelessWidget {
  final RecurringSuggestion suggestion;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const RecurringSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
    required this.onDismiss,
  });

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'VND': return 'đ';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'KRW': return '₩';
      case 'THB': return '฿';
      case 'IDR': return 'Rp';
      default: return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _getCurrencySymbol(suggestion.currency);
    final formattedAmount = formatCurrency(
      suggestion.amount.toPriceFormat(),
      symbol,
      suggestion.currency,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary600.withAlpha(10),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: AppColors.primary600.withAlpha(40)),
      ),
      child: Row(
        children: [
          // AI icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary600.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAiBrain01,
                color: AppColors.primary600,
                size: 22,
              ),
            ),
          ),
          const Gap(AppSpacing.spacing8),

          // Name + frequency + amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  suggestion.name,
                  style: AppTextStyles.body3.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Row(
                  children: [
                    // Frequency badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary600.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        suggestion.frequencyLabel,
                        style: AppTextStyles.body5.copyWith(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(8),
                    // Amount
                    Flexible(
                      child: AutoSizeText(
                        formattedAmount,
                        style: AppTextStyles.body4.copyWith(
                          color: AppColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          const Gap(AppSpacing.spacing8),
          // Add button
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Add',
                style: AppTextStyles.body4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(4),
          // Dismiss button
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: AppColors.neutral600),
            ),
          ),
        ],
      ),
    );
  }
}
