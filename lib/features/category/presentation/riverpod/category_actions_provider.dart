import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';

/// A simple grouping of your DB write methods
class CategoriesActions {
  final Future<Category> Function(CategoriesCompanion) add;
  final Future<bool> Function(Category) update;
  final Future<int> Function(int) delete;

  CategoriesActions({
    required this.add,
    required this.update,
    required this.delete,
  });
}

/// Expose your CRUD methods via Riverpod
/// IMPORTANT: Uses categoryDaoProvider (with Ref) to enable cloud sync!
final categoriesActionsProvider = Provider<CategoriesActions>((ref) {
  final categoryDao = ref.watch(categoryDaoProvider);
  return CategoriesActions(
    add: categoryDao.addCategory,
    update: categoryDao.updateCategory,
    delete: categoryDao.deleteCategoryById,
  );
});
