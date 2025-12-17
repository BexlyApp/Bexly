import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/services/keyboard_service/virtual_keyboard_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/goal/data/model/checklist_item_model.dart';
import 'package:bexly/features/goal/presentation/services/goal_form_service.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class GoalChecklistFormDialog extends HookConsumerWidget {
  final int goalId;
  final ChecklistItemModel? checklistItemModel;
  const GoalChecklistFormDialog({
    super.key,
    required this.goalId,
    this.checklistItemModel,
  });

  @override
  Widget build(BuildContext context, ref) {
    final wallet = ref.watch(activeWalletProvider);
    final defaultCurrency = wallet.value?.currencyByIsoCode(ref).symbol;
    final titleController = useTextEditingController();
    final amountController = useTextEditingController();
    final linkController = useTextEditingController();
    bool completed = false;
    bool isEditing = checklistItemModel != null;

    useEffect(() {
      if (isEditing) {
        titleController.text = checklistItemModel!.title;
        final amount = checklistItemModel!.amount;
        if (amount > 0) {
          amountController.text =
              '${defaultCurrency ?? ''} ${amount.toPriceFormat()}'.trim();
        }
        linkController.text = checklistItemModel!.link;
        completed = checklistItemModel!.completed;
      }
      return null;
    }, const []);

    return CustomBottomSheet(
      title: '${isEditing ? 'Edit' : 'Add'} Checklist Item',
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.spacing16,
          children: [
            CustomTextField(
              controller: titleController,
              label: 'Title (max. 25)',
              hint: 'Buy something',
              isRequired: true,
              prefixIcon: HugeIcons.strokeRoundedShirt01 as dynamic,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              maxLength: 25,
              customCounterText: '',
            ),
            CustomNumericField(
              controller: amountController,
              label: 'Price amount',
              hint: '1,000.00',
              icon: HugeIcons.strokeRoundedMoney03 as dynamic,
              appendCurrencySymbolToHint: true,
              isRequired: true,
            ),
            CustomTextField(
              controller: linkController,
              label: 'Offline store or link to buy',
              hint: 'Insert or paste link here...',
              maxLength: 1000,
              customCounterText: '',
              prefixIcon: HugeIcons.strokeRoundedLink01 as dynamic,
              suffixIcon: HugeIcons.strokeRoundedClipboard as dynamic,
              onTapSuffixIcon: () =>
                  KeyboardService.pasteFromClipboard(linkController),
            ),
            PrimaryButton(
              label: 'Save',
              state: ButtonState.active,
              onPressed: () async {
                Log.d(titleController.text, label: 'title');
                Log.d(
                  amountController.text.takeNumericAsDouble(),
                  label: 'amount',
                );
                Log.d(linkController.text, label: 'link');

                final newItem = ChecklistItemModel(
                  id: checklistItemModel?.id,
                  goalId: goalId,
                  title: titleController.text,
                  amount: amountController.text.takeNumericAsDouble(),
                  link: linkController.text,
                  completed: completed,
                );

                // return;
                GoalFormService().saveChecklist(
                  context,
                  ref,
                  checklistItem: newItem,
                );
              },
            ),
            if (isEditing)
              TextButton(
                child: Text(
                  context.l10n.delete,
                  style: AppTextStyles.body2.copyWith(color: AppColors.red),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (dialogContext) => AlertBottomSheet(
                      context: context,
                      title: context.l10n.deleteChecklist,
                      content: Text(
                        context.l10n.confirmDelete,
                        style: AppTextStyles.body2,
                      ),
                      confirmText: context.l10n.delete,
                      onConfirm: () {
                        GoalFormService().deleteChecklist(
                          context,
                          ref,
                          checklistItem: checklistItemModel!,
                        );
                        context.pop(); // close this dialog
                        context.pop(); // close edit dialog
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
