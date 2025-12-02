import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/buttons/menu_tile_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/screens/wallet_form_bottom_sheet.dart';

/// Get HugeIcon for wallet type (constant for tree-shaking)
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

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);
    final defaultWalletId = ref.watch(defaultWalletIdProvider);

    return CustomScaffold(
      context: context,
      title: 'Manage Wallets',
      showBalance: false,
      actions: [
        CustomIconButton(
          context,
          icon: HugeIcons.strokeRoundedAdd01,
          onPressed: () {
            context.openBottomSheet(child: const WalletFormBottomSheet());
          },
          themeMode: context.themeMode,
        ),
      ],
      body: allWalletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(
              child: Text('No wallets found. Add one to get started!'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isDefault = wallet.id == defaultWalletId;
              return MenuTileButton(
                label: wallet.name,
                subtitle: Text(
                  '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}',
                  style: AppTextStyles.body3,
                ),
                icon: _getWalletIcon(wallet.walletType),
                trailing: isDefault
                    ? const Icon(
                        HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: AppColors.primary600,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  final bool isNotLastWallet = wallets.length > 1;
                  final defaultCurrencies = ref.read(currenciesStaticProvider);

                  final selectedCurrency = defaultCurrencies.firstWhere(
                    (currency) => currency.isoCode == wallet.currency,
                    orElse: () => defaultCurrencies.first,
                  );

                  ref.read(currencyProvider.notifier).state = selectedCurrency;

                  context.openBottomSheet(
                    child: WalletFormBottomSheet(
                      wallet: wallet,
                      showDeleteButton: isNotLastWallet,
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.spacing8),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
