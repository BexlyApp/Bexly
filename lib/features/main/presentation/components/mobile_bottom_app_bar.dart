import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';

class MobileBottomAppBar extends ConsumerWidget {
  final PageController pageController;
  const MobileBottomAppBar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageControllerProvider);
    final l10n = AppLocalizations.of(context)!;

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
        currentIndex: currentIndex,
        onTap: (index) {
          pageController.jumpToPage(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedHome01),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedAiChat01),
            label: l10n.aiChat,
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedReceiptDollar),
            label: l10n.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Recurring',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedTarget02),
            label: l10n.planning,
          ),
        ],
      ),
    );
  }
}
