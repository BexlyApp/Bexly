import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';

class TransactionWalletSelector extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(WalletModel wallet) onWalletSelected;
  final WalletModel? selectedWallet;
  final bool isEditing;

  const TransactionWalletSelector({
    super.key,
    required this.controller,
    required this.onWalletSelected,
    this.selectedWallet,
    this.isEditing = false,
  });

  List<List> _getWalletIcon() {
    if (selectedWallet == null) {
      return HugeIcons.strokeRoundedWallet01;
    }

    switch (selectedWallet!.walletType) {
      case WalletType.cash:
        return HugeIcons.strokeRoundedMoney02;
      case WalletType.bankAccount:
        return HugeIcons.strokeRoundedBank;
      case WalletType.creditCard:
        return HugeIcons.strokeRoundedCreditCard;
      case WalletType.eWallet:
        return HugeIcons.strokeRoundedMoney04;
      case WalletType.investment:
        return HugeIcons.strokeRoundedChart;
      case WalletType.savings:
        return HugeIcons.strokeRoundedPiggyBank;
      case WalletType.insurance:
        return HugeIcons.strokeRoundedSecurityCheck;
      case WalletType.other:
      default:
        return HugeIcons.strokeRoundedWallet03;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomSelectField(
      context: context,
      controller: controller,
      label: 'Wallet',
      hint: 'Select Wallet',
      prefixIcon: _getWalletIcon(),
      isRequired: true,
      onTap: () async {
        await showModalBottomSheet<WalletModel>(
          context: context,
          isScrollControlled: true,
          builder: (context) => WalletSelectorBottomSheet(
            currentlySelectedWallet: selectedWallet,
            filterByCurrency: isEditing ? selectedWallet?.currency : null,
            onWalletSelected: (wallet) {
              onWalletSelected.call(wallet);
            },
          ),
        );
      },
    );
  }
}
