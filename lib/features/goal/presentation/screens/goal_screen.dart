import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/features/goal/presentation/components/goal_card.dart';
import 'package:bexly/features/goal/presentation/riverpod/goals_list_provider.dart';
import 'package:bexly/features/goal/presentation/screens/goal_form_dialog.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncGoals = ref.watch(goalsListProvider);

    return Scaffold(
      // Hide FAB on desktop - use sidebar button instead
      floatingActionButton: context.isDesktopLayout
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.openBottomSheet(child: GoalFormDialog());
              },
              child: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
            ),
      body: asyncGoals.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(child: Text(l10n.noGoalsAddOne));
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
