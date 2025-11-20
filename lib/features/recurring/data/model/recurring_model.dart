import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';

part 'recurring_model.freezed.dart';
part 'recurring_model.g.dart';

/// Represents a recurring payment/bill/subscription
@freezed
abstract class RecurringModel with _$RecurringModel {
  const factory RecurringModel({
    /// Unique identifier (null for new recurrings)
    int? id,

    /// Cloud sync ID
    String? cloudId,

    /// Recurring payment name/title
    required String name,

    /// Optional description
    String? description,

    /// Wallet used for this recurring payment
    required WalletModel wallet,

    /// Category for expense tracking
    required CategoryModel category,

    /// Amount charged per billing cycle
    required double amount,

    /// Currency code (ISO 4217)
    required String currency,

    /// Start date of recurring payment
    required DateTime startDate,

    /// Next payment due date
    required DateTime nextDueDate,

    /// Billing frequency
    required RecurringFrequency frequency,

    /// Custom interval (for custom frequency)
    int? customInterval,

    /// Custom interval unit (for custom frequency)
    String? customUnit,

    /// Billing day (day of month or day of week)
    int? billingDay,

    /// End date (null = no end date)
    DateTime? endDate,

    /// Current status
    required RecurringStatus status,

    /// Auto-create transactions when due
    @Default(false) bool autoCreate,

    /// Enable payment reminders
    @Default(true) bool enableReminder,

    /// Days before due date to remind
    @Default(3) int reminderDaysBefore,

    /// Additional notes
    String? notes,

    /// Vendor/service name
    String? vendorName,

    /// Icon for display
    String? iconName,

    /// Color for visual identification
    String? colorHex,

    /// Last payment date
    DateTime? lastChargedDate,

    /// Total number of payments made
    @Default(0) int totalPayments,

    /// Creation timestamp
    DateTime? createdAt,

    /// Last update timestamp
    DateTime? updatedAt,
  }) = _RecurringModel;

  factory RecurringModel.fromJson(Map<String, dynamic> json) =>
      _$RecurringModelFromJson(json);
}

/// Utility extensions for RecurringModel
extension RecurringModelUtils on RecurringModel {
  /// Check if recurring payment is currently active
  bool get isActive => status == RecurringStatus.active;

  /// Check if payment is due today
  bool get isDueToday {
    final today = DateTime.now();
    return nextDueDate.year == today.year &&
        nextDueDate.month == today.month &&
        nextDueDate.day == today.day;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return todayDate.isAfter(dueDate) && isActive;
  }

  /// Days until next payment
  int get daysUntilDue {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDate.difference(todayDate).inDays;
  }

  /// Check if reminder should be shown
  bool get shouldShowReminder {
    return enableReminder &&
        isActive &&
        daysUntilDue <= reminderDaysBefore &&
        daysUntilDue >= 0;
  }

  /// Calculate next due date based on frequency
  DateTime calculateNextDueDate() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextDueDate.add(const Duration(days: 1));

      case RecurringFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));

      case RecurringFrequency.monthly:
        return _addMonths(nextDueDate, 1);

      case RecurringFrequency.quarterly:
        return _addMonths(nextDueDate, 3);

      case RecurringFrequency.yearly:
        return _addMonths(nextDueDate, 12);

      case RecurringFrequency.custom:
        if (customInterval == null || customUnit == null) {
          throw Exception('Custom interval requires interval and unit');
        }
        switch (customUnit) {
          case 'days':
            return nextDueDate.add(Duration(days: customInterval!));
          case 'weeks':
            return nextDueDate.add(Duration(days: customInterval! * 7));
          case 'months':
            return _addMonths(nextDueDate, customInterval!);
          case 'years':
            return _addMonths(nextDueDate, customInterval! * 12);
          default:
            throw Exception('Invalid custom unit: $customUnit');
        }
    }
  }

  /// Helper to add months while preserving day of month
  DateTime _addMonths(DateTime date, int months) {
    int targetYear = date.year;
    int targetMonth = date.month + months;

    // Handle year overflow
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }
    while (targetMonth < 1) {
      targetMonth += 12;
      targetYear--;
    }

    // Use billing day if available, otherwise use current day
    int targetDay = billingDay ?? date.day;

    // Handle invalid dates (e.g., Feb 31 -> Feb 28/29)
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > daysInMonth) {
      targetDay = daysInMonth;
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Calculate total cost per month (for budgeting)
  double get monthlyCost {
    switch (frequency) {
      case RecurringFrequency.daily:
        return amount * 30; // Approximate
      case RecurringFrequency.weekly:
        return amount * 4.33; // Average weeks per month
      case RecurringFrequency.monthly:
        return amount;
      case RecurringFrequency.quarterly:
        return amount / 3;
      case RecurringFrequency.yearly:
        return amount / 12;
      case RecurringFrequency.custom:
        if (customInterval == null || customUnit == null) return 0;
        switch (customUnit) {
          case 'days':
            return amount * (30 / customInterval!);
          case 'weeks':
            return amount * (4.33 / customInterval!);
          case 'months':
            return amount / customInterval!;
          case 'years':
            return amount / (customInterval! * 12);
          default:
            return 0;
        }
    }
  }

  /// Calculate total cost per year
  double get yearlyCost {
    return monthlyCost * 12;
  }

  /// Get formatted frequency display
  String get frequencyDisplay {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
      case RecurringFrequency.custom:
        return 'Every $customInterval ${customUnit ?? ''}';
    }
  }

  /// Check if recurring payment has ended
  bool get hasEnded {
    if (endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(endDate!);
  }

  /// Days remaining until end (null if no end date)
  int? get daysUntilEnd {
    if (endDate == null) return null;
    final now = DateTime.now();
    return endDate!.difference(now).inDays;
  }
}

/// Extension for list of recurring payments
extension RecurringListUtils on List<RecurringModel> {
  /// Get total monthly cost across all recurring payments
  double get totalMonthlyCost {
    return fold(0.0, (sum, recurring) => sum + recurring.monthlyCost);
  }

  /// Get total yearly cost across all recurring payments
  double get totalYearlyCost {
    return fold(0.0, (sum, recurring) => sum + recurring.yearlyCost);
  }

  /// Filter active recurring payments
  List<RecurringModel> get activeRecurrings {
    return where((r) => r.isActive).toList();
  }

  /// Filter overdue recurring payments
  List<RecurringModel> get overdueRecurrings {
    return where((r) => r.isOverdue).toList();
  }

  /// Filter recurring payments due within specified days
  List<RecurringModel> dueWithinDays(int days) {
    return where((r) => r.isActive && r.daysUntilDue <= days && r.daysUntilDue >= 0)
        .toList();
  }

  /// Sort by next due date (earliest first)
  List<RecurringModel> sortByDueDate() {
    final list = List<RecurringModel>.from(this);
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  /// Sort by amount (highest first)
  List<RecurringModel> sortByAmount() {
    final list = List<RecurringModel>.from(this);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Sort by name (alphabetically)
  List<RecurringModel> sortByName() {
    final list = List<RecurringModel>.from(this);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
