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
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';

class TransactionSummaryCard extends ConsumerWidget {
  final List<TransactionModel> transactions;
  const TransactionSummaryCard({super.key, required this.transactions});

  /// Calculate totals with currency conversion to base currency
  Future<({double income, double expenses})> _calculateConvertedTotals(
    List<TransactionModel> transactions,
    String baseCurrency,
    ExchangeRateCacheNotifier rateCache,
  ) async {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final t in transactions) {
      final txCurrency = t.wallet.currency;
      double amount = t.amount;

      // Convert to base currency if different
      if (txCurrency != baseCurrency) {
        try {
          final rate = await rateCache.getRate(txCurrency, baseCurrency);
          amount = t.amount * rate;
        } catch (e) {
          // If conversion fails, use original amount (not ideal but prevents crash)
          amount = t.amount;
        }
      }

      if (t.transactionType == TransactionType.income) {
        totalIncome += amount;
      } else if (t.transactionType == TransactionType.expense) {
        totalExpenses += amount;
      }
    }

    return (income: totalIncome, expenses: totalExpenses);
  }

  @override
  Widget build(BuildContext context, ref) {
    // Use base currency for display
    final baseCurrency = ref.read(baseCurrencyProvider);
    final currencies = ref.read(currenciesStaticProvider);
    final currency = currencies.fromIsoCode(baseCurrency)?.symbol ?? '\$';
    final rateCache = ref.read(exchangeRateCacheProvider.notifier);

    return FutureBuilder<({double income, double expenses})>(
      future: _calculateConvertedTotals(transactions, baseCurrency, rateCache),
      builder: (context, snapshot) {
        // Use converted values, fallback to 0 while loading
        final income = snapshot.data?.income ?? 0;
        final expenses = snapshot.data?.expenses ?? 0;
        final total = income - expenses;

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
                      formatCurrency(income.toPriceFormat(), currency, baseCurrency),
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
                      '- ${formatCurrency(expenses.toPriceFormat(), currency, baseCurrency)}',
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
                      formatCurrency(total.toPriceFormat(), currency, baseCurrency),
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
      },
    );
  }
}
