import 'package:flutter/material.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';

class BudgetTotalCard extends StatelessWidget {
  final double totalAmount;
  final String currencySymbol;
  final String isoCode;
  const BudgetTotalCard({super.key, required this.totalAmount, this.currencySymbol = 'đ', this.isoCode = 'VND'});

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
          Text(
            formatCurrency(totalAmount.toPriceFormat(), currencySymbol, isoCode),
            style: AppTextStyles.numericMedium.copyWith(color: context.incomeText),
          ),
        ],
      ),
    );
  }
}
