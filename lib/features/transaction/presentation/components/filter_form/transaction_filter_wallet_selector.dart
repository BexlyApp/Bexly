import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';

class TransactionFilterWalletSelector extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(WalletModel? wallet) onWalletSelected;

  const TransactionFilterWalletSelector({
    super.key,
    required this.controller,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomSelectField(
      context: context,
      controller: controller,
      label: context.l10n.wallet,
      hint: context.l10n.allWallets,
      isRequired: false,
      onTap: () async {
        await showModalBottomSheet<WalletModel>(
          context: context,
          isScrollControlled: true,
          builder: (context) => WalletSelectorBottomSheet(
            onWalletSelected: (wallet) {
              onWalletSelected(wallet);
            },
          ),
        );
      },
    );
  }
}
