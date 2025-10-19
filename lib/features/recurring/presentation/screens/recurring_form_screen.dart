import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_form_state.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/category/presentation/riverpod/category_providers.dart';
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

    final nameController = useTextEditingController(text: formState.name);
    final amountController = useTextEditingController(
      text: formState.amount > 0 ? formState.amount.toString() : '',
    );

    // Initialize with default wallet and category if not editing
    useEffect(() {
      if (recurringId == null && formState.wallet == null) {
        final walletsAsync = ref.read(allWalletsStreamProvider);
        final categoriesAsync = ref.read(hierarchicalCategoriesProvider);

        walletsAsync.whenData((wallets) {
          if (wallets.isNotEmpty) {
            formNotifier.setWallet(wallets.first);
          }
        });

        categoriesAsync.whenData((categories) {
          if (categories.isNotEmpty) {
            formNotifier.setCategory(categories.first);
          }
        });
      }
      return null;
    }, []);

    return CustomScaffold(
      context: context,
      title: recurringId == null ? 'Add Recurring Payment' : 'Edit Recurring Payment',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            CustomTextField(
              controller: nameController,
              label: 'Name',
              hint: 'e.g., Netflix, Spotify, Electric Bill',
              isRequired: true,
              onChanged: formNotifier.setName,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Amount field
            CustomTextField(
              controller: amountController,
              label: 'Amount',
              hint: '0.00',
              isRequired: true,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                formNotifier.setAmount(amount);
              },
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Wallet selector
            _WalletSelector(
              selectedWallet: formState.wallet,
              onChanged: formNotifier.setWallet,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Category selector
            _CategorySelector(
              selectedCategory: formState.category,
              onChanged: formNotifier.setCategory,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Frequency selector
            _FrequencySelector(
              selectedFrequency: formState.frequency,
              onChanged: formNotifier.setFrequency,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Start Date
            _DateField(
              label: 'Start Date',
              date: formState.startDate,
              onDateSelected: formNotifier.setStartDate,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Next Due Date
            _DateField(
              label: 'Next Due Date',
              date: formState.nextDueDate,
              onDateSelected: formNotifier.setNextDueDate,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Enable Reminder switch
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: Text(
                'Remind ${formState.reminderDaysBefore} days before due date',
              ),
              value: formState.enableReminder,
              onChanged: formNotifier.setEnableReminder,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // Auto Charge switch
            SwitchListTile(
              title: const Text('Auto Charge'),
              subtitle: const Text('Automatically deduct from wallet on due date'),
              value: formState.autoCharge,
              onChanged: formNotifier.setAutoCharge,
            ),
            const SizedBox(height: AppSpacing.spacing24),

            // Error message
            if (formState.errorMessage != null) ...[
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
              const SizedBox(height: AppSpacing.spacing16),
            ],

            // Save button
            PrimaryButton(
              label: formState.isLoading
                  ? 'Saving...'
                  : (recurringId == null ? 'Add Recurring' : 'Update Recurring'),
              onPressed: formState.isLoading
                  ? null
                  : () async {
                      final success = await formNotifier.save();
                      if (success && context.mounted) {
                        context.pop();
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
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }
}

class _WalletSelector extends HookConsumerWidget {
  final WalletModel? selectedWallet;
  final Function(WalletModel) onChanged;

  const _WalletSelector({
    required this.selectedWallet,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(allWalletsStreamProvider);

    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return const Text('No wallets available');
        }

        return DropdownButtonFormField<WalletModel>(
          decoration: const InputDecoration(
            labelText: 'Wallet *',
            border: OutlineInputBorder(),
          ),
          value: selectedWallet,
          items: wallets.map((wallet) {
            return DropdownMenuItem<WalletModel>(
              value: wallet,
              child: Text('${wallet.name} (${wallet.currency})'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading wallets'),
    );
  }
}

class _CategorySelector extends HookConsumerWidget {
  final CategoryModel? selectedCategory;
  final Function(CategoryModel) onChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(hierarchicalCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Text('No categories available');
        }

        return DropdownButtonFormField<CategoryModel>(
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          value: selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text(category.title),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading categories'),
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
      value: selectedFrequency,
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
