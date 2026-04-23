import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/features/recurring/services/recurring_notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/core/database/database_provider.dart';

/// Provider for recurring form state
final recurringFormProvider = NotifierProvider<RecurringFormNotifier, RecurringFormState>(
  RecurringFormNotifier.new,
);

/// Recurring form state
class RecurringFormState {
  final RecurringModel? editingRecurring;
  final String name;
  final String? description;
  final WalletModel? wallet;
  final CategoryModel? category;
  final double amount;
  final DateTime startDate;
  final DateTime nextDueDate;
  final RecurringFrequency frequency;
  final int? customInterval;
  final String? customUnit;
  final int? billingDay;
  final DateTime? endDate;
  final RecurringStatus status;
  final bool autoCreate;
  final bool enableReminder;
  final int reminderDaysBefore;
  final String? notes;
  final String? vendorName;
  final String? iconName;
  final String? colorHex;
  final bool isLoading;
  final String? errorMessage;

  RecurringFormState({
    this.editingRecurring,
    this.name = '',
    this.description,
    this.wallet,
    this.category,
    this.amount = 0.0,
    DateTime? startDate,
    DateTime? nextDueDate,
    this.frequency = RecurringFrequency.monthly,
    this.customInterval,
    this.customUnit,
    this.billingDay,
    this.endDate,
    this.status = RecurringStatus.active,
    this.autoCreate = false,
    this.enableReminder = true,
    this.reminderDaysBefore = 3,
    this.notes,
    this.vendorName,
    this.iconName,
    this.colorHex,
    this.isLoading = false,
    this.errorMessage,
  })  : startDate = startDate ?? DateTime.now(),
        nextDueDate = nextDueDate ?? DateTime.now();

