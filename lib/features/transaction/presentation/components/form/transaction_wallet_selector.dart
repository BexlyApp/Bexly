import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

class TransactionWalletSelector extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(WalletModel wallet) onWalletSelected;

  const TransactionWalletSelector({
    super.key,
    required this.controller,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomSelectField(
      context: context,
      controller: controller,
      label: 'Wallet',
      hint: 'Select Wallet',
      isRequired: true,
      onTap: () async {
        final wallet = await showModalBottomSheet<WalletModel>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const WalletSelectorBottomSheet(),
        );

        if (wallet != null) {
          onWalletSelected.call(wallet);
        }
      },
    );
  }
}
