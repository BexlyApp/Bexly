import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_form_state.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/features/category/data/model/category_model.dart';

class RecurringFormScreen extends HookConsumerWidget {
  final int? recurringId;

  const RecurringFormScreen({
    super.key,
    this.recurringId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(recurringFormProvider);
    final formNotifier = ref.read(recurringFormProvider.notifier);
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: formState.name);
    final amountController = useTextEditingController(
      text: formState.amount > 0 ? formState.amount.toString() : '',
    );
    final walletController = useTextEditingController();
    final categoryController = useTextEditingController();

    // Initialize form on mount
    useEffect(() {
      // Reset form if creating new (not editing)
      // Must use addPostFrameCallback to avoid modifying provider during build
      if (recurringId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formNotifier.reset();
        });
      }
      return null;
    }, const []);

    // Auto-select wallet if only one wallet exists
    useEffect(() {
      if (recurringId == null && formState.wallet == null && allWalletsAsync.valueOrNull != null) {
        Future.microtask(() {
          final wallets = allWalletsAsync.valueOrNull;
          if (wallets != null && wallets.length == 1) {
            // Only 1 wallet - auto-select it
            final wallet = wallets.first;
            formNotifier.setWallet(wallet);
            walletController.text = '${wallet.name} - ${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}';
          }
        });
      }

      // Update controllers when form state changes
      if (formState.wallet != null && walletController.text.isEmpty) {
        final wallet = formState.wallet!;
        walletController.text = '${wallet.name} - ${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}';
      }
      if (formState.category != null && categoryController.text.isEmpty) {
        categoryController.text = formState.category!.title;
      }

      return null;
    }, [formState.wallet, formState.category, allWalletsAsync]);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing20,
                AppSpacing.spacing20,
                AppSpacing.spacing20,
                100,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.spacing16,
                children: [
                  // Title
                  Text(
                    recurringId == null ? 'Add Recurring Payment' : 'Edit Recurring Payment',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Name field
                  CustomTextField(
                    controller: nameController,
                    label: 'Name',
                    hint: 'e.g., Netflix, Spotify, Electric Bill',
                    isRequired: true,
                    onChanged: formNotifier.setName,
                  ),

                  // Wallet selector - only show if multiple wallets
                  if (allWalletsAsync.valueOrNull != null && allWalletsAsync.valueOrNull!.length > 1)
                    CustomSelectField(
                      context: context,
                      controller: walletController,
                      label: 'Wallet',
                      hint: 'Select Wallet',
                      isRequired: true,
                      prefixIcon: HugeIcons.strokeRoundedWallet01,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => WalletSelectorBottomSheet(
                            onWalletSelected: (WalletModel wallet) {
                              formNotifier.setWallet(wallet);
                              walletController.text = '${wallet.name} - ${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}';
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),

                  // Category selector
                  CustomSelectField(
                    context: context,
                    controller: categoryController,
                    label: 'Category',
                    hint: 'Select Category',
                    isRequired: true,
                    prefixIcon: HugeIcons.strokeRoundedPackage,
                    onTap: () async {
                      final CategoryModel? result = await context.push(
                        Routes.categoryList,
                      );
                      if (result != null) {
                        formNotifier.setCategory(result);
                        categoryController.text = result.title;
                      }
                    },
                  ),

                  // Amount field
                  CustomNumericField(
                    controller: amountController,
                    label: 'Amount',
                    hint: '1,000.00',
                    icon: HugeIcons.strokeRoundedCoins01,
                    appendCurrencySymbolToHint: true,
                    isRequired: true,
                  ),

                  // Frequency selector
                  _FrequencySelector(
                    selectedFrequency: formState.frequency,
                    onChanged: formNotifier.setFrequency,
                  ),

                  // First Billing Date (hidden Start Date for backward compatibility)
                  _DateField(
                    label: 'First Billing Date',
                    date: formState.nextDueDate,
                    onDateSelected: formNotifier.setNextDueDate,
                  ),

                  // Charge Immediately checkbox
                  CheckboxListTile(
                    title: const Text('Charge immediately'),
                    subtitle: const Text('Create first transaction on the billing date'),
                    value: formState.autoCharge,
                    onChanged: (value) {
                      if (value != null) {
                        formNotifier.setAutoCharge(value);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Enable Reminder switch
                  SwitchListTile(
                    title: const Text('Enable Reminder'),
                    subtitle: Text(
                      'Remind ${formState.reminderDaysBefore} days before due date',
                    ),
                    value: formState.enableReminder,
                    onChanged: formNotifier.setEnableReminder,
                  ),

                  // Error message
                  if (formState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: PrimaryButton(
                label: formState.isLoading
                    ? 'Saving...'
                    : (recurringId == null ? 'Add Recurring' : 'Update Recurring'),
                onPressed: formState.isLoading
                    ? null
                    : () async {
                        final success = await formNotifier.save();
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                recurringId == null
                                    ? 'Recurring payment added successfully'
                                    : 'Recurring payment updated successfully',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final RecurringFrequency selectedFrequency;
  final Function(RecurringFrequency) onChanged;

  const _FrequencySelector({
    required this.selectedFrequency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RecurringFrequency>(
      decoration: const InputDecoration(
        labelText: 'Frequency *',
        border: OutlineInputBorder(),
      ),
      initialValue: selectedFrequency,
      items: RecurringFrequency.values.map((frequency) {
        return DropdownMenuItem<RecurringFrequency>(
          value: frequency,
          child: Text(frequency.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final Function(DateTime) onDateSelected;

  const _DateField({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
        ),
      ),
    );
  }
}
