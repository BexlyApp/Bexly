import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';
import 'package:bexly/features/goal/presentation/riverpod/date_picker_provider.dart';
import 'package:bexly/features/goal/presentation/components/goal_date_range_picker.dart';
import 'package:bexly/features/goal/presentation/services/goal_form_service.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart'; // for Value

class GoalFormDialog extends HookConsumerWidget {
  final GoalModel? goal;
  const GoalFormDialog({super.key, this.goal});

  @override
  Widget build(BuildContext context, ref) {
    final wallet = ref.read(activeWalletProvider);
    final defaultCurrency = wallet.value?.currencyByIsoCode(ref).symbol;
    final dateRange = ref.watch(datePickerProvider);
    final titleController = useTextEditingController();
    final noteController = useTextEditingController();
    final targetAmountController = useTextEditingController();

    final isEditing = goal != null;

    useEffect(() {
      if (isEditing) {
        titleController.text = goal!.title;
        noteController.text = goal!.description ?? '';
        targetAmountController.text =
            '$defaultCurrency ${goal!.targetAmount.toPriceFormat()}';
      }

      return null;
    }, const []);

    return CustomBottomSheet(
      title: '${isEditing ? 'Edit' : 'New'} Goal',
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
              prefixIcon: HugeIcons.strokeRoundedArrangeByLettersAZ as dynamic,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              maxLength: 25,
              customCounterText: '',
            ),
            GoalDateRangePicker(initialDate: dateRange),
            CustomTextField(
              controller: noteController,
              label: 'Write a note',
              hint: 'Write here...',
              prefixIcon: HugeIcons.strokeRoundedNote as dynamic,
              minLines: 1,
              maxLines: 3,
              maxLength: 250,
            ),
            /* CustomNumericField(
              controller: targetAmountController,
              label: 'Target amount',
              hint: '1,500',
              icon: HugeIcons.strokeRoundedCoins01,
              isRequired: true,
              appendCurrencySymbolToHint: true,
            ), */
            PrimaryButton(
              label: 'Save',
              state: ButtonState.active,
              themeMode: context.themeMode,
              onPressed: () async {
                final currentDateRange = ref.read(datePickerProvider);
                Log.d(titleController.text, label: 'title');
                Log.d(currentDateRange, label: 'selected date');
                Log.d(noteController.text, label: 'note');
                Log.d(targetAmountController.text, label: 'target');

                final newGoal = GoalModel(
                  id: goal?.id,
                  cloudId: goal?.cloudId,
                  title: titleController.text.trim(),
                  description: noteController.text.trim(),
                  targetAmount: targetAmountController.text
                      .takeNumericAsDouble(),
                  currentAmount: goal?.currentAmount ?? 0.0,
                  createdAt: goal?.createdAt ?? DateTime.now(),
                  startDate: currentDateRange.first,
                  endDate: currentDateRange.length > 1 &&
                          currentDateRange[1] != null
                      ? currentDateRange[1]!
                      : currentDateRange.first!,
                  iconName: goal?.iconName,
                  associatedAccountId: goal?.associatedAccountId,
                  pinned: goal?.pinned ?? false,
                  isDeleted: goal?.isDeleted ?? false,
                  deletedAt: goal?.deletedAt,
                );

                Log.d(newGoal.toJson(), label: 'new goal');

                await GoalFormService().save(context, ref, goal: newGoal);
              },
            ),
          ],
        ),
      ),
    );
  }
}
