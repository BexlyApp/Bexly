import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
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

    return InkWell(
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.neutral600,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Icon(
              _getWalletIcon(selectedType),
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),

            // Type name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(
                      label!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    selectedType.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedType.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow icon
            if (enabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
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
