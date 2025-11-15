import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';

class TransactionWalletSelector extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(WalletModel wallet) onWalletSelected;
  final WalletModel? selectedWallet;

  const TransactionWalletSelector({
    super.key,
    required this.controller,
    required this.onWalletSelected,
    this.selectedWallet,
  });

  IconData _getWalletIcon() {
    if (selectedWallet == null) {
      return Icons.account_balance_wallet;
    }

    switch (selectedWallet!.walletType) {
      case WalletType.cash:
        return Icons.payments;
      case WalletType.bankAccount:
        return Icons.account_balance;
      case WalletType.creditCard:
        return Icons.credit_card;
      case WalletType.eWallet:
        return Icons.phone_iphone;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.savings:
        return Icons.savings;
      case WalletType.insurance:
        return Icons.security;
      case WalletType.other:
      default:
        return Icons.account_balance_wallet;
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
            onWalletSelected: (wallet) {
              onWalletSelected.call(wallet);
            },
          ),
        );
      },
    );
  }
}
