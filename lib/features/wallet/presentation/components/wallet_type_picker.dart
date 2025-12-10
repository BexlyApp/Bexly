import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';

/// A picker widget for selecting wallet type
///
/// Displays all available wallet types in a grid layout
/// with icons and descriptions
class WalletTypePicker extends StatelessWidget {
  final WalletType selectedType;
  final Function(WalletType) onTypeSelected;

  const WalletTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Wallet Type',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wallet type grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: WalletType.values.length,
              itemBuilder: (context, index) {
                final type = WalletType.values[index];
                final isSelected = type == selectedType;

                return _WalletTypeCard(
                  type: type,
                  isSelected: isSelected,
                  onTap: () {
                    onTypeSelected(type);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTypeCard extends StatelessWidget {
  final WalletType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalletTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: _getWalletIcon(type),
              size: 28,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              type.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<List<dynamic>> _getWalletIcon(WalletType type) {
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

/// Shows wallet type picker as a bottom sheet
Future<WalletType?> showWalletTypePicker({
  required BuildContext context,
  required WalletType currentType,
}) {
  return showModalBottomSheet<WalletType>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: WalletTypePicker(
        selectedType: currentType,
        onTypeSelected: (type) => Navigator.pop(context, type),
      ),
    ),
  );
}
