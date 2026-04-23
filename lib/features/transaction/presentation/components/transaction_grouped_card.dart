import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_tile.dart';

class TransactionGroupedCard extends ConsumerWidget {
  final List<TransactionModel> transactions;
  const TransactionGroupedCard({super.key, required this.transactions});

  /// Calculate day total with currency conversion to base currency
  Future<double> _calculateDayTotal(
    List<TransactionModel> transactionsForDay,
    String baseCurrency,
    ExchangeRateCacheNotifier rateCache,
  ) async {
    double total = 0;

    for (final t in transactionsForDay) {
      final txCurrency = t.wallet.currency;
      double amount = t.amount;

      // Convert to base currency if different
      if (txCurrency != baseCurrency) {
        try {
          final rate = await rateCache.getRate(txCurrency, baseCurrency);
          amount = t.amount * rate;
        } catch (e) {
          // If conversion fails, skip this transaction in total
          continue;
        }
      }

      if (t.transactionType == TransactionType.income) {
        total += amount;
      } else if (t.transactionType == TransactionType.expense) {
        total -= amount;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use base currency for display (consistent across all wallets)
    final baseCurrency = ref.read(baseCurrencyProvider);
    final currencies = ref.read(currenciesStaticProvider);
    final currency = currencies.fromIsoCode(baseCurrency)?.symbol ?? '\$';
    final rateCache = ref.read(exchangeRateCacheProvider.notifier);

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing20,
          vertical: AppSpacing.spacing40,
        ),
        child: Center(
          child: Text(
            context.l10n.noTransactionsToDisplay,
            style: AppTextStyles.body3,
          ),
        ),
      );
    }

    // 1. Group transactions by date (ignoring time)
    final Map<DateTime, List<TransactionModel>> groupedByDate = {};
    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      groupedByDate.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // 2. Sort date keys in descending order (most recent first)
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // 3. Build a ListView for these groups
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDateKeys[index];
        final transactionsForDay = groupedByDate[dateKey]!
          ..sort((a, b) => b.date.compareTo(a.date)); // Sort transactions within each day (newest first)

        final String displayDate = dateKey.toRelativeDayFormatted();

        // No box container - just date header and transactions list
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header row with async total calculation
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: Row(
                children: [
                  Text(displayDate, style: AppTextStyles.body2.bold),
                  Expanded(
                    child: FutureBuilder<double>(
                      future: _calculateDayTotal(transactionsForDay, baseCurrency, rateCache),
                      builder: (context, snapshot) {
                        final dayTotal = snapshot.data ?? 0;
                        return Text(
                          formatCurrency(dayTotal.toPriceFormat(), currency, baseCurrency),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.numericMedium.copyWith(
                            color: dayTotal > 0
                                ? AppColors.green200
                                : (dayTotal < 0
                                      ? AppColors.red700
                                      : null), // Neutral for zero
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Transactions list for the day
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactionsForDay.length,
              itemBuilder: (context, itemIndex) {
                final transaction = transactionsForDay[itemIndex];
                return TransactionTile(
                  transaction: transaction,
                  showDate: false, // Date is in the group header
                );
              },
              separatorBuilder: (context, itemIndex) =>
                  const Gap(AppSpacing.spacing8),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => const Gap(AppSpacing.spacing12),
    );
  }
}
