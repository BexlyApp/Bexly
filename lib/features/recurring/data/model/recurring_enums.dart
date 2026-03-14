import 'package:flutter/widgets.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

/// Enum representing different recurring payment frequencies
enum RecurringFrequency {
  /// Billed every day
  daily,

  /// Billed every week
  weekly,

  /// Billed every month
  monthly,

  /// Billed every 3 months
  quarterly,

  /// Billed every year
  yearly,

  /// Custom billing interval
  custom,
}

/// Enum representing the current status of a recurring payment
enum RecurringStatus {
  /// Recurring payment is currently active
  active,

  /// Recurring payment is temporarily paused by user
  paused,

  /// Recurring payment has been cancelled by user
  cancelled,

  /// Recurring payment has expired (end date reached)
  expired,
}

/// Extension methods for RecurringFrequency enum
extension RecurringFrequencyExtension on RecurringFrequency {
  /// Convert enum to database integer value
  int toDbValue() {
    return index;
  }

  /// Create enum from database integer value
  static RecurringFrequency fromDbValue(int value) {
    if (value >= 0 && value < RecurringFrequency.values.length) {
      return RecurringFrequency.values[value];
    }
    throw ArgumentError('Invalid integer value for RecurringFrequency: $value');
  }

  /// Get display name for the frequency.
  /// Prefer [localizedName] when a BuildContext is available.
  String get displayName {
    switch (this) {
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
        return 'Custom';
    }
  }
}

/// Extension methods for RecurringStatus enum
extension RecurringStatusExtension on RecurringStatus {
  /// Convert enum to database integer value
  int toDbValue() {
    return index;
  }

  /// Create enum from database integer value
  static RecurringStatus fromDbValue(int value) {
    if (value >= 0 && value < RecurringStatus.values.length) {
      return RecurringStatus.values[value];
    }
    throw ArgumentError('Invalid integer value for RecurringStatus: $value');
  }

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case RecurringStatus.active:
        return 'Active';
      case RecurringStatus.paused:
        return 'Paused';
      case RecurringStatus.cancelled:
        return 'Cancelled';
      case RecurringStatus.expired:
        return 'Expired';
    }
  }

  /// Check if recurring payment can be charged
  bool get canBeCharged {
    return this == RecurringStatus.active;
  }

  /// Check if recurring payment can be resumed
  bool get canBeResumed {
    return this == RecurringStatus.paused;
  }

  /// Check if recurring payment can be paused
  bool get canBePaused {
    return this == RecurringStatus.active;
  }
}

/// Context-aware display name for frequency (uses l10n).
extension RecurringFrequencyDisplay on RecurringFrequency {
  String localizedName(BuildContext context) {
    switch (this) {
      case RecurringFrequency.daily:
        return context.l10n.frequencyDaily;
      case RecurringFrequency.weekly:
        return context.l10n.frequencyWeekly;
      case RecurringFrequency.monthly:
        return context.l10n.frequencyMonthly;
      case RecurringFrequency.quarterly:
        return context.l10n.frequencyQuarterly;
      case RecurringFrequency.yearly:
        return context.l10n.frequencyYearly;
      case RecurringFrequency.custom:
        return context.l10n.frequencyCustom;
    }
  }
}