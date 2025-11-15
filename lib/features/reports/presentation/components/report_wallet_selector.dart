part of '../screens/basic_monthly_report_screen.dart';

class _ReportWalletSelector extends ConsumerWidget {
  const _ReportWalletSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);
    final selectedWalletId = ref.watch(reportWalletFilterProvider);

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

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wallets.length + 1,
            itemBuilder: (context, index) {
              // First item is "All Wallets"
              if (index == 0) {
                final isSelected = selectedWalletId == null;
                return ListTile(
                  title: Text('All Wallets', style: AppTextStyles.body1),
                  dense: true,
                  leading: const Icon(HugeIcons.strokeRoundedWallet01),
                  subtitle: Text(
                    'View combined expenses from all wallets',
                    style: AppTextStyles.body3,
                  ),
                  trailing: Icon(
                    isSelected
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedCircle,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    ref.read(reportWalletFilterProvider.notifier).state = null;
                    context.pop();
                  },
                );
              }

              // Individual wallets
              final wallet = wallets[index - 1];
              final isSelected = selectedWalletId == wallet.id;

              return ListTile(
                title: Text(wallet.name, style: AppTextStyles.body1),
                dense: true,
                leading: Icon(_getWalletTypeIcon(wallet.walletType)),
                subtitle: Text(
                  '${wallet.currency} ${wallet.balance.toPriceFormat()}',
                  style: AppTextStyles.body3,
                ),
                trailing: Icon(
                  isSelected
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedCircle,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                onTap: () {
                  ref.read(reportWalletFilterProvider.notifier).state = wallet.id;
                  context.pop();
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

  IconData _getWalletTypeIcon(WalletType walletType) {
    // Use HugeIcons for wallet types
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
