import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/presentation/components/wallet_type_picker.dart';

/// A form field for selecting wallet type
///
/// Displays the currently selected wallet type and opens
/// a picker bottom sheet when tapped
class WalletTypeSelectorField extends StatelessWidget {
  final WalletType selectedType;
  final Function(WalletType) onTypeChanged;
  final String? label;
  final bool enabled;

  const WalletTypeSelectorField({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController(
      text: '${selectedType.displayName}\n${selectedType.description}',
    );

    return Stack(
      children: [
        CustomTextField(
          context: context,
          controller: controller,
          label: label ?? 'Wallet Type',
          readOnly: true,
          enabled: enabled,
          prefixIcon: _getWalletIcon(selectedType),
          minLines: 2,
          maxLines: 2,
          onTap: enabled
              ? () async {
                  final result = await showWalletTypePicker(
                    context: context,
                    currentType: selectedType,
                  );
                  if (result != null) {
                    onTypeChanged(result);
                  }
                }
              : null,
        ),
        // Arrow icon overlay
        if (enabled)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  IconData _getWalletIcon(WalletType type) {
    switch (type) {
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
        return HugeIcons.strokeRoundedWallet03;
    }
  }
}
