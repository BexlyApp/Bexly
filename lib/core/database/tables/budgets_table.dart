import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

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

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

extension BudgetExtension on Budget {
  /// Creates a [Budget] instance from a map, typically from JSON deserialization.
  Budget fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int,
      cloudId: json['cloudId'] as String?,
      walletId: json['walletId'] as int,
      categoryId: json['categoryId'] as int,
      amount: json['amount'] as double,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isRoutine: json['isRoutine'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Extension to convert Budget entity to BudgetModel
extension BudgetTableExtensions on Budget {
  BudgetModel toModel({
    required CategoryModel category,
    required WalletModel wallet,
  }) {
    return BudgetModel(
      id: id,
      cloudId: cloudId,
      wallet: wallet,
      category: category,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRoutine: isRoutine,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert BudgetModel to Drift companion
extension BudgetModelExtensions on BudgetModel {
  BudgetsCompanion toCompanion({bool isInsert = false}) {
    return BudgetsCompanion(
      id: isInsert
          ? const Value.absent()
          : (id == null ? const Value.absent() : Value(id!)),
      cloudId: cloudId == null ? const Value.absent() : Value(cloudId),
      walletId: Value(wallet.id!),
      categoryId: Value(category.id!),
      amount: Value(amount),
      startDate: Value(startDate),
      endDate: Value(endDate),
      isRoutine: Value(isRoutine),
      createdAt: createdAt != null
          ? Value(createdAt!)
          : (isInsert ? Value(DateTime.now()) : const Value.absent()),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
    );
  }
}
