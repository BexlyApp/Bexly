import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/model/category_model.dart';

class TransactionCategorySelector extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(CategoryModel? parentCategory, CategoryModel? category)
  onCategorySelected;
  final String? currentTransactionType; // Current transaction type to pre-select tab

  const TransactionCategorySelector({
    super.key,
    required this.controller,
    required this.onCategorySelected,
    this.currentTransactionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomSelectField(
      context: context,
      controller: controller,
      label: 'Category',
      hint: 'Select Category',
      isRequired: true,
      onTap: () async {
        // Pass transaction type as query parameter if available
        final route = currentTransactionType != null
            ? '${Routes.categoryList}?type=$currentTransactionType'
            : Routes.categoryList;
        final category = await context.push<CategoryModel>(route);
        Log.d(category?.toJson(), label: 'category selected via text field');
        if (category != null) {
          final db = ref.read(databaseProvider);
          if (category.hasParent) {
            db.categoryDao.getCategoryById(category.parentId!).then((
              parentCat,
            ) {
              onCategorySelected.call(parentCat?.toModel(), category);
            });
          } else {
            onCategorySelected.call(null, category);
          }
        }
      },
    );
  }
}
