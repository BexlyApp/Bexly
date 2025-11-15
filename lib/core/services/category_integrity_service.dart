import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/repositories/category_repo.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';

/// Service to validate and repair category integrity
/// Runs on app startup to ensure built-in categories are not corrupted
class CategoryIntegrityService {
  /// Validates category integrity and auto-repairs if needed
  /// Returns true if integrity is valid or was successfully repaired
  static Future<bool> validateAndRepair(AppDatabase db) async {
    Log.i('🔍 Validating category integrity...', label: 'category_integrity');

    try {
      final allCategories = await db.categoryDao.getAllCategories();
      final builtInCategories = categories.getAllCategories();

      // Check 1: Verify all built-in categories exist
      final missingCategories = <int>[];
      for (final builtIn in builtInCategories) {
        final exists = allCategories.any((c) => c.id == builtIn.id);
        if (!exists) {
          missingCategories.add(builtIn.id!);
          Log.w('⚠️ Missing built-in category: ${builtIn.title} (ID: ${builtIn.id})', label: 'category_integrity');
        }
      }

      // Check 2: Verify built-in categories have correct subcategories count
      final corruptedCategories = <int>[];
      for (final builtIn in builtInCategories) {
        if (builtIn.subCategories == null || builtIn.subCategories!.isEmpty) {
          continue; // Skip parent categories without subcategories
        }

        final dbCategory = allCategories.firstWhere(
          (c) => c.id == builtIn.id,
          orElse: () => throw Exception('Category not found'),
        );

        // Get subcategories for this parent
        final subcategories = await db.categoryDao.getSubCategories(dbCategory.id);
        final expectedSubcategoriesCount = builtIn.subCategories!.length;

        if (subcategories.length != expectedSubcategoriesCount) {
          corruptedCategories.add(builtIn.id!);
          Log.w(
            '⚠️ Corrupted category: ${builtIn.title} (ID: ${builtIn.id}) - '
            'Expected $expectedSubcategoriesCount subcategories, found ${subcategories.length}',
            label: 'category_integrity',
          );
        }
      }

      // Check 3: Verify isSystemDefault flag is set correctly
      final incorrectFlags = <int>[];
      for (final builtIn in builtInCategories) {
        final dbCategory = allCategories.firstWhere(
          (c) => c.id == builtIn.id,
          orElse: () => throw Exception('Category not found'),
        );

        if (!dbCategory.isSystemDefault) {
          incorrectFlags.add(builtIn.id!);
          Log.w(
            '⚠️ Incorrect system flag: ${builtIn.title} (ID: ${builtIn.id}) - '
            'isSystemDefault should be true',
            label: 'category_integrity',
          );
        }
      }

      // If any issues found, trigger auto-repair
      if (missingCategories.isNotEmpty ||
          corruptedCategories.isNotEmpty ||
          incorrectFlags.isNotEmpty) {
        Log.w(
          '⚠️ Category integrity issues detected:\n'
          '  - Missing: ${missingCategories.length}\n'
          '  - Corrupted: ${corruptedCategories.length}\n'
          '  - Incorrect flags: ${incorrectFlags.length}',
          label: 'category_integrity',
        );

        // Auto-repair
        Log.i('🔧 AUTO-REPAIRING category database...', label: 'category_integrity');
        await CategoryPopulationService.repopulate(db);
        Log.i('✅ Category database repaired successfully', label: 'category_integrity');

        return true;
      }

      Log.i('✅ Category integrity validated - all OK!', label: 'category_integrity');
      return true;
    } catch (e, stack) {
      Log.e('❌ Category integrity validation failed: $e', label: 'category_integrity');
      Log.e('Stack: $stack', label: 'category_integrity');
      return false;
    }
  }
}
