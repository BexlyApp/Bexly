import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';
import 'package:bexly/features/planning/presentation/riverpod/planning_tab_provider.dart';

class DesktopSidebar extends ConsumerWidget {
  static const double desktopSidebarWidth = 220.0; // Increased width for text
  final PageController pageController;
  const DesktopSidebar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: desktopSidebarWidth, // Uses the updated width
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.spacing16,
        // horizontal: AppSpacing.spacing8, // ListTile will handle its own padding
      ),
      decoration: const BoxDecoration(color: AppColors.dark),
      child: Column(
        // Using ListView for scrollability if items exceed height
        // mainAxisAlignment: MainAxisAlignment.start, // Align items to the top
        // crossAxisAlignment: CrossAxisAlignment.stretch, // Make ListTiles fill width
        children: <Widget>[
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'Home',
            icon: HugeIcons.strokeRoundedHome01,
            pageIndex: 0,
            onTap: () => pageController.jumpToPage(0),
          ),
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'AI Chat',
            icon: HugeIcons.strokeRoundedAiChat01,
            pageIndex: 1,
            onTap: () => pageController.jumpToPage(1),
          ),
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'History',
            icon: HugeIcons.strokeRoundedReceiptDollar,
            pageIndex: 2,
            onTap: () => pageController.jumpToPage(2),
          ),
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'Recurring',
            icon: Icons.repeat,
            pageIndex: 3,
            onTap: () => pageController.jumpToPage(3),
          ),
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'Goals',
            icon: HugeIcons.strokeRoundedTarget01,
            pageIndex: 4,
            onTap: () {
              // Set planning tab to Goals (index 1) before navigating
              ref.read(planningTabProvider.notifier).setTab(1);
              pageController.jumpToPage(4);
            },
          ),
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'Budgets',
            icon: HugeIcons.strokeRoundedDatabase,
            pageIndex: 4,
            onTap: () {
              // Set planning tab to Budgets (index 0) before navigating
              ref.read(planningTabProvider.notifier).setTab(0);
              pageController.jumpToPage(4);
            },
          ),
          const Spacer(),
          // Settings button at bottom
          _buildSidebarItem(
            context: context,
            ref: ref,
            title: 'Settings',
            icon: HugeIcons.strokeRoundedSettings02,
            onTap: () => context.push(Routes.settings),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          // FAB-style button - opens action menu popup
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
              vertical: AppSpacing.spacing8,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TransactionOptionsMenu(),
                  );
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'New Transaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radius12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required dynamic icon, // Support both IconData and List<List> (HugeIcons)
    required VoidCallback onTap,
    int? pageIndex,
    bool isSpecialAction = false,
  }) {
    final Color itemColor = isSpecialAction
        ? AppColors.primary
        : ref
              .read(pageControllerProvider.notifier)
              .getIconColor(pageIndex ?? -1);

    return ListTile(
      leading: icon is IconData
          ? Icon(icon, color: itemColor, size: 26)
          : HugeIcon(icon: icon, color: itemColor, size: 26),
      title: Text(
        title,
        style: AppTextStyles.body2.copyWith(
          color: itemColor,
          fontWeight:
              (pageIndex != null &&
                      ref.watch(pageControllerProvider) == pageIndex) ||
                  isSpecialAction
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing20,
        vertical: AppSpacing.spacing4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
      ),
      hoverColor: AppColors.light.withAlpha(10),
      selected:
          pageIndex != null && ref.watch(pageControllerProvider) == pageIndex,
      selectedTileColor: AppColors.primary.withAlpha(
        15,
      ), // Subtle selection indication
    );
  }
}
