import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class TransactionTabBar extends HookConsumerWidget {
  final int pendingCount;

  const TransactionTabBar({
    super.key,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context, ref) {
    // Fixed 3 tabs: This Month, Last Month, Pending
    final thisMonthTab = Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar03,
            size: 18,
            color: AppColors.primary600,
          ),
          const SizedBox(width: 6),
          Text(context.l10n.thisMonth),
        ],
      ),
    );

    final lastMonthTab = Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCalendar03,
            size: 18,
            color: AppColors.primary600,
          ),
          const SizedBox(width: 6),
          Text(context.l10n.lastMonth),
        ],
      ),
    );

    final pendingTab = Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInbox,
            size: 18,
            color: AppColors.primary600,
          ),
          const SizedBox(width: 6),
          const Text('Pending'),
          if (pendingCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pendingCount > 99 ? '99+' : pendingCount.toString(),
                style: AppTextStyles.body5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );

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
        isScrollable: false, // 3 fixed tabs, no need to scroll
        tabs: [thisMonthTab, lastMonthTab, pendingTab],
      ),
    );
  }
}
