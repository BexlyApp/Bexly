import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';

class TransactionAmountField extends HookConsumerWidget {
  final TextEditingController controller;
  final bool autofocus;
  final String? currencySymbol;

  const TransactionAmountField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomNumericField(
      controller: controller,
      label: 'Amount',
      hint: '1,000.00',
      icon: HugeIcons.strokeRoundedMoney03,
      autofocus: autofocus,
      isRequired: true,
      appendCurrencySymbolToHint: true,
      defaultCurreny: currencySymbol,
    );
  }
}
