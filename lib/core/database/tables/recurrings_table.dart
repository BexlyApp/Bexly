import 'package:drift/drift.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Represents the `recurrings` table in the database
@DataClassName('Recurring')
class Recurrings extends Table {
  /// Unique identifier for the recurring payment (local ID)
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  /// Name/title of the recurring payment (e.g., "Netflix Premium", "Electric Bill")
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Optional description or notes about the recurring payment
  TextColumn get description => text().nullable()();

  /// Foreign key referencing the Wallets table
  IntColumn get walletId => integer().references(Wallets, #id)();

  /// Foreign key referencing the Categories table
  IntColumn get categoryId => integer().references(Categories, #id)();

  /// Payment amount per billing cycle
  RealColumn get amount => real()();

  /// Currency code (ISO 4217) - typically inherited from wallet
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Date when the recurring payment started
  DateTimeColumn get startDate => dateTime()();

  /// Next due date for payment
  DateTimeColumn get nextDueDate => dateTime()();

  /// Billing frequency (0=daily, 1=weekly, 2=monthly, 3=quarterly, 4=yearly, 5=custom)
  IntColumn get frequency => integer()();

  /// Custom interval number (e.g., 3 for "every 3 months")
  /// Only used when frequency is custom
  IntColumn get customInterval => integer().nullable()();

  /// Custom interval unit ('days', 'weeks', 'months', 'years')
  /// Only used when frequency is custom
  TextColumn get customUnit => text().nullable()();

  /// Day of month for billing (1-31) for monthly/quarterly/yearly
  /// Or day of week (0-6) for weekly recurring payments
  IntColumn get billingDay => integer().nullable()();

  /// Optional end date (null means no end date)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Recurring payment status (0=active, 1=paused, 2=cancelled, 3=expired)
  IntColumn get status => integer()();

  /// Whether to automatically create transactions when due
  BoolColumn get autoCreate => boolean().withDefault(const Constant(false))();

  /// Whether to enable payment reminders
  BoolColumn get enableReminder => boolean().withDefault(const Constant(true))();

  /// Number of days before due date to send reminder
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(3))();

  /// Additional notes about the recurring payment
  TextColumn get notes => text().nullable()();

  /// Vendor/service name (e.g., "Netflix", "Spotify", "Electric Company")
  TextColumn get vendorName => text().nullable()();

  /// Icon name for display
  TextColumn get iconName => text().nullable()();

  /// Color hex code for visual identification
  TextColumn get colorHex => text().nullable()();

  /// Last date when payment was processed
  DateTimeColumn get lastChargedDate => dateTime().nullable()();

  /// Total number of payments made so far
  IntColumn get totalPayments => integer().withDefault(const Constant(0))();

  /// Timestamp of when the recurring payment was created in the database
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp of when the recurring payment was last updated in the database
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Extension to convert Recurring entity to RecurringModel
extension RecurringTableExtensions on Recurring {
  RecurringModel toModel({
    required CategoryModel category,
    required WalletModel wallet,
  }) {
    return RecurringModel(
      id: id,
      cloudId: cloudId,
      name: name,
      description: description,
      wallet: wallet,
      category: category,
      amount: amount,
      currency: currency,
      startDate: startDate,
      nextDueDate: nextDueDate,
      frequency: RecurringFrequency.values[frequency],
      customInterval: customInterval,
      customUnit: customUnit,
      billingDay: billingDay,
      endDate: endDate,
      status: RecurringStatus.values[status],
      autoCreate: autoCreate,
      enableReminder: enableReminder,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes,
      vendorName: vendorName,
      iconName: iconName,
      colorHex: colorHex,
      lastChargedDate: lastChargedDate,
      totalPayments: totalPayments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
