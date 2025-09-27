import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/circle_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';

class MobileBottomAppBar extends ConsumerWidget {
  final PageController pageController;
  const MobileBottomAppBar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageControllerProvider);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: currentIndex == 0 || currentIndex == 1 || currentIndex == 2 || currentIndex == 3
            ? (currentIndex > 1 ? currentIndex + 1 : currentIndex)
            : 0,
        onTap: (index) {
          if (index == 2) {
            // Add button - show menu
            showModalBottomSheet(
              context: context,
              builder: (context) => const TransactionOptionsMenu(),
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
            );
          } else {
            // Navigate to page (adjust index for add button)
            final pageIndex = index > 2 ? index - 1 : index;
            pageController.jumpToPage(pageIndex);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedHome01),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedAiChat01),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                HugeIcons.strokeRoundedPlusSign,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedReceiptDollar),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedTarget02),
            label: 'Planning',
          ),
        ],
      ),
    );
  }
}
