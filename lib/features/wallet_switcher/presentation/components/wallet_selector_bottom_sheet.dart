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
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

class WalletSelectorBottomSheet extends ConsumerWidget {
  final Function(WalletModel)? onWalletSelected;
  const WalletSelectorBottomSheet({super.key, this.onWalletSelected});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);
    final selectedWallet = ref.watch(dashboardWalletFilterProvider);

    // If used in form context (onWalletSelected provided), hide "Total Balance"
    final bool isFormContext = onWalletSelected != null;

    return CustomBottomSheet(
      title: 'Select Wallet',
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

              return ListTile(
                title: Text(wallet.name, style: AppTextStyles.body1),
                dense: true,
                subtitle: Text(
                  '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}',
                  style: AppTextStyles.body3,
                ),
                trailing: Icon(
                  isSelected
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedCircle,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                onTap: () {
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
}