  RecurringFormState copyWith({
    RecurringModel? editingRecurring,
    String? name,
    String? description,
    WalletModel? wallet,
    CategoryModel? category,
    double? amount,
    DateTime? startDate,
    DateTime? nextDueDate,
    RecurringFrequency? frequency,
    int? customInterval,
    String? customUnit,
    int? billingDay,
    DateTime? endDate,
    RecurringStatus? status,
    bool? autoCreate,
    bool? enableReminder,
    int? reminderDaysBefore,
    String? notes,
    String? vendorName,
    String? iconName,
    String? colorHex,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecurringFormState(
      editingRecurring: editingRecurring ?? this.editingRecurring,
      name: name ?? this.name,
      description: description ?? this.description,
      wallet: wallet ?? this.wallet,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      frequency: frequency ?? this.frequency,
      customInterval: customInterval ?? this.customInterval,
      customUnit: customUnit ?? this.customUnit,
      billingDay: billingDay ?? this.billingDay,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      autoCreate: autoCreate ?? this.autoCreate,
      enableReminder: enableReminder ?? this.enableReminder,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      vendorName: vendorName ?? this.vendorName,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isValid {
    return name.isNotEmpty &&
        wallet != null &&
        category != null &&
        amount > 0;
  }
}

/// Notifier for recurring form state
class RecurringFormNotifier extends Notifier<RecurringFormState> {
  @override
  RecurringFormState build() => RecurringFormState();

  /// Initialize form with existing recurring for editing
  void initializeWithRecurring(RecurringModel recurring) {
    state = RecurringFormState(
      editingRecurring: recurring,
      name: recurring.name,
      description: recurring.description,
      wallet: recurring.wallet,
      category: recurring.category,
      amount: recurring.amount,
      startDate: recurring.startDate,
      nextDueDate: recurring.nextDueDate,
      frequency: recurring.frequency,
      customInterval: recurring.customInterval,
      customUnit: recurring.customUnit,
      billingDay: recurring.billingDay,
      endDate: recurring.endDate,
      status: recurring.status,
      autoCreate: recurring.autoCreate,
      enableReminder: recurring.enableReminder,
      reminderDaysBefore: recurring.reminderDaysBefore,
      notes: recurring.notes,
      vendorName: recurring.vendorName,
      iconName: recurring.iconName,
      colorHex: recurring.colorHex,
    );
  }

  /// Initialize form with default wallet and category
  void initializeWithDefaults({
    required WalletModel wallet,
    required CategoryModel category,
  }) {
    state = state.copyWith(
      wallet: wallet,
      category: category,
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setDescription(String? description) {
    state = state.copyWith(description: description);
  }

  void setWallet(WalletModel wallet) {
    state = state.copyWith(wallet: wallet);
  }

  void setCategory(CategoryModel category) {
    state = state.copyWith(category: category);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setNextDueDate(DateTime date) {
    state = state.copyWith(nextDueDate: date);
  }

  void setFrequency(RecurringFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setCustomInterval(int? interval) {
    state = state.copyWith(customInterval: interval);
  }

  void setCustomUnit(String? unit) {
    state = state.copyWith(customUnit: unit);
  }

  void setBillingDay(int? day) {
    state = state.copyWith(billingDay: day);
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date);
  }

  void setStatus(RecurringStatus status) {
    state = state.copyWith(status: status);
  }

  void setAutoCreate(bool autoCreate) {
    state = state.copyWith(autoCreate: autoCreate);
  }

  void setEnableReminder(bool enableReminder) {
    state = state.copyWith(enableReminder: enableReminder);
  }

  void setReminderDaysBefore(int days) {
    state = state.copyWith(reminderDaysBefore: days);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void setVendorName(String? vendorName) {
    state = state.copyWith(vendorName: vendorName);
  }

  void setIconName(String? iconName) {
    state = state.copyWith(iconName: iconName);
  }

  void setColorHex(String? colorHex) {
    state = state.copyWith(colorHex: colorHex);
  }

  /// Reset form to initial state
  void reset() {
    state = RecurringFormState();
  }

  /// Save recurring (add or update)
  Future<bool> save() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Please fill all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final actions = ref.read(recurringActionsProvider);

      final recurring = RecurringModel(
        id: state.editingRecurring?.id,
        cloudId: state.editingRecurring?.cloudId,
        name: state.name,
        description: state.description,
        wallet: state.wallet!,
        category: state.category!,
        amount: state.amount,
        currency: state.wallet!.currency,
        startDate: state.startDate,
        nextDueDate: state.nextDueDate,
        frequency: state.frequency,
        customInterval: state.customInterval,
        customUnit: state.customUnit,
        billingDay: state.billingDay,
        endDate: state.endDate,
        status: state.status,
        autoCreate: state.autoCreate,
        enableReminder: state.enableReminder,
        reminderDaysBefore: state.reminderDaysBefore,
        notes: state.notes,
        vendorName: state.vendorName,
        iconName: state.iconName,
        colorHex: state.colorHex,
        lastChargedDate: state.editingRecurring?.lastChargedDate,
        totalPayments: state.editingRecurring?.totalPayments ?? 0,
        createdAt: state.editingRecurring?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      int? savedRecurringId;
      if (state.editingRecurring != null) {
        // Update existing
        final success = await actions.updateRecurring(recurring);
        if (success) {
          savedRecurringId = recurring.id;
          Log.i('Recurring updated successfully', label: 'RecurringForm');
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to update recurring',
          );
          return false;
        }
      } else {
        // Check subscription limit before creating new recurring
        final limits = ref.read(subscriptionLimitsProvider);
        final db = ref.read(databaseProvider);
        final allRecurrings = await db.recurringDao.getAllRecurrings();
        if (!limits.isWithinLimit(allRecurrings.length, limits.maxRecurring)) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'You have reached the maximum of ${limits.maxRecurring} recurring transactions. Upgrade to Plus for unlimited.',
          );
          return false;
        }

        // Add new
        final id = await actions.addRecurring(recurring);
        if (id > 0) {
          savedRecurringId = id;
          Log.i('Recurring added successfully with ID: $id', label: 'RecurringForm');
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to add recurring',
          );
          return false;
        }
      }

      // TODO: Implement Supabase sync for recurring transactions
      // Cloud sync removed with Firebase Auth migration
      if (savedRecurringId != null) {
        try {
          Log.i('Recurring saved locally (cloud sync not implemented)', label: 'RecurringForm');
        } catch (e) {
          Log.e('Error: $e', label: 'RecurringForm');
          // Don't fail the save operation if cloud sync fails
        }
      }

      // Create transaction immediately if recurring is due and auto-create is enabled
      if (state.autoCreate && savedRecurringId != null) {
        try {
          final today = DateTime.now();
          final dueDateOnly = DateTime(state.nextDueDate.year, state.nextDueDate.month, state.nextDueDate.day);
          final todayOnly = DateTime(today.year, today.month, today.day);

          // If next due date is today or in the past, create transaction immediately
          if (dueDateOnly.isBefore(todayOnly) || dueDateOnly.isAtSameMomentAs(todayOnly)) {
            Log.i('Recurring is due now, creating transaction...', label: 'RecurringForm');
            final chargeService = ref.read(recurringChargeServiceProvider);
            await chargeService.createDueTransactions();
            Log.i('Transaction created for new recurring', label: 'RecurringForm');
          }
        } catch (e) {
          Log.e('Failed to create transaction for recurring: $e', label: 'RecurringForm');
          // Don't fail the save operation if transaction creation fails
        }
      }

      // Schedule notification for this recurring payment
      if (savedRecurringId != null) {
        try {
          // Create a complete recurring model with the saved ID
          final savedRecurring = recurring.copyWith(id: savedRecurringId);
          await RecurringNotificationService.scheduleNotification(savedRecurring);
          Log.i('Notification scheduled for recurring $savedRecurringId', label: 'RecurringForm');
        } catch (e) {
          Log.e('Failed to schedule notification: $e', label: 'RecurringForm');
          // Don't fail the save operation if notification scheduling fails
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      Log.e('Error saving recurring: $e', label: 'RecurringForm');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: $e',
      );
      return false;
    }
  }
}

