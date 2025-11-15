import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';

class BudgetTabBar extends HookConsumerWidget {
  const BudgetTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 1);
    final budgetPeriods = ref.watch(budgetPeriodListProvider);
    final selectedPeriodNotifier = ref.read(
      selectedBudgetPeriodProvider.notifier,
    );

    // Update the selected period when the tab changes
    useEffect(() {
      void listener() {
        selectedPeriodNotifier.state = budgetPeriods[tabController.index];
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController, budgetPeriods, selectedPeriodNotifier]);

    return Container(
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
        isScrollable: true,
        tabs: budgetPeriods
            .map(
              (period) => Tab(text: period.toMonthTabLabel(period)),
            )
            .toList(),
      ),
    );
  }
}
