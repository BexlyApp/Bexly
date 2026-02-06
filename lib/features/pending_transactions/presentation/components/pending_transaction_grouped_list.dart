import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/pending_transactions/presentation/components/pending_transaction_tile.dart';

/// Grouped list of pending transactions by date
/// Similar to TransactionGroupedCard but for pending transactions
class PendingTransactionGroupedList extends ConsumerWidget {
  final List<PendingTransactionModel> pendingTransactions;
  final void Function(PendingTransactionModel) onApprove;
  final void Function(PendingTransactionModel) onReject;
  final void Function(PendingTransactionModel) onTap;

  const PendingTransactionGroupedList({
    super.key,
    required this.pendingTransactions,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.read(baseCurrencyProvider);
    final currencies = ref.read(currenciesStaticProvider);
    final currencyData = currencies.fromIsoCode(baseCurrency);
    final currencySymbol = currencyData?.symbol ?? 'đ';

    // 1. Group transactions by date (ignoring time)
    final Map<DateTime, List<PendingTransactionModel>> groupedByDate = {};
    for (final pending in pendingTransactions) {
      final dateKey = DateTime(
        pending.transactionDate.year,
        pending.transactionDate.month,
        pending.transactionDate.day,
      );
      groupedByDate.putIfAbsent(dateKey, () => []).add(pending);
    }

    // 2. Sort date keys in descending order (most recent first)
    final sortedDateKeys = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // 3. Build ListView for these groups
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDateKeys[index];
        final pendingForDay = groupedByDate[dateKey]!
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        final String displayDate = dateKey.toRelativeDayFormatted();

        // Calculate day total
        double dayTotal = 0;
        for (final p in pendingForDay) {
          if (p.isIncome) {
            dayTotal += p.amount;
          } else {
            dayTotal -= p.amount;
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header row with total
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: Row(
                children: [
                  Text(displayDate, style: AppTextStyles.body2.bold),
                  Expanded(
                    child: Text(
                      formatAmountWithCurrency(
                        amount: dayTotal,
                        symbol: currencySymbol,
                        isoCode: baseCurrency,
                        decimalDigits: currencyData?.decimalDigits ?? 0,
                      ),
                      textAlign: TextAlign.end,
                      style: AppTextStyles.numericMedium.copyWith(
                        color: dayTotal > 0
                            ? AppColors.green200
                            : (dayTotal < 0 ? AppColors.red700 : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pending transactions list for the day
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingForDay.length,
              itemBuilder: (context, itemIndex) {
                final item = pendingForDay[itemIndex];
                return PendingTransactionTile(
                  pending: item,
                  onApprove: () => onApprove(item),
                  onReject: () => onReject(item),
                  onTap: () => onTap(item),
                );
              },
              separatorBuilder: (context, itemIndex) =>
                  const Gap(AppSpacing.spacing8),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => const Gap(AppSpacing.spacing16),
    );
  }
}
