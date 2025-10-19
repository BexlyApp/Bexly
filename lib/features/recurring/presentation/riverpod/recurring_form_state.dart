import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/core/utils/logger.dart';

/// Provider for recurring form state
final recurringFormProvider = StateNotifierProvider.autoDispose<RecurringFormNotifier, RecurringFormState>((ref) {
  return RecurringFormNotifier(ref);
});

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
  final bool autoCharge;
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
    this.autoCharge = false,
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
    bool? autoCharge,
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
      autoCharge: autoCharge ?? this.autoCharge,
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
class RecurringFormNotifier extends StateNotifier<RecurringFormState> {
  final Ref _ref;

  RecurringFormNotifier(this._ref) : super(RecurringFormState());

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
      autoCharge: recurring.autoCharge,
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

  void setAutoCharge(bool autoCharge) {
    state = state.copyWith(autoCharge: autoCharge);
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
      final actions = _ref.read(recurringActionsProvider);

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
        autoCharge: state.autoCharge,
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

      if (state.editingRecurring != null) {
        // Update existing
        final success = await actions.updateRecurring(recurring);
        if (success) {
          Log.i('Recurring updated successfully', label: 'RecurringForm');
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to update recurring',
          );
          return false;
        }
      } else {
        // Add new
        final id = await actions.addRecurring(recurring);
        if (id > 0) {
          Log.i('Recurring added successfully with ID: $id', label: 'RecurringForm');
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to add recurring',
          );
          return false;
        }
      }
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
