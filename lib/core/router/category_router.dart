import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/category/presentation/screens/category_icon_asset_picker.dart';
import 'package:bexly/features/category/presentation/screens/category_icon_emoji_picker.dart';
import 'package:bexly/features/category_picker/presentation/screens/category_picker_screen.dart';

class CategoryRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.categoryList,
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        final categoryIdStr = state.uri.queryParameters['categoryId'];
        final categoryId = categoryIdStr != null ? int.tryParse(categoryIdStr) : null;
        return CategoryPickerScreen(
          initialTransactionType: type,
          selectedCategoryId: categoryId,
        );
      },
    ),
    GoRoute(
      path: Routes.manageCategories,
      builder: (context, state) =>
          const CategoryPickerScreen(isManageCategories: true),
    ),
    GoRoute(
      path: Routes.categoryListPickingParent,
      builder: (context, state) =>
          const CategoryPickerScreen(isPickingParent: true),
    ),
    GoRoute(
      path: Routes.categoryIconAssetPicker,
      builder: (context, state) => const CategoryIconAssetPicker(),
    ),
    GoRoute(
      path: Routes.categoryIconEmojiPicker,
      builder: (context, state) => const CategoryIconEmojiPicker(),
    ),
    // GoRoute(
    //   path: Routes.categoryIconInitialPicker,
    //   builder: (context, state) => const CategoryIconAssetPicker(),
    // ),
  ];
}
