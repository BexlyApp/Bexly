import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';

class TransactionTabBar extends HookConsumerWidget {
  final List<DateTime> monthsForTabs;

  const TransactionTabBar({super.key, required this.monthsForTabs});

  @override
  Widget build(BuildContext context, ref) {
    final now = DateTime.now();

    // Match recurring screen TabBar style exactly
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        indicatorColor: AppColors.primary600,
        indicatorWeight: 3,
        labelColor: AppColors.primary600,
        unselectedLabelColor: AppColors.neutral400,
        labelStyle: AppTextStyles.body3.copyWith(
          fontWeight: FontWeight.w600,
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        tabs: monthsForTabs
            .map((monthDate) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        size: 18,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: 6),
                      Text(monthDate.toMonthTabLabel(now)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
