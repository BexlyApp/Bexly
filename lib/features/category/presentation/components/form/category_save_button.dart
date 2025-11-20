part of '../../screens/category_form_screen.dart';

class CategorySaveButton extends ConsumerWidget {
  const CategorySaveButton({
    super.key,
    required this.categoryId,
    required this.titleController,
    required this.descriptionController,
    required this.makeAsParent,
    required this.selectedParentCategory,
    required this.icon,
    required this.iconType,
    required this.iconBackground,
    required this.isEditingParent,
    required this.transactionType,
  });

  final int? categoryId;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ValueNotifier<bool> makeAsParent;
  final CategoryModel? selectedParentCategory;
  final ValueNotifier<String> icon;
  final ValueNotifier<IconType> iconType;
  final ValueNotifier<String> iconBackground;
  final bool isEditingParent;
  final ValueNotifier<String> transactionType;

  @override
  Widget build(BuildContext context, ref) {
    return PrimaryButton(
      label: 'Save',
      state: ButtonState.active,
      onPressed: () async {
        final newCategory = CategoryModel(
          id: categoryId,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          parentId: makeAsParent.value ? null : selectedParentCategory?.id,
          icon: icon.value,
          iconTypeValue: iconType.value.name,
          iconBackground: iconBackground.value,
          transactionType: transactionType.value,
        );

        CategoryFormService().save(context, ref, newCategory);
      },
    );
  }
}
