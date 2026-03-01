import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
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
        DashboardScreen(),  // Page 0: Home
        AIChatScreen(),     // Page 1: AI Chat
        RecurringScreen(),  // Page 2: Recurring
        PlanningScreen(),   // Page 3: Planning (Goals & Budgets)
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
                  navigationControls,
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
                  // Bottom navigation bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: navigationControls,
                  ),
                  // Right-side History button
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 80,
                    child: _HistoryRailButton(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HistoryRailButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionScreen()),
          );
        },
        child: Container(
          width: 28,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkGrey.withAlpha(220)
                : AppColors.light.withAlpha(240),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                width: 0.5,
              ),
              bottom: BorderSide(
                color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                width: 0.5,
              ),
              left: BorderSide(
                color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: RotatedBox(
            quarterTurns: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedReceiptDollar,
                  color: isDark ? Colors.white.withAlpha(160) : Colors.grey.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white.withAlpha(160) : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
