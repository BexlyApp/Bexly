import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/features/goal/presentation/components/goal_card.dart';
import 'package:bexly/features/goal/presentation/riverpod/goals_list_provider.dart';
import 'package:bexly/features/goal/presentation/screens/goal_form_dialog.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGoals = ref.watch(goalsListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.openBottomSheet(child: GoalFormDialog());
        },
        child: Icon(HugeIcons.strokeRoundedPlusSign),
      ),
      body: asyncGoals.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(child: Text('No goals. Add one!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            itemCount: goals.length,
            itemBuilder: (_, i) => GoalCard(goal: goals[i]),
            separatorBuilder: (_, _) => const Gap(AppSpacing.spacing12),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
