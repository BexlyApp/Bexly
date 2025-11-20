import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/budget/presentation/screens/budget_screen.dart';
import 'package:bexly/features/goal/presentation/screens/goal_form_dialog.dart';
import 'package:bexly/features/goal/presentation/screens/goal_screen.dart';

class PlanningScreen extends HookConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    final currentTab = useState(0);
    final l10n = AppLocalizations.of(context)!;

    useEffect(() {
      void listener() {
        currentTab.value = tabController.index;
      }
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      title: 'Planning',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to budget or goal form based on current tab
          if (currentTab.value == 0) {
            // Budget tab - navigate to budget form
            context.push(Routes.budgetForm);
          } else {
            // Goals tab - show goal form dialog
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const GoalFormDialog(),
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          HugeIcons.strokeRoundedPlusSign,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary600,
              indicatorWeight: 3,
              labelColor: AppColors.primary600,
              unselectedLabelColor: AppColors.neutral400,
              labelStyle: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  text: l10n.budget,
                  icon: const Icon(Icons.account_balance_wallet),
                ),
                Tab(
                  text: l10n.goals,
                  icon: const Icon(Icons.flag),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                // Budget tab - hiển thị BudgetScreen
                BudgetScreen(),

                // Goals tab - hiển thị GoalScreen
                GoalScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}