import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_form_state.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/sync/cloud_sync_service.dart';

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

    // Watch recurring data if editing
    final recurringAsync = recurringId != null
        ? ref.watch(recurringByIdProvider(recurringId!))
        : null;

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: formState.name);
    final amountController = useTextEditingController(
      text: formState.amount > 0 ? formState.amount.toString() : '',
    );
    final walletController = useTextEditingController();
    final categoryController = useTextEditingController();

    // Initialize form with recurring data when editing
    useEffect(() {
      if (recurringId != null && recurringAsync?.valueOrNull != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formNotifier.initializeWithRecurring(recurringAsync!.value!);
        });
      } else if (recurringId == null) {
        // Reset form if creating new
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formNotifier.reset();
        });
      }
      return null;
    }, [recurringId, recurringAsync?.valueOrNull]);

    // Update controllers when formState changes (Fix for edit mode)
    useEffect(() {
      nameController.text = formState.name;
      amountController.text = formState.amount > 0 ? formState.amount.toString() : '';
      return null;
    }, [formState.name, formState.amount]);

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          recurringId == null ? 'Add Recurring Payment' : 'Edit Recurring Payment',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
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
                              // No need to pop - WalletSelectorBottomSheet already handles it
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
                    onChanged: (value) {
                      final amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                      formNotifier.setAmount(amount);
                    },
                  ),

                  // Frequency and First Billing Date in 2 columns
                  Row(
                    children: [
                      Expanded(
                        child: _FrequencySelector(
                          selectedFrequency: formState.frequency,
                          onChanged: formNotifier.setFrequency,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        child: _DateField(
                          label: 'First Billing Date',
                          date: formState.nextDueDate,
                          onDateSelected: formNotifier.setNextDueDate,
                        ),
                      ),
                    ],
                  ),

                  // Auto Create toggle - only show when creating new recurring
                  if (recurringId == null)
                    _AutoCreateToggle(
                      value: formState.autoCreate,
                      onChanged: formNotifier.setAutoCreate,
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

                  // Action buttons (Pause/Delete) - only show when editing
                  if (recurringId != null && formState.editingRecurring != null)
                    _ActionButtons(
                      recurringId: recurringId!,
                      currentStatus: formState.status,
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

class _AutoCreateToggle extends HookConsumerWidget {
  final bool value;
  final Function(bool) onChanged;

  const _AutoCreateToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.purpleButtonBackground,
        border: Border.all(
          color: context.purpleButtonBorder,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.spacing8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing20,
        vertical: AppSpacing.spacing12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto Create',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create transaction on billing date automatically',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends HookConsumerWidget {
  final int recurringId;
  final RecurringStatus currentStatus;

  const _ActionButtons({
    required this.recurringId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaused = currentStatus == RecurringStatus.paused;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacing8),
      child: Row(
        children: [
          // Pause/Resume Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  final db = ref.read(databaseProvider);
                  if (isPaused) {
                    await db.recurringDao.resumeRecurring(recurringId);
                  } else {
                    await db.recurringDao.pauseRecurring(recurringId);
                  }

                  // Sync to cloud
                  final user = ref.read(authStateProvider).valueOrNull;
                  if (user?.uid != null) {
                    try {
                      final syncService = ref.read(cloudSyncServiceProvider);
                      final recurringEntity = await (db.select(db.recurrings)
                            ..where((r) => r.id.equals(recurringId)))
                          .getSingleOrNull();

                      if (recurringEntity != null) {
                        await syncService.syncRecurring(recurringEntity);
                      }
                    } catch (e) {
                      // Silently fail cloud sync
                    }
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isPaused
                              ? 'Recurring payment resumed'
                              : 'Recurring payment paused',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                size: 20,
              ),
              label: Text(isPaused ? 'Resume' : 'Pause'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          // Delete Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Recurring Payment'),
                    content: const Text(
                      'Are you sure you want to delete this recurring payment? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  try {
                    final db = ref.read(databaseProvider);

                    // Sync delete to cloud first
                    final user = ref.read(authStateProvider).valueOrNull;
                    if (user?.uid != null) {
                      try {
                        final syncService = ref.read(cloudSyncServiceProvider);
                        final recurringEntity = await (db.select(db.recurrings)
                              ..where((r) => r.id.equals(recurringId)))
                            .getSingleOrNull();

                        if (recurringEntity != null) {
                          await syncService.deleteRecurring(recurringEntity);
                        }
                      } catch (e) {
                        // Silently fail cloud sync
                      }
                    }

                    // Delete from local database
                    await db.recurringDao.deleteRecurring(recurringId);
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close form
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
              ),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

