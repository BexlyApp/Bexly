import 'package:flutter/material.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';

class BudgetTotalCard extends StatelessWidget {
  final double totalAmount;
  final String currencySymbol;
  const BudgetTotalCard({super.key, required this.totalAmount, this.currencySymbol = 'đ'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing8),
      decoration: BoxDecoration(
        color: context.incomeBackground,
        border: Border.all(color: context.incomeLine),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget',
            style: AppTextStyles.body5.copyWith(
              color: context.incomeText,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSpacing.spacing2,
            children: [
              Text(
                currencySymbol,
                style: AppTextStyles.body3.copyWith(color: context.incomeText),
              ),
              Text(
                totalAmount.toPriceFormat(),
                style: AppTextStyles.numericMedium.copyWith(color: context.incomeText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
