import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/features/category/data/model/category_model.dart';

// Define tables
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()();
  TextColumn get iconBackground => text().nullable()();
  TextColumn get iconType => text().nullable()();
  IntColumn get parentId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
    onUpdate: KeyAction.cascade,
  )();
  TextColumn get description => text().nullable()();

  /// System default categories cannot be deleted by cloud sync
  /// These are the initial categories created on first app launch
  BoolColumn get isSystemDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

extension CategoryExtension on Category {
  /// Creates a [Category] instance from a map, typically from JSON deserialization.
  Category fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      cloudId: json['cloudId'] as String?,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      iconBackground: json['iconBackground'] as String?,
      iconType: json['iconType'] as String?,
      parentId: json['parentId'] as int?,
      description: json['description'] as String?,
      isSystemDefault: json['isSystemDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

extension CategoryTableExtensions on Category {
  /// Converts this Drift [Category] data class to a [CategoryModel].
  ///
  /// Note: The `subCategories` field in [CategoryModel] is not populated
  /// by this direct conversion as the Drift [Category] object doesn't
  /// inherently store its children. Fetching and assembling sub-categories
  /// is typically handled at a higher layer (e.g., a repository or service)
  /// that can query for children based on `parentId`.
  CategoryModel toModel() {
    return CategoryModel(
      id: id,
      cloudId: cloudId,
      title: title,
      icon: icon ?? '',
      iconBackground: iconBackground ?? '',
      iconTypeValue: iconType ?? '',
      parentId: parentId,
      description: description,
      // subCategories are not directly available on the Drift Category object.
      // This needs to be populated by querying children if needed.
      subCategories: null,
      isSystemDefault: isSystemDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension methods for CategoryModel to convert to Drift companion
extension CategoryModelExtensions on CategoryModel {
  CategoriesCompanion toCompanion({bool isInsert = false}) {
    return CategoriesCompanion(
      id: isInsert
          ? const Value.absent()
          : (id == null ? const Value.absent() : Value(id!)),
      cloudId: cloudId == null ? const Value.absent() : Value(cloudId),
      title: Value(title),
      icon: Value(icon),
      iconBackground: Value(iconBackground),
      iconType: Value(iconTypeValue),
      parentId: Value(parentId),
      description: Value(description),
      isSystemDefault: Value(isSystemDefault),
      createdAt: createdAt != null
          ? Value(createdAt!)
          : (isInsert ? Value(DateTime.now()) : const Value.absent()),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
    );
  }
}
