import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/components/buttons/small_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';

class TransactionSummaryCard extends ConsumerWidget {
  final List<TransactionModel> transactions;
  const TransactionSummaryCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, ref) {
    // Use base currency for display
    final baseCurrency = ref.read(baseCurrencyProvider);
    final currencies = ref.read(currenciesStaticProvider);
    final currency = currencies.fromIsoCode(baseCurrency)?.symbol ?? '\$';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        border: Border.all(color: context.purpleBorderLighter),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.earning, style: AppTextStyles.body3),
              Expanded(
                child: Text(
                  '$currency ${transactions.totalIncome.toPriceFormat()}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.numericMedium.copyWith(
                    color: context.incomeText,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.spending, style: AppTextStyles.body3),
              Expanded(
                child: Text(
                  '- $currency ${transactions.totalExpenses.toPriceFormat()}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.numericMedium.copyWith(
                    color: context.expenseText,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: context.breakLineColor, thickness: 1, height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.total,
                style: AppTextStyles.body3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  '$currency ${transactions.total.toPriceFormat()}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.numericMedium,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing4),
          SmallButton(
            label: context.l10n.viewFullReport,
            backgroundColor: context.purpleButtonBackground,
            borderColor: context.purpleButtonBorder,
            foregroundColor: context.secondaryText,
            labelTextStyle: AppTextStyles.body5,
            onTap: () => context.push(
              Routes.basicMonthlyReports,
              extra: transactions.first.date,
            ),
          ),
        ],
      ),
    );
  }
}
