import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bexly/features/main/presentation/components/custom_bottom_app_bar.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_screen.dart';
import 'package:bexly/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:bexly/features/planning/presentation/screens/planning_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final currentPage = ref.watch(pageControllerProvider);
    // It's generally recommended to create PageController outside build or use usePageController hook if stateful,
    // but for this structure, ensure it's stable or managed by a provider if complex interactions are needed.
    // For this specific case where it's driven by Riverpod's currentPage, it's acceptable.
    final pageController = PageController(initialPage: currentPage);

    final Widget pageViewWidget = PageView(
      controller: pageController,
      onPageChanged: (value) {
        ref.read(pageControllerProvider.notifier).setPage(value);
      },
      children: const [
        DashboardScreen(),
        AIChatScreen(),
        TransactionScreen(),
        PlanningScreen(),
      ],
    );

    final Widget navigationControls = CustomBottomAppBar(
      pageController: pageController,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Material(
        child: context.isDesktopLayout
            ? Row(
                children: [
                  navigationControls, // This will render as a sidebar
                  Expanded(child: pageViewWidget),
                ],
              )
            : Column(
                children: [
                  Expanded(child: pageViewWidget),
                  navigationControls,
                ],
              ),
      ),
    );
  }
}
