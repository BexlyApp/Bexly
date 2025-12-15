import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bexly/features/main/presentation/components/custom_bottom_app_bar.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_screen.dart';
import 'package:bexly/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:bexly/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:bexly/features/planning/presentation/screens/planning_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // PageController must be created once and reused to prevent rebuilding pages
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(pageControllerProvider);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(pageControllerProvider);

    // Sync PageController with provider state (when changed externally)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _pageController.page?.round() != currentPage) {
        _pageController.jumpToPage(currentPage);
      }
    });

    final Widget pageViewWidget = PageView(
      controller: _pageController,
      onPageChanged: (value) {
        ref.read(pageControllerProvider.notifier).setPage(value);
      },
      children: const [
        DashboardScreen(),    // Page 0: Home
        TransactionScreen(),  // Page 1: Transactions
        PlanningScreen(),     // Page 2: Goals
        RecurringScreen(),    // Page 3: Budgets
        AIChatScreen(),       // Page 4: AI Chat (accessed via mobile bottom bar)
      ],
    );

    final Widget navigationControls = CustomBottomAppBar(
      pageController: _pageController,
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
            : Stack(
                children: [
                  // Page content - add bottom padding for nav bar
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: pageViewWidget,
                    ),
                  ),
                  // Liquid glass bottom navigation bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: navigationControls,
                  ),
                ],
              ),
      ),
    );
  }
}
