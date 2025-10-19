import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';

@DataClassName('Budget') // Name of the generated data class
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isRoutine => boolean()();
}

extension BudgetExtension on Budget {
  /// Creates a [Budget] instance from a map, typically from JSON deserialization.
  Budget fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int,
      walletId: json['walletId'] as int,
      categoryId: json['categoryId'] as int,
      amount: json['amount'] as double,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isRoutine: json['isRoutine'] as bool,
    );
  }
}
