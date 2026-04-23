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
    final allWallets = ref.watch(allWalletsStreamProvider).value ?? [];
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
            : formatCurrency(wallet!.balance.toPriceFormat(), wallet!.currencyByIsoCode(ref).symbol, wallet!.currency);
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

    // Auto-update wallet name when currency or wallet type changes (for new wallets only)
    useEffect(() {
      if (wallet == null) { // Only for new wallets
        String walletTypeName;
        switch (walletType.value) {
          case WalletType.cash:
            walletTypeName = 'Cash';
            break;
          case WalletType.bankAccount:
            walletTypeName = 'Bank';
            break;
          case WalletType.creditCard:
            walletTypeName = 'Credit Card';
            break;
          case WalletType.savings:
            walletTypeName = 'Savings';
            break;
          case WalletType.investment:
            walletTypeName = 'Investment';
            break;
          case WalletType.eWallet:
            walletTypeName = 'E-Wallet';
            break;
          case WalletType.insurance:
            walletTypeName = 'Insurance';
            break;
          case WalletType.other:
            walletTypeName = 'Wallet';
            break;
        }

        final newName = 'My ${currency.isoCode} $walletTypeName';
        nameController.text = newName;
        // Select all text so it's easy to replace
        nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: newName.length,
        );
      }
      return null;
    }, [currency, walletType.value]);

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
              hint: walletType.value == WalletType.creditCard ? '-1,000.00' : '1,000.00',
              icon: Icons.attach_money, // CustomNumericField uses IconData, use Material icon
              isRequired: true,
              appendCurrencySymbolToHint: true,
              useSelectedCurrency: true,
              enabled: canEditCurrencyAndBalance, // Disable balance change unless allowFullEdit
              allowNegative: walletType.value == WalletType.creditCard, // Allow negative for credit cards
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
                onPressed: () async {
                  final walletDao = ref.read(walletDaoProvider);

                  // Helper: reassign default wallet after deletion
                  Future<void> reassignDefaultWallet() async {
                    final currentDefault = ref.read(defaultWalletIdProvider);
                    if (currentDefault == wallet!.id) {
                      final remaining = ref.read(allWalletsStreamProvider).value ?? [];
                      final other = remaining.where((w) => w.id != wallet!.id).toList();
                      if (other.isNotEmpty) {
                        await ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(other.first.id!);
                      } else {
                        await ref.read(defaultWalletIdProvider.notifier).clearDefaultWallet();
                      }
                    }
                  }

                  final relatedCount = await walletDao.getRelatedDataCount(wallet!.id!);

                  if (relatedCount == 0) {
                    // No transactions — simple confirm
                    if (!context.mounted) return;
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
                          try {
                            await walletDao.deleteWallet(wallet!.id!);
                            await reassignDefaultWallet();
                            if (context.mounted) {
                              context.pop();
                              context.pop();
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Wallet "${wallet!.name}" deleted successfully', style: AppTextStyles.body2),
                              );
                            }
                          } catch (e) {
                            Log.e('Failed to delete wallet: $e', label: 'wallet_form');
                            if (context.mounted) {
                              context.pop();
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Error deleting wallet: $e', style: AppTextStyles.body2),
                              );
                            }
                          }
                        },
                      ),
                    );
                  } else {
                    // Has transactions — show options
                    if (!context.mounted) return;
                    final allWallets = ref.read(allWalletsStreamProvider).value ?? [];
                    final otherWallets = allWallets.where((w) => w.id != wallet!.id).toList();

                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (sheetContext) => _DeleteWalletOptionsSheet(
                        walletName: wallet!.name,
                        relatedDataCount: relatedCount,
                        otherWallets: otherWallets,
                        onMoveAndDelete: (targetWalletId) async {
                          try {
                            await walletDao.reassignWalletData(wallet!.id!, targetWalletId);
                            await walletDao.deleteWallet(wallet!.id!);
                            await reassignDefaultWallet();
                            if (context.mounted) {
                              Navigator.of(sheetContext).pop();
                              context.pop();
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Transactions moved and wallet "${wallet!.name}" deleted', style: AppTextStyles.body2),
                              );
                            }
                          } catch (e) {
                            Log.e('Failed to move & delete wallet: $e', label: 'wallet_form');
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            if (context.mounted) {
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Error: $e', style: AppTextStyles.body2),
                              );
                            }
                          }
                        },
                        onForceDelete: () async {
                          try {
                            await walletDao.forceDeleteWallet(wallet!.id!);
                            await reassignDefaultWallet();
                            if (context.mounted) {
                              Navigator.of(sheetContext).pop();
                              context.pop();
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Wallet "${wallet!.name}" and all transactions deleted', style: AppTextStyles.body2),
                              );
                            }
                          } catch (e) {
                            Log.e('Failed to force delete wallet: $e', label: 'wallet_form');
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            if (context.mounted) {
                              toastification.show(
                                autoCloseDuration: Duration(seconds: 3),
                                showProgressBar: true,
                                description: Text('Error: $e', style: AppTextStyles.body2),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for wallet deletion options when transactions exist
class _DeleteWalletOptionsSheet extends StatefulWidget {
  final String walletName;
  final int relatedDataCount;
  final List<WalletModel> otherWallets;
  final Future<void> Function(int targetWalletId) onMoveAndDelete;
  final Future<void> Function() onForceDelete;

  const _DeleteWalletOptionsSheet({
    required this.walletName,
    required this.relatedDataCount,
    required this.otherWallets,
    required this.onMoveAndDelete,
    required this.onForceDelete,
  });

  @override
  State<_DeleteWalletOptionsSheet> createState() => _DeleteWalletOptionsSheetState();
}

class _DeleteWalletOptionsSheetState extends State<_DeleteWalletOptionsSheet> {
  int? _selectedWalletId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.otherWallets.isNotEmpty) {
      _selectedWalletId = widget.otherWallets.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: 'Delete "${widget.walletName}"',
      subtitle: 'This wallet has ${widget.relatedDataCount} related item(s). What would you like to do?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option 1: Move transactions to another wallet
          if (widget.otherWallets.isNotEmpty) ...[
            Text('Move transactions to:', style: AppTextStyles.body3),
            const SizedBox(height: AppSpacing.spacing8),
            DropdownButtonFormField<int>(
              value: _selectedWalletId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: widget.otherWallets.map((w) => DropdownMenuItem(
                value: w.id,
                child: Text('${w.name} (${w.currency})', style: AppTextStyles.body2),
              )).toList(),
              onChanged: _isProcessing ? null : (v) => setState(() => _selectedWalletId = v),
            ),
            const SizedBox(height: AppSpacing.spacing16),
          ],
          Row(
            spacing: AppSpacing.spacing12,
            children: [
              // Delete all button
              Expanded(
                child: PrimaryButton(
                  label: 'Delete',
                  isOutlined: true,
                  state: _isProcessing ? ButtonState.inactive : ButtonState.outlinedActive,
                  onPressed: () async {
                    setState(() => _isProcessing = true);
                    await widget.onForceDelete();
                  },
                ),
              ),
              // Move & delete button
              if (widget.otherWallets.isNotEmpty)
                Expanded(
                  child: PrimaryButton(
                    label: 'Move',
                    state: _isProcessing || _selectedWalletId == null ? ButtonState.inactive : ButtonState.active,
                    onPressed: () async {
                      if (_selectedWalletId == null) return;
                      setState(() => _isProcessing = true);
                      await widget.onMoveAndDelete(_selectedWalletId!);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
