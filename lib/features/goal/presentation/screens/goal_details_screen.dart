// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';

import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';
import 'package:bexly/features/goal/presentation/components/goal_checklist_holder.dart';
import 'package:bexly/features/goal/presentation/components/goal_title_card.dart';
import 'package:bexly/features/goal/presentation/riverpod/checklist_items_provider.dart';
import 'package:bexly/features/goal/presentation/riverpod/date_picker_provider.dart';
import 'package:bexly/features/goal/presentation/riverpod/goal_details_provider.dart';
import 'package:bexly/features/goal/presentation/screens/goal_checklist_form_dialog.dart';
import 'package:bexly/features/goal/presentation/screens/goal_form_dialog.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:toastification/toastification.dart';

class GoalDetailsScreen extends ConsumerWidget {
  final int goalId;
  const GoalDetailsScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, ref) {
    final wallet = ref.watch(activeWalletProvider);
    final goalAsync = ref.watch(goalDetailsProvider(goalId));
    final checklistItemsAsync = ref.watch(checklistItemsProvider(goalId));

    return CustomScaffold(
      context: context,
      title: 'My Goals',
      showBalance: false,
      actions: [
        if (goalAsync.value != null)
          CustomIconButton(
            context,
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final goal = goalAsync.value!;
              if (goal.pinned) {
                await db.goalDao.unpinGoal(goalId);
              } else {
                await db.goalDao.pinGoal(goalId);
              }
              Toast.show(
                'Goal ${goal.pinned ? 'unpinned' : 'pinned'}',
                type: ToastificationType.success,
              );
            },
            icon: goalAsync.value!.pinned
                ? HugeIcons.strokeRoundedPinOff as dynamic
                : HugeIcons.strokeRoundedPin as dynamic,
            active: goalAsync.value!.pinned,
            themeMode: context.themeMode,
          ),
        Gap(AppSpacing.spacing8),
        CustomIconButton(
          context,
          onPressed: () {
            if (goalAsync.value != null) {
              ref.read(datePickerProvider.notifier).state =
                  goalAsync.value!.goalDates;

              context.openBottomSheet(
                child: GoalFormDialog(goal: goalAsync.value!),
              );
            }
          },
          icon: HugeIcons.strokeRoundedEdit02 as dynamic,
          themeMode: context.themeMode,
        ),
        Gap(AppSpacing.spacing8),
        if (goalAsync.value != null)
          CustomIconButton(
            context,
            onPressed: () {
              context.openBottomSheet(
                child: AlertBottomSheet(
                  context: context,
                  title: context.l10n.deleteGoal,
                  content: Text(
                    context.l10n.deleteGoalConfirm,
                    style: AppTextStyles.body2,
                  ),
                  confirmText: context.l10n.delete,
                  onConfirm: () {
                    final db = ref.read(databaseProvider);
                    db.goalDao.deleteGoal(goalId);
                    context.pop();
                    context.pop();
                  },
                ),
              );
            },
            icon: HugeIcons.strokeRoundedDelete02 as dynamic,
            themeMode: context.themeMode,
          ),
      ],
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing20,
              AppSpacing.spacing20,
              AppSpacing.spacing20,
              150,
            ),
            child: goalAsync.when(
              data: (GoalModel goal) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GoalTitleCard(goal: goal),
                    GoalChecklistHolder(goalId: goalId),
                  ],
                );
              },
              error: (Object error, StackTrace stackTrace) {
                return Center(child: Text('Error: $error'));
              },
              loading: () {
                return Center(child: LoadingIndicator());
              },
            ),
          ),
          PrimaryButton(
            label: 'Add Checklist Item',
            state: ButtonState.outlinedActive,
            themeMode: context.themeMode,
            onPressed: () {
              print('➕  Opening checklist dialog for goalId=$goalId');
              context.openBottomSheet(
                child: GoalChecklistFormDialog(goalId: goalId),
              );
            },
          ).floatingBottomWithContent(
            content: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.body2),
                  checklistItemsAsync.when(
                    data: (items) {
                      final total = items.fold<double>(
                        0.0,
                        (sum, item) => sum + item.amount,
                      );
                      return Text(
                        '${wallet.value?.currencyByIsoCode(ref).symbol} ${total.toPriceFormat()}',
                        style: AppTextStyles.numericLarge,
                      );
                    },
                    error: (e, _) => Container(),
                    loading: () => Container(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
