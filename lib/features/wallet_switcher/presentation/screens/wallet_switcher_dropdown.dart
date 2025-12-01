import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/small_button.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';

class WalletSwitcherDropdown extends ConsumerWidget {
  const WalletSwitcherDropdown({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final selectedWallet = ref.watch(dashboardWalletFilterProvider);

    return SmallButton(
      prefixIcon: HugeIcons.strokeRoundedWallet01,
      label: selectedWallet?.name ?? context.l10n.totalBalance,
      suffixIcon: HugeIcons.strokeRoundedArrowDown01,
      onTap: () {
        context.openBottomSheet(child: const WalletSelectorBottomSheet());
      },
    );
  }
}
