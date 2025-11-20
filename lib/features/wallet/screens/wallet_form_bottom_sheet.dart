import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/currency_picker/presentation/components/currency_picker_field.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/presentation/components/wallet_type_selector_field.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:toastification/toastification.dart';

class WalletFormBottomSheet extends HookConsumerWidget {
  final WalletModel? wallet;
  final bool showDeleteButton;
  final Function(WalletModel)? onSave;
  final bool allowFullEdit; // Allow editing currency and balance even in edit mode
  const WalletFormBottomSheet({
    super.key,
    this.wallet,
    this.showDeleteButton = true,
    this.onSave,
    this.allowFullEdit = false, // Default to false for backward compatibility
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch currency provider to get updated value when user picks new currency
    final currency = ref.watch(currencyProvider);
    // Check if wallet has ID - if yes, it's editing regardless of allowFullEdit
    final isEditing = wallet?.id != null;
    // Lock currency/balance change unless it's a new wallet or allowFullEdit is true
    final canEditCurrencyAndBalance = wallet?.id == null || allowFullEdit;

    final nameController = useTextEditingController();
    final balanceController = useTextEditingController();
    final currencyController = useTextEditingController();

    // Wallet type state
    final walletType = useState<WalletType>(wallet?.walletType ?? WalletType.cash);

    // Credit card fields
    final creditLimitController = useTextEditingController();
    final billingDayController = useTextEditingController();
    final interestRateController = useTextEditingController();

    // Initialize form fields if wallet exists (populate data for both edit and create modes)
    useEffect(() {
      if (wallet != null) {
        nameController.text = wallet!.name;
        balanceController.text = wallet!.balance == 0
            ? ''
            : '${wallet?.currencyByIsoCode(ref).symbol} ${wallet?.balance.toPriceFormat()}';
        currencyController.text = wallet!.currency;
        walletType.value = wallet!.walletType;

        // Initialize credit card fields
        if (wallet!.creditLimit != null) {
          creditLimitController.text = wallet!.creditLimit.toString();
        }
        if (wallet!.billingDay != null) {
          billingDayController.text = wallet!.billingDay.toString();
        }
        if (wallet!.interestRate != null) {
          interestRateController.text = wallet!.interestRate.toString();
        }
      } else {
        // For new wallets, pre-fill with currency-based placeholder
        final placeholderName = 'My ${currency.isoCode} Wallet';
        nameController.text = placeholderName;
        // Select all text so it's easy to replace
        nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: placeholderName.length,
        );
      }
      return null;
    }, [wallet]);

    return CustomBottomSheet(
      title: '${isEditing ? 'Edit' : 'Add'} Wallet',
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.spacing16,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Wallet Name (max. 15)',
              hint: 'e.g., Savings Account',
              isRequired: true,
              prefixIcon: HugeIcons.strokeRoundedWallet02,
              textInputAction: TextInputAction.next,
              maxLength: 15,
              customCounterText: '',
            ),

            // Wallet Type Selector (locked after creation)
            WalletTypeSelectorField(
              key: ValueKey(walletType.value),
              selectedType: walletType.value,
              onTypeChanged: (type) => walletType.value = type,
              label: 'Wallet Type',
              enabled: canEditCurrencyAndBalance, // Lock wallet type unless allowFullEdit
            ),

            CurrencyPickerField(
              defaultCurrency: currency,
              enabled: canEditCurrencyAndBalance, // Disable currency change unless allowFullEdit
            ),
            CustomNumericField(
              controller: balanceController,
              label: canEditCurrencyAndBalance ? 'Initial Balance' : 'Current Balance (read-only)',
              hint: '1,000.00',
              icon: HugeIcons.strokeRoundedMoney01,
              isRequired: true,
              appendCurrencySymbolToHint: true,
              useSelectedCurrency: true,
              enabled: canEditCurrencyAndBalance, // Disable balance change unless allowFullEdit
              // autofocus: !isEditing, // Optional: autofocus if adding new
            ),

            // Credit Card Specific Fields
            if (walletType.value == WalletType.creditCard) ...[
              CustomNumericField(
                controller: creditLimitController,
                label: 'Credit Limit',
                hint: '5,000.00',
                icon: HugeIcons.strokeRoundedCreditCard,
                isRequired: false,
                appendCurrencySymbolToHint: true,
                useSelectedCurrency: true,
              ),
              CustomTextField(
                controller: billingDayController,
                label: 'Billing Day (1-31)',
                hint: 'e.g., 15',
                isRequired: false,
                prefixIcon: HugeIcons.strokeRoundedCalendar03,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                controller: interestRateController,
                label: 'Annual Interest Rate (%)',
                hint: 'e.g., 18.5',
                isRequired: false,
                prefixIcon: HugeIcons.strokeRoundedPercent,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            PrimaryButton(
              label: 'Save Wallet',
              state: ButtonState.active,
              onPressed: () async {
                // Parse credit card fields
                double? creditLimit;
                int? billingDay;
                double? interestRate;

                if (walletType.value == WalletType.creditCard) {
                  if (creditLimitController.text.isNotEmpty) {
                    creditLimit = creditLimitController.text.takeNumericAsDouble();
                  }
                  if (billingDayController.text.isNotEmpty) {
                    billingDay = int.tryParse(billingDayController.text.trim());
                  }
                  if (interestRateController.text.isNotEmpty) {
                    interestRate = double.tryParse(interestRateController.text.trim());
                  }
                }

                final newWallet = WalletModel(
                  id: wallet?.id, // Keep ID for updates, null for inserts
                  name: nameController.text.trim(),
                  balance: balanceController.text.takeNumericAsDouble(),
                  currency: currency.isoCode,
                  iconName: wallet?.iconName, // Preserve or add UI to change
                  colorHex: wallet?.colorHex, // Preserve or add UI to change
                  walletType: walletType.value,
                  creditLimit: creditLimit,
                  billingDay: billingDay,
                  interestRate: interestRate,
                );

                // return;

                final walletDao = ref.read(walletDaoProvider);
                try {
                  // Validate: Check for duplicate wallet name
                  final allWallets = await walletDao.getAllWallets();
                  final duplicateName = allWallets.any((w) =>
                    w.name.toLowerCase() == newWallet.name.toLowerCase() &&
                    w.id != newWallet.id  // Exclude current wallet when editing
                  );

                  if (duplicateName) {
                    toastification.show(
                      description: const Text('A wallet with this name already exists. Please choose a different name.'),
                      type: ToastificationType.error,
                    );
                    return;
                  }

                  if (isEditing) {
                    Log.d(newWallet.toJson(), label: 'edit wallet');
                    // update the wallet
                    bool success = await walletDao.updateWallet(newWallet);
                    Log.d(success, label: 'edit wallet');

                    // only update active wallet if condition is met
                    ref
                        .read(activeWalletProvider.notifier)
                        .updateActiveWallet(newWallet);
                  } else {
                    Log.d(newWallet.toJson(), label: 'new wallet');
                    int id = await walletDao.addWallet(newWallet);
                    Log.d(id, label: 'new wallet');

                    // Set newly created wallet as active
                    final createdWallet = newWallet.copyWith(id: id);
                    ref.read(activeWalletProvider.notifier).setActiveWallet(createdWallet);
                  }

                  onSave?.call(
                    newWallet,
                  ); // Call the onSave callback if provided
                  if (context.mounted) context.pop(); // Close bottom sheet
                } catch (e) {
                  // Handle error, e.g., show a SnackBar
                  toastification.show(
                    description: Text('Error saving wallet: $e'),
                  );
                }
              },
            ),
            if (isEditing && showDeleteButton)
              TextButton(
                child: Text(
                  'Delete',
                  style: AppTextStyles.body2.copyWith(color: AppColors.red),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => AlertBottomSheet(
                      context: context,
                      title: 'Delete Wallet',
                      content: Text(
                        'All transactions, budgets, and goals will also be deleted. This action cannot be undone.',
                        style: AppTextStyles.body2,
                      ),
                      confirmText: 'Delete',
                      onConfirm: () async {
                        final walletDao = ref.read(walletDaoProvider);
                        try {
                          await walletDao.deleteWallet(wallet!.id!);

                          if (context.mounted) {
                            context.pop(); // close this dialog
                            context.pop(); // close form dialog

                            toastification.show(
                              autoCloseDuration: Duration(seconds: 3),
                              showProgressBar: true,
                              description: Text(
                                'Wallet "${wallet!.name}" deleted successfully',
                                style: AppTextStyles.body2,
                              ),
                            );
                          }
                        } catch (e) {
                          Log.e('Failed to delete wallet: $e', label: 'wallet_form');
                          if (context.mounted) {
                            context.pop(); // close dialog on error
                            toastification.show(
                              autoCloseDuration: Duration(seconds: 3),
                              showProgressBar: true,
                              description: Text(
                                'Error deleting wallet: $e',
                                style: AppTextStyles.body2,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
