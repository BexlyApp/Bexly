import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/features/currency_picker/data/sources/currency_local_source.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/screens/wallet_form_bottom_sheet.dart';

class CreateFirstWalletField extends HookConsumerWidget {
  const CreateFirstWalletField({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(activeWalletProvider).value;
    final initialText = wallet != null
        ? '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}'
        : 'Setup Wallet'; // Fallback if no active wallet

    final textController = useTextEditingController(text: initialText);

    useEffect(() {
      final newText = wallet != null
          ? '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}'
          : 'Setup Wallet';
      if (textController.text != newText) {
        textController.text = newText;
      }
      return null;
    }, [wallet]);

    return CustomTextField(
      context: context,
      controller: textController,
      label: wallet?.name ?? 'Wallet', // Fallback label
      hint: wallet != null ? '' : 'Tap to setup your first wallet',
      prefixIcon: HugeIcons.strokeRoundedWallet01,
      suffixIcon: HugeIcons.strokeRoundedAdd01,
      readOnly: true,
      onTap: () {
        // In onboarding, always allow full edit (currency and balance)
        final defaultCurrencies = ref.read(currenciesStaticProvider);

        if (wallet != null) {
          // Pre-select current currency if wallet exists
          final selectedCurrency = defaultCurrencies.firstWhere(
            (currency) => currency.isoCode == wallet.currency,
            orElse: () => CurrencyLocalDataSource.dummy,
          );
          ref.read(currencyProvider.notifier).state = selectedCurrency;
        }

        context.openBottomSheet(
          child: WalletFormBottomSheet(
            wallet: wallet,
            showDeleteButton: false,
            allowFullEdit: true, // Always allow full edit in onboarding
          ),
        );
      },
    );
  }
}
