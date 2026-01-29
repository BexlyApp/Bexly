import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/utils/retry_helper.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';
import 'package:bexly/features/category/data/model/category_model.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  final Ref? _ref;

  CategoryDao(super.db, [this._ref]);

  // --- Read Operations ---

  /// Watches all categories in the database (including soft-deleted).
  /// Returns a stream that emits a new list of categories whenever the data changes.
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  /// Fetches all categories from the database once (including soft-deleted).
  Future<List<Category>> getAllCategories() => select(categories).get();

  /// Watches only non-deleted categories (recommended for UI)
  /// Returns a stream that emits a new list of active categories
  Stream<List<Category>> watchActiveCategories() {
    return (select(categories)..where((tbl) => tbl.isDeleted.equals(false))).watch();
  }

  /// Fetches only non-deleted categories (recommended for UI)
  Future<List<Category>> getActiveCategories() {
    return (select(categories)..where((tbl) => tbl.isDeleted.equals(false))).get();
  }

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
  /// Generates a UUID v7 for cloudId if not provided.
  /// Returns the inserted [Category] object.
  Future<Category> addCategory(CategoriesCompanion categoryCompanion) async {
    Log.d('Adding new category', label: 'category');

    // 1. Generate cloudId if not provided
    final companionWithCloudId = categoryCompanion.cloudId.present
        ? categoryCompanion
        : categoryCompanion.copyWith(cloudId: Value(const Uuid().v7()));

    if (!categoryCompanion.cloudId.present) {
      Log.d('Generated cloudId: ${companionWithCloudId.cloudId.value}', label: 'category');
    }

    // 2. Save to local database WITH cloudId
    final category = await into(categories).insertReturning(companionWithCloudId);

    // 3. Upload to cloud with retry (if sync available)
    if (_ref != null) {
      final cloudId = category.cloudId;
      if (cloudId != null) {
        // Fire and forget upload (don't block UI)
        _uploadCategoryWithRetry(category.id, cloudId).catchError((e) {
          Log.e('Failed to upload category: $e', label: 'sync');
        });
      }
    }

    return category;
  }

  // --- Update Operations ---

  /// Updates an existing category in the database.
  /// This uses `replace` which means all fields of the [category] object will be updated.
  /// Returns `true` if the update was successful, `false` otherwise.
  ///
  /// Modified Hybrid Sync: When updating built-in category, marks hasBeenModified = true
  Future<bool> updateCategory(Category category) async {
    Log.d('Updating category: ${category.id}', label: 'category');

    // Modified Hybrid Sync: Mark built-in categories as modified
    Category categoryToUpdate = category;
    if (category.source == 'built-in' && category.hasBeenModified == false) {
      Log.d('Marking built-in category as modified: ${category.title}', label: 'category');
      categoryToUpdate = category.copyWith(
        hasBeenModified: true,
        updatedAt: DateTime.now(),
      );
    }

    // 1. Update local database
    final success = await update(categories).replace(categoryToUpdate);

    // 2. Upload to cloud with retry (if sync available)
    // Modified Hybrid Sync: Will only sync if custom or modified built-in
    if (success && _ref != null && categoryToUpdate.cloudId != null) {
      // Fire and forget upload (don't block UI)
      _uploadCategoryWithRetry(categoryToUpdate.id, categoryToUpdate.cloudId!).catchError((e) {
        Log.e('Failed to upload category update: $e', label: 'sync');
      });
    }

    return success;
  }

  /// Upserts a category: inserts if new, updates if exists based on primary key.
  ///
  /// Modified Hybrid Sync: Allows upsert for all categories
  Future<int> upsertCategory(CategoriesCompanion categoryCompanion) async {
    return into(categories).insertOnConflictUpdate(categoryCompanion);
  }

  // --- Delete Operations ---

  /// Soft deletes a category by its ID.
  /// Sets is_deleted = true to sync deletion across devices
  /// Returns the number of rows affected (usually 1 if successful).
  ///
  /// Modified Hybrid Sync: Uses soft delete for cross-device consistency
  Future<int> deleteCategoryById(int id) async {
    Log.d('Soft deleting category with ID: $id', label: 'category');

    // 1. Get category to retrieve cloudId
    final category = await getCategoryById(id);
    if (category == null) {
      Log.w('Category $id not found', label: 'category');
      return 0;
    }

    // 2. Soft delete: Update is_deleted = true
    final updatedCategory = category.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );

    // For built-in categories, also mark as modified to trigger cloud sync
    final categoryToUpdate = category.source == 'built-in'
        ? updatedCategory.copyWith(hasBeenModified: true)
        : updatedCategory;

    final success = await update(categories).replace(categoryToUpdate);

    // 3. Sync deletion to cloud (if sync available and has cloudId)
    if (success && _ref != null && category.cloudId != null) {
      try {
        final syncService = _ref.read(supabaseSyncServiceProvider);
        if (syncService.isAuthenticated) {
          await syncService.deleteCategoryFromCloud(category.cloudId!);
        }
      } catch (e, stack) {
        Log.e('Failed to sync category deletion to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return success ? 1 : 0;
  }

  // --- Upload Helpers ---

  /// Upload category with retry logic (fire and forget)
  Future<void> _uploadCategoryWithRetry(int categoryId, String cloudId) async {
    return RetryHelper.retry(
      operationName: 'Upload category $cloudId',
      operation: () async {
        final syncService = _ref?.read(supabaseSyncServiceProvider);
        if (syncService == null || !syncService.isAuthenticated) {
          Log.w('Supabase sync not available or not authenticated', label: 'sync');
          return;
        }

        final category = await getCategoryById(categoryId);
        if (category == null) {
          throw Exception('Category $categoryId not found');
        }

        await syncService.uploadCategory(category.toModel());
        Log.d('✅ Category uploaded: ${category.title}', label: 'sync');
      },
    );
  }

  // --- Sync Operations ---

  /// Create or update category (used by sync service to pull from cloud)
  /// Uses cloudId to find existing category, or creates new one
  /// NOTE: This method does NOT sync back to cloud (to avoid infinite loop)
  Future<void> createOrUpdateCategory(CategoryModel categoryModel) async {
    Log.d('Creating or updating category from cloud: ${categoryModel.cloudId}', label: 'category');

    // Check if category exists by cloudId
    final existingCategory = categoryModel.cloudId != null
        ? await getCategoryByCloudId(categoryModel.cloudId!)
        : null;

    if (existingCategory != null) {
      // Update existing category (local only, no cloud sync)
      // Preserve the local ID
      final companion = CategoriesCompanion(
        id: Value(existingCategory.id),
        cloudId: Value(categoryModel.cloudId),
        title: Value(categoryModel.title),
        icon: Value(categoryModel.icon),
        iconBackground: Value(categoryModel.iconBackground),
        iconType: Value(categoryModel.iconTypeValue), // Field name is iconType in table
        parentId: Value(categoryModel.parentId),
        description: Value(categoryModel.description),
        localizedTitles: Value(categoryModel.localizedTitles),
        isSystemDefault: Value(categoryModel.isSystemDefault),
        source: Value(categoryModel.source ?? 'built-in'),  // Modified Hybrid Sync
        builtInId: Value(categoryModel.builtInId),  // Modified Hybrid Sync
        hasBeenModified: Value(categoryModel.hasBeenModified ?? false),  // Modified Hybrid Sync
        isDeleted: Value(categoryModel.isDeleted ?? false),  // Soft delete support
        transactionType: Value(categoryModel.transactionType),
        createdAt: categoryModel.createdAt != null
            ? Value(categoryModel.createdAt!)
            : const Value.absent(),
        updatedAt: Value(categoryModel.updatedAt ?? DateTime.now()),
      );
      await update(categories).replace(companion);
      Log.d('Updated existing category ${existingCategory.id} from cloud', label: 'category');
    } else {
      // Create new category (local only, no cloud sync)
      final companion = CategoriesCompanion.insert(
        cloudId: Value(categoryModel.cloudId),
        title: categoryModel.title,
        icon: Value(categoryModel.icon),
        iconBackground: Value(categoryModel.iconBackground),
        iconType: Value(categoryModel.iconTypeValue), // Field name is iconType in table
        parentId: Value(categoryModel.parentId),
        description: Value(categoryModel.description ?? ''),
        localizedTitles: Value(categoryModel.localizedTitles),
        isSystemDefault: Value(categoryModel.isSystemDefault),
        source: Value(categoryModel.source ?? 'built-in'),  // Modified Hybrid Sync
        builtInId: Value(categoryModel.builtInId),  // Modified Hybrid Sync
        hasBeenModified: Value(categoryModel.hasBeenModified ?? false),  // Modified Hybrid Sync
        isDeleted: Value(categoryModel.isDeleted ?? false),  // Soft delete support
        transactionType: categoryModel.transactionType,
        createdAt: categoryModel.createdAt != null
            ? Value(categoryModel.createdAt!)
            : Value(DateTime.now()),
        updatedAt: Value(categoryModel.updatedAt ?? DateTime.now()),
      );
      final id = await into(categories).insert(companion);
      Log.d('Created new category $id from cloud', label: 'category');
    }
  }
}
