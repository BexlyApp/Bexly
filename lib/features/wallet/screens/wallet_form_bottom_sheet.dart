import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/data/sources/currency_local_source.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/presentation/components/wallet_type_selector_field.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
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

    // Default wallet checkbox state
    final defaultWalletId = ref.watch(defaultWalletIdProvider);
    final allWallets = ref.watch(allWalletsStreamProvider).valueOrNull ?? [];
    final isFirstWallet = !isEditing && allWallets.isEmpty;
    final isOnlyWallet = isEditing && allWallets.length == 1;

    // Force checked if: creating first wallet OR editing the only wallet
    final forceDefaultWallet = isFirstWallet || isOnlyWallet;

    final isDefaultWallet = useState<bool>(
      forceDefaultWallet || (wallet?.id != null && wallet!.id == defaultWalletId),
    );

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
        // For new wallets, initialize currency from base currency setting or device locale
        final baseCurrency = ref.read(baseCurrencyProvider);
        final currencies = ref.read(currenciesStaticProvider);

        // Find currency object matching base currency
        Currency? matchingCurrency = currencies.cast<Currency?>().firstWhere(
          (c) => c?.isoCode == baseCurrency,
          orElse: () => null,
        );

        // Fallback to device locale if base currency not found
        if (matchingCurrency == null && currencies.isNotEmpty) {
          final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
          final localeCurrencyCode = CurrencyLocalDataSource.getCurrencyCodeFromLocale(
            deviceLocale.countryCode,
            deviceLocale.languageCode,
          );
          matchingCurrency = currencies.cast<Currency?>().firstWhere(
            (c) => c?.isoCode == localeCurrencyCode,
            orElse: () => null,
          );
        }

        // Use Future.microtask to avoid modifying provider during build
        if (matchingCurrency != null) {
          Future.microtask(() {
            ref.read(currencyProvider.notifier).state = matchingCurrency!;
          });
        }

        // Pre-fill with currency-based placeholder using detected currency
        final currencyCode = matchingCurrency?.isoCode ?? baseCurrency;
        final placeholderName = 'My $currencyCode Wallet';
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
              prefixIcon: Icons.wallet, // CustomTextField uses IconData, use Material icon
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
              icon: Icons.attach_money, // CustomNumericField uses IconData, use Material icon
              isRequired: true,
              appendCurrencySymbolToHint: true,
              useSelectedCurrency: true,
              enabled: canEditCurrencyAndBalance, // Disable balance change unless allowFullEdit
              // autofocus: !isEditing, // Optional: autofocus if adding new
            ),

            // Set as default wallet checkbox
            // Disabled when: creating first wallet or editing the only wallet (must be default)
            CheckboxListTile(
              value: forceDefaultWallet ? true : isDefaultWallet.value,
              onChanged: forceDefaultWallet
                  ? null // Disable checkbox if this must be default wallet
                  : (value) => isDefaultWallet.value = value ?? false,
              title: Text(
                context.l10n.setAsDefaultWallet,
                style: AppTextStyles.body2,
              ),
              subtitle: Text(
                context.l10n.usedForAiAndConversion,
                style: AppTextStyles.body4.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            // Credit Card Specific Fields
            if (walletType.value == WalletType.creditCard) ...[
              CustomNumericField(
                controller: creditLimitController,
                label: 'Credit Limit',
                hint: '5,000.00',
                icon: Icons.credit_card, // CustomNumericField uses IconData, use Material icon
                isRequired: false,
                appendCurrencySymbolToHint: true,
                useSelectedCurrency: true,
              ),
              CustomTextField(
                controller: billingDayController,
                label: 'Billing Day (1-31)',
                hint: 'e.g., 15',
                isRequired: false,
                prefixIcon: Icons.calendar_today, // CustomTextField uses IconData, use Material icon
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                controller: interestRateController,
                label: 'Annual Interest Rate (%)',
                hint: 'e.g., 18.5',
                isRequired: false,
                prefixIcon: Icons.percent, // CustomTextField uses IconData, use Material icon
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

                  int savedWalletId;

                  if (isEditing) {
                    Log.d(newWallet.toJson(), label: 'edit wallet');
                    // update the wallet
                    bool success = await walletDao.updateWallet(newWallet);
                    Log.d(success, label: 'edit wallet');
                    savedWalletId = newWallet.id!;

                    // only update active wallet if condition is met
                    ref
                        .read(activeWalletProvider.notifier)
                        .updateActiveWallet(newWallet);
                  } else {
                    // Check subscription limit before creating new wallet
                    final limits = ref.read(subscriptionLimitsProvider);
                    if (!limits.isWithinLimit(allWallets.length, limits.maxWallets)) {
                      toastification.show(
                        description: Text('You have reached the maximum of ${limits.maxWallets} wallets. Upgrade to Plus for unlimited wallets.'),
                        type: ToastificationType.warning,
                      );
                      return;
                    }

                    Log.d(newWallet.toJson(), label: 'new wallet');
                    int id = await walletDao.addWallet(newWallet);
                    Log.d(id, label: 'new wallet');
                    savedWalletId = id;

                    // Set newly created wallet as active
                    final createdWallet = newWallet.copyWith(id: id);
                    ref.read(activeWalletProvider.notifier).setActiveWallet(createdWallet);
                  }

                  // Handle default wallet setting
                  // Auto-set as default if: checkbox is checked OR this is the first wallet
                  final currentDefaultId = ref.read(defaultWalletIdProvider);
                  if (isDefaultWallet.value || currentDefaultId == null) {
                    await ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(savedWalletId);
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
                  context.l10n.delete,
                  style: AppTextStyles.body2.copyWith(color: AppColors.red),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (dialogContext) => AlertBottomSheet(
                      context: context,
                      title: context.l10n.deleteWallet,
                      content: Text(
                        context.l10n.confirmDelete,
                        style: AppTextStyles.body2,
                      ),
                      confirmText: context.l10n.delete,
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
