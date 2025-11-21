import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

class WalletSelectorBottomSheet extends ConsumerWidget {
  final Function(WalletModel)? onWalletSelected;
  final WalletModel? currentlySelectedWallet;
  final String? filterByCurrency; // Only show wallets with this currency
  const WalletSelectorBottomSheet({
    super.key,
    this.onWalletSelected,
    this.currentlySelectedWallet,
    this.filterByCurrency,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);
    final selectedWallet = currentlySelectedWallet ?? ref.watch(dashboardWalletFilterProvider);

    // If used in form context (onWalletSelected provided), hide "Total Balance"
    final bool isFormContext = onWalletSelected != null;

    return CustomBottomSheet(
      title: 'Select Wallet',
      subtitle: filterByCurrency != null
          ? 'You can only switch to wallets with the same currency'
          : null,
      child: allWalletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spacing16),
                child: Text('No wallets available.'),
              ),
            );
          }
          // Check if currently showing total (selectedWallet is null)
          final isShowingTotal = selectedWallet == null;

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // If form context: show only wallets, else show "Total" + wallets
            itemCount: isFormContext ? wallets.length : wallets.length + 1,
            itemBuilder: (context, index) {
              // First item is "Total (All Wallets)" - only if NOT form context
              if (!isFormContext && index == 0) {
                return ListTile(
                  title: Text('Total Balance', style: AppTextStyles.body1),
                  dense: true,
                  leading: const Icon(HugeIcons.strokeRoundedWallet01),
                  subtitle: Text(
                    'View combined balance from all wallets',
                    style: AppTextStyles.body3,
                  ),
                  trailing: Icon(
                    isShowingTotal
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedCircle,
                    color: isShowingTotal ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    if (isShowingTotal) {
                      context.pop(); // Already showing total, just close
                      return;
                    }

                    // Set filter to null to show total
                    ref.read(dashboardWalletFilterProvider.notifier).state = null;
                    context.pop(); // Close the bottom sheet
                  },
                );
              }

              // Other items are individual wallets
              // If form context: use index directly, else -1 for "Total" offset
              final walletIndex = isFormContext ? index : index - 1;
              final wallet = wallets[walletIndex];
              final bool isSelected = selectedWallet?.id == wallet.id;

              // Check if wallet has different currency (when editing)
              final bool isDifferentCurrency = filterByCurrency != null &&
                  wallet.currency != filterByCurrency;
              final bool isDisabled = isDifferentCurrency;

              return Opacity(
                opacity: isDisabled ? 0.4 : 1.0,
                child: ListTile(
                  title: Text(
                    wallet.name,
                    style: AppTextStyles.body1.copyWith(
                      color: isDisabled ? Colors.grey : null,
                    ),
                  ),
                  dense: true,
                  leading: Icon(
                    _getWalletTypeIcon(wallet.walletType),
                    color: isDisabled ? Colors.grey : null,
                  ),
                  subtitle: Text(
                    '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}',
                    style: AppTextStyles.body3.copyWith(
                      color: isDisabled ? Colors.grey : null,
                    ),
                  ),
                  trailing: Icon(
                    isSelected
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedCircle,
                    color: isDisabled
                        ? Colors.grey
                        : (isSelected ? Colors.green : Colors.grey),
                  ),
                  enabled: !isDisabled,
                  onTap: isDisabled
                      ? null
                      : () {
                          // If callback provided, just call it (for budget form use)
                          if (onWalletSelected != null) {
                            onWalletSelected!(wallet);
                            context.pop();
                            return;
                          }

                          // Already selected, just close
                          if (isSelected) {
                            context.pop();
                            return;
                          }

                          // Set wallet filter (no confirmation needed - just a filter)
                          ref.read(dashboardWalletFilterProvider.notifier).state = wallet;
                          context.pop(); // Close the bottom sheet
                        },
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  IconData _getWalletTypeIcon(WalletType walletType) {
    switch (walletType) {
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
}
