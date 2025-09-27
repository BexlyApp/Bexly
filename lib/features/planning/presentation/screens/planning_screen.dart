import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/budget/presentation/screens/budget_screen.dart';
import 'package:bexly/features/goal/presentation/screens/goal_screen.dart';

class PlanningScreen extends HookConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    final currentTab = useState(0);

    useEffect(() {
      void listener() {
        currentTab.value = tabController.index;
      }
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Planning'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: AppColors.primary600,
          labelColor: AppColors.primary600,
          unselectedLabelColor: AppColors.neutral600,
          labelStyle: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              text: 'Budget',
              icon: Icon(Icons.account_balance_wallet),
            ),
            Tab(
              text: 'Goals',
              icon: Icon(Icons.flag),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          // Budget tab - hiển thị BudgetScreen
          BudgetScreen(),

          // Goals tab - hiển thị GoalScreen
          GoalScreen(),
        ],
      ),
    );
  }
}