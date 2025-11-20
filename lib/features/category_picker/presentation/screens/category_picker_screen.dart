import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/buttons/button_chip.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/features/category/presentation/riverpod/category_providers.dart';
import 'package:bexly/features/category/presentation/screens/category_form_screen.dart';
import 'package:bexly/features/category_picker/presentation/components/category_dropdown.dart';

class CategoryPickerScreen extends HookConsumerWidget {
  final bool isManageCategories;
  final bool isPickingParent;
  final String? initialTransactionType; // Initial transaction type to display
  const CategoryPickerScreen({
    super.key,
    this.isManageCategories = false,
    this.isPickingParent = false,
    this.initialTransactionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track selected transaction type (expense or income)
    // Initialize from parameter, or detect from selected category, or default to 'expense'
    final selectedParentCategory = ref.watch(selectedParentCategoryProvider);
    final initialType = initialTransactionType ??
                        selectedParentCategory?.transactionType ??
                        'expense';
    final selectedType = useState(initialType);

    // Update selectedType when selectedParentCategory changes
    useEffect(() {
      if (selectedParentCategory != null && !isManageCategories) {
        selectedType.value = selectedParentCategory.transactionType;
      }
      return null;
    }, [selectedParentCategory]);

    // Only show tab selector in Manage Categories mode
    final showTabSelector = isManageCategories;

    return CustomScaffold(
      context: context,
      title: isManageCategories ? 'Manage Categories' : 'Picking Category',
      showBalance: false,
      body: Column(
        children: [
          // Tab selector for Income/Expense (only in Manage Categories mode)
          if (showTabSelector)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing20,
                AppSpacing.spacing0,
                AppSpacing.spacing20,
                AppSpacing.spacing12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ButtonChip(
                      label: 'Expense',
                      active: selectedType.value == 'expense',
                      onTap: () {
                        selectedType.value = 'expense';
                      },
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),
                  Expanded(
                    child: ButtonChip(
                      label: 'Income',
                      active: selectedType.value == 'income',
                      onTap: () {
                        selectedType.value = 'income';
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ref
                .watch(hierarchicalCategoriesProvider)
                .when(
                  data: (categories) {
                    // Filter categories by selected transaction type
                    final filteredCategories = categories
                        .where((cat) => cat.transactionType == selectedType.value)
                        .toList();

                    if (filteredCategories.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.spacing20),
                          child: Text(
                            'No ${selectedType.value} categories found. Add one!',
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.spacing20,
                        0,
                        AppSpacing.spacing20,
                        150,
                      ),
                      shrinkWrap: true,
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) => CategoryDropdown(
                        category: filteredCategories[index],
                        isManageCategory: isManageCategories,
                      ),
                      separatorBuilder: (context, index) =>
                          const Gap(AppSpacing.spacing12),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Error loading categories: $error')),
                ),
          ),
          if (!isPickingParent)
            PrimaryButton(
              label: 'Add New Category',
              state: ButtonState.outlinedActive,
              onPressed: () {
                ref.read(selectedParentCategoryProvider.notifier).state = null;
                // Pass the selected transaction type to the form
                context.openBottomSheet(
                  child: CategoryFormScreen(
                    initialTransactionType: selectedType.value,
                  ),
                );
              },
            ).contained,
        ],
      ),
    );
  }
}
