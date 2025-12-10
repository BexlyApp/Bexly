import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/category_picker/presentation/components/category_icon.dart';

class CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final double? height;
  final double? iconSize;
  final dynamic suffixIcon; // Support both IconData and List<List> (HugeIcons)
  final GestureTapCallback? onSuffixIconPressed;
  final Function(CategoryModel)? onSelectCategory;
  final bool isSelected; // Whether this category is currently selected
  const CategoryTile({
    super.key,
    required this.category,
    this.onSuffixIconPressed,
    this.onSelectCategory,
    this.suffixIcon,
    this.height,
    this.iconSize = AppSpacing.spacing32,
    this.isSelected = false,
  });

  /// Get localized category name - use translation for default categories (ID <= 1005),
  /// show original title for custom user-created categories
  String _getLocalizedCategoryName(BuildContext context, CategoryModel category) {
    // Default categories have IDs in specific ranges (1-10 for main, 101-1005 for sub)
    if (category.id != null && category.id! <= 1005) {
      final localizedName = context.l10n.getCategoryName(category.id);
      // If localization returns "Unknown Category", fall back to original title
      if (localizedName != 'Unknown Category') {
        return localizedName;
      }
    }
    return category.title;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectCategory?.call(category),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.spacing8),
        decoration: BoxDecoration(
          color: context.purpleBackground,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          border: Border.all(color: context.purpleBorderLighter),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: context.purpleBackground,
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                border: Border.all(color: context.purpleBorderLighter),
              ),
              child: CategoryIcon(
                iconType: category.iconType,
                icon: category.icon,
                iconBackground: category.iconBackground,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            Expanded(
              child: Text(
                _getLocalizedCategoryName(context, category),
                style: AppTextStyles.body3,
              ),
            ),
            // Show checkmark if selected
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.green200,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (suffixIcon != null)
              CustomIconButton(
                context,
                onPressed: onSuffixIconPressed ?? () {},
                icon: suffixIcon!,
                iconSize: IconSize.small,
                visualDensity: VisualDensity.compact,
                backgroundColor: context.purpleBackground,
                borderColor: onSuffixIconPressed == null
                    ? Colors.transparent
                    : context.purpleBorderLighter,
                color: context.purpleText,
              ),
            const Gap(AppSpacing.spacing8),
          ],
        ),
      ),
    );
  }
}
