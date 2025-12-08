import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/buttons/button_chip.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';

class TransactionFilterTypeSelector extends ConsumerWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeSelected;

  const TransactionFilterTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: AppSpacing.spacing4,
      children: TransactionType.values.map((type) {
        String label;
        switch (type) {
          case TransactionType.income:
            label = context.l10n.income;
            break;
          case TransactionType.expense:
            label = context.l10n.expense;
            break;
          case TransactionType.transfer:
            label = context.l10n.transfer;
            break;
        }
        return Expanded(
          child: ButtonChip(
            label: label,
            active: selectedType == type,
            onTap: () => onTypeSelected(type),
          ),
        );
      }).toList(),
    );
  }
}
