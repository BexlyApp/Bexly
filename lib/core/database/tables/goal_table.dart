import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';

@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get iconName => text().nullable()();
  IntColumn get associatedAccountId => integer().nullable()();
  BoolColumn get pinned => boolean().nullable()();
}

extension GoalExtension on Goal {
  /// Creates a [Goal] instance from a map, typically from JSON deserialization.
  Goal fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int,
      cloudId: json['cloudId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetAmount: json['targetAmount'] as double,
      currentAmount: json['currentAmount'] as double,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      iconName: json['iconName'] as String?,
      associatedAccountId: json['associatedAccountId'] as int?,
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

extension GoalTableExtensions on Goal {
  /// Converts this Drift [Goal] data class to a [GoalModel].
  GoalModel toModel() {
    return GoalModel(
      id: id,
      cloudId: cloudId,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      iconName: iconName,
      description: description,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      associatedAccountId: associatedAccountId,
      pinned: pinned ?? false,
    );
  }
}

/// Extension to convert GoalModel to Drift companion
extension GoalModelExtensions on GoalModel {
  GoalsCompanion toCompanion({bool isInsert = false}) {
    return GoalsCompanion(
      id: isInsert
          ? const Value.absent()
          : (id == null ? const Value.absent() : Value(id!)),
      cloudId: cloudId == null ? const Value.absent() : Value(cloudId),
      title: Value(title),
      description: Value(description),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      startDate: Value(startDate),
      endDate: Value(endDate),
      createdAt: Value(createdAt),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
      iconName: Value(iconName),
      associatedAccountId: Value(associatedAccountId),
      pinned: Value(pinned),
    );
  }
}
