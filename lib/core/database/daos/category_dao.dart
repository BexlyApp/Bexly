import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  final Ref? _ref;

  CategoryDao(super.db, [this._ref]);

  // --- Read Operations ---

  /// Watches all categories in the database.
  /// Returns a stream that emits a new list of categories whenever the data changes.
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  /// Fetches all categories from the database once.
  Future<List<Category>> getAllCategories() => select(categories).get();

  /// Watches a single category by its ID.
  Stream<Category?> watchCategoryById(int id) {
    return (select(
      categories,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Fetches a single category by its ID once.
  Future<Category?> getCategoryById(int id) {
    return (select(
      categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get category by cloud ID (for sync operations)
  Future<Category?> getCategoryByCloudId(String cloudId) {
    return (select(categories)..where((c) => c.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  Future<List<Category>> getCategoriesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    return (select(categories)..where((c) => c.id.isIn(ids))).get();
  }

  /// Watches all top-level categories (those without a parentId).
  Stream<List<Category>> watchTopLevelCategories() {
    return (select(categories)..where((tbl) => tbl.parentId.isNull())).watch();
  }

  /// Fetches all top-level categories once.
  Future<List<Category>> getTopLevelCategories() {
    return (select(categories)..where((tbl) => tbl.parentId.isNull())).get();
  }

  /// Watches all sub-categories for a given parentId.
  Stream<List<Category>> watchSubCategories(int parentId) {
    return (select(
      categories,
    )..where((tbl) => tbl.parentId.equals(parentId))).watch();
  }

  /// Fetches all sub-categories for a given parentId once.
  Future<List<Category>> getSubCategories(int parentId) {
    return (select(
      categories,
    )..where((tbl) => tbl.parentId.equals(parentId))).get();
  }

  // --- Create Operations ---

  /// Inserts a new category into the database.
  /// The `id` within [categoryCompanion] should typically be a pre-generated UUID.
  /// Returns the inserted [Category] object.
  Future<Category> addCategory(CategoriesCompanion categoryCompanion) async {
    Log.d('Adding new category', label: 'category');

    // 1. Save to local database
    final category = await into(categories).insertReturning(categoryCompanion);

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadCategory(category.toModel());
      } catch (e, stack) {
        Log.e('Failed to upload category to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local save succeeded
      }
    }

    return category;
  }

  // --- Update Operations ---

  /// Updates an existing category in the database.
  /// This uses `replace` which means all fields of the [category] object will be updated.
  /// Returns `true` if the update was successful, `false` otherwise.
  ///
  /// PROTECTION: Cannot update system default categories (built-in categories)
  Future<bool> updateCategory(Category category) async {
    Log.d('Updating category: ${category.id}', label: 'category');

    // PROTECTION: Check if this is a system default category
    if (category.isSystemDefault) {
      Log.w('⚠️ BLOCKED: Cannot update system default category: ${category.title} (ID: ${category.id})', label: 'category');
      throw Exception('Cannot modify built-in categories. System categories are protected.');
    }

    // 1. Update local database
    final success = await update(categories).replace(category);

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadCategory(category.toModel());
      } catch (e, stack) {
        Log.e('Failed to upload category update to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local update succeeded
      }
    }

    return success;
  }

  /// Upserts a category: inserts if new, updates if exists based on primary key.
  ///
  /// PROTECTION: Only allow upsert for non-system categories OR system categories during initial population
  Future<int> upsertCategory(CategoriesCompanion categoryCompanion) async {
    // PROTECTION: If updating existing category, check if it's a system default
    if (categoryCompanion.id.present) {
      final existingCategory = await getCategoryById(categoryCompanion.id.value);
      if (existingCategory != null && existingCategory.isSystemDefault) {
        // Allow upsert ONLY if the companion is ALSO marked as system default
        // This allows repopulation but blocks user/sync overwrites
        if (!categoryCompanion.isSystemDefault.present || !categoryCompanion.isSystemDefault.value) {
          Log.w('⚠️ BLOCKED: Cannot upsert non-system data into system category: ${existingCategory.title} (ID: ${existingCategory.id})', label: 'category');
          throw Exception('Cannot modify built-in categories. System categories are protected from cloud sync.');
        }
      }
    }

    return into(categories).insertOnConflictUpdate(categoryCompanion);
  }

  // --- Delete Operations ---

  /// Deletes a category by its ID.
  /// Returns the number of rows affected (usually 1 if successful).
  ///
  /// PROTECTION: Cannot delete system default categories (built-in categories)
  Future<int> deleteCategoryById(int id) async {
    Log.d('Deleting category with ID: $id', label: 'category');

    // 1. Get category to retrieve cloudId AND check if system default
    final category = await getCategoryById(id);

    // PROTECTION: Check if this is a system default category
    if (category != null && category.isSystemDefault) {
      Log.w('⚠️ BLOCKED: Cannot delete system default category: ${category.title} (ID: ${category.id})', label: 'category');
      throw Exception('Cannot delete built-in categories. System categories are protected.');
    }

    // 2. Delete from local database
    final count = await (delete(categories)..where((tbl) => tbl.id.equals(id))).go();

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && category != null && category.cloudId != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.deleteCategoryFromCloud(category.cloudId!);
      } catch (e, stack) {
        Log.e('Failed to delete category from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return count;
  }
}
