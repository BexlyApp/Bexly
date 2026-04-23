import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:drift/drift.dart';

/// Helper class to migrate existing local categories to Modified Hybrid Sync
///
/// This converts existing categories by:
/// 1. Setting source = 'built-in' (default)
/// 2. Setting has_been_modified = FALSE (unless already synced)
/// 3. Generating built_in_id from category name
/// 4. Setting is_deleted = FALSE
class CategoryMigrationHelper {
  static const _label = 'CategoryMigration';
  final AppDatabase _db;

  CategoryMigrationHelper(this._db);

  /// Run full migration on local database
  Future<MigrationResult> runMigration() async {
    Log.i('Starting category migration to Modified Hybrid Sync...', label: _label);

    try {
      // Get all categories
      final categories = await _db.categoryDao.getAllCategories();
      Log.d('Found ${categories.length} categories to migrate', label: _label);

      int updatedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (final category in categories) {
        try {
          // Check if already migrated (has source field populated)
          if (category.source != null && category.source!.isNotEmpty) {
            Log.d('Category ${category.title} already migrated, skipping', label: _label);
            skippedCount++;
            continue;
          }

          // Generate built-in ID from name
          final builtInId = _generateBuiltInId(category.title);

          // Determine if this is a modified category
          // Strategy: If cloudId exists, assume it was synced (modified)
          final hasBeenModified = category.cloudId != null;

          // Create updated category
          // Note: Drift copyWith requires Value<T> ONLY for nullable fields
          final updatedCategory = category.copyWith(
            source: 'built-in',  // NON-NULLABLE: pass directly
            builtInId: Value(builtInId),  // NULLABLE: wrap in Value
            hasBeenModified: hasBeenModified,  // NON-NULLABLE: pass directly
            isDeleted: false,  // NON-NULLABLE: pass directly
            updatedAt: DateTime.now(),  // NON-NULLABLE: pass directly
          );

          // Update in database
          await _db.categoryDao.updateCategory(updatedCategory);
          updatedCount++;

          Log.d(
            'Migrated: ${category.title} → built-in (modified: $hasBeenModified, id: $builtInId)',
            label: _label,
          );
        } catch (e) {
          Log.e('Failed to migrate category ${category.title}: $e', label: _label);
          errorCount++;
        }
      }

      final result = MigrationResult(
        totalCategories: categories.length,
        updated: updatedCount,
        skipped: skippedCount,
        errors: errorCount,
      );

      Log.i('Migration completed: $result', label: _label);
      return result;
    } catch (e, stack) {
      Log.e('Migration failed: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Generate stable built-in ID from category name
  /// Examples:
  ///   "Food & Drinks" → "food_drinks"
  ///   "Transport" → "transport"
  ///   "Bills & Utilities" → "bills_utilities"
  String _generateBuiltInId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')  // Trim leading/trailing underscores
        .replaceAll(RegExp(r'_+'), '_');     // Replace multiple underscores with single
  }

  /// Match categories to known built-in templates
  /// This can be used for cleanup optimization
  Future<void> matchBuiltInTemplates({
    required List<BuiltInCategoryTemplate> templates,
  }) async {
    Log.i('Matching categories to built-in templates...', label: _label);

    final categories = await _db.categoryDao.getActiveCategories();
    int matchedCount = 0;

    for (final category in categories) {
      if (category.source != 'built-in') continue;

      // Try to match to template
      final template = templates.firstWhere(
        (t) => t.builtInId == category.builtInId,
        orElse: () => BuiltInCategoryTemplate.empty(),
      );

      if (template.builtInId == null) {
        Log.d('No template match for: ${category.title}', label: _label);
        continue;
      }

      // Check if category matches template exactly
      final isExactMatch = category.title == template.name &&
                           category.icon == template.icon &&
                           category.iconBackground == template.iconBackground;

      if (isExactMatch) {
        // Mark as unmodified (no need to sync)
        final updated = category.copyWith(hasBeenModified: false);
        await _db.categoryDao.updateCategory(updated);
        matchedCount++;
        Log.d('Exact match: ${category.title} marked as unmodified', label: _label);
      }
    }

    Log.i('Matched $matchedCount categories to templates', label: _label);
  }

  /// Clean up soft-deleted categories older than X days
  Future<int> cleanupOldDeletedCategories({int olderThanDays = 30}) async {
    Log.i('Cleaning up soft-deleted categories older than $olderThanDays days...', label: _label);

    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    // Get all soft-deleted categories
    final allCategories = await _db.categoryDao.getAllCategories();
    final deletedCategories = allCategories.where((c) =>
        c.isDeleted == true &&
        c.updatedAt.isBefore(cutoffDate)
    ).toList();

    int hardDeletedCount = 0;
    for (final category in deletedCategories) {
      try {
        // Hard delete (permanent removal)
        await (_db.delete(_db.categories)
          ..where((c) => c.id.equals(category.id))
        ).go();

        hardDeletedCount++;
        Log.d('Hard deleted old category: ${category.title}', label: _label);
      } catch (e) {
        Log.e('Failed to hard delete category ${category.title}: $e', label: _label);
      }
    }

    Log.i('Cleaned up $hardDeletedCount old deleted categories', label: _label);
    return hardDeletedCount;
  }

  /// Verify migration integrity
  Future<MigrationVerification> verifyMigration() async {
    Log.i('Verifying migration integrity...', label: _label);

    final categories = await _db.categoryDao.getAllCategories();

    int withSource = 0;
    int withBuiltInId = 0;
    int withModifiedFlag = 0;
    int withDeletedFlag = 0;
    int missingFields = 0;

    for (final category in categories) {
      if (category.source != null) withSource++;
      if (category.builtInId != null) withBuiltInId++;
      if (category.hasBeenModified != null) withModifiedFlag++;
      if (category.isDeleted != null) withDeletedFlag++;

      if (category.source == null ||
          category.builtInId == null ||
          category.hasBeenModified == null ||
          category.isDeleted == null) {
        missingFields++;
        Log.w('Category ${category.title} has missing migration fields', label: _label);
      }
    }

    final verification = MigrationVerification(
      totalCategories: categories.length,
      withSource: withSource,
      withBuiltInId: withBuiltInId,
      withModifiedFlag: withModifiedFlag,
      withDeletedFlag: withDeletedFlag,
      missingFields: missingFields,
    );

    if (verification.isComplete) {
      Log.i('✅ Migration verification passed!', label: _label);
    } else {
      Log.w('⚠️  Migration incomplete: $verification', label: _label);
    }

    return verification;
  }
}

/// Result of migration operation
class MigrationResult {
  final int totalCategories;
  final int updated;
  final int skipped;
  final int errors;

  MigrationResult({
    required this.totalCategories,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  bool get isSuccess => errors == 0;
  int get processed => updated + skipped;

  @override
  String toString() {
    return 'MigrationResult(total: $totalCategories, updated: $updated, skipped: $skipped, errors: $errors)';
  }
}

/// Verification results
class MigrationVerification {
  final int totalCategories;
  final int withSource;
  final int withBuiltInId;
  final int withModifiedFlag;
  final int withDeletedFlag;
  final int missingFields;

  MigrationVerification({
    required this.totalCategories,
    required this.withSource,
    required this.withBuiltInId,
    required this.withModifiedFlag,
    required this.withDeletedFlag,
    required this.missingFields,
  });

  bool get isComplete => missingFields == 0 && totalCategories > 0;

  @override
  String toString() {
    return 'MigrationVerification(total: $totalCategories, '
           'source: $withSource, builtInId: $withBuiltInId, '
           'modified: $withModifiedFlag, deleted: $withDeletedFlag, '
           'missing: $missingFields)';
  }
}

/// Built-in category template for matching
class BuiltInCategoryTemplate {
  final String? builtInId;
  final String name;
  final String icon;
  final String iconBackground;
  final String transactionType;

  BuiltInCategoryTemplate({
    required this.builtInId,
    required this.name,
    required this.icon,
    required this.iconBackground,
    required this.transactionType,
  });

  factory BuiltInCategoryTemplate.empty() {
    return BuiltInCategoryTemplate(
      builtInId: null,
      name: '',
      icon: '',
      iconBackground: '',
      transactionType: 'expense',
    );
  }
}
