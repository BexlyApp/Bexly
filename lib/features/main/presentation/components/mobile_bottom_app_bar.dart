import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';

class MobileBottomAppBar extends ConsumerWidget {
  final PageController pageController;
  const MobileBottomAppBar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDarkMode
        ? AppColors.darkGrey.withAlpha(180)
        : AppColors.light.withAlpha(200);

    final Color borderColor = isDarkMode
        ? Colors.white.withAlpha(30)
        : Colors.grey.shade300;

    final Color activeColor = AppColors.primary;
    final Color inactiveColor = isDarkMode
        ? Colors.white.withAlpha(150)
        : Colors.grey.shade600;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.only(
            top: AppSpacing.spacing8,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.spacing8,
            left: AppSpacing.spacing8,
            right: AppSpacing.spacing8,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: HugeIcons.strokeRoundedHome01,
                label: l10n.home,
                isActive: currentIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => pageController.jumpToPage(0),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedReceiptDollar,
                label: l10n.history,
                isActive: currentIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => pageController.jumpToPage(1),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedTarget02,
                label: l10n.planning,
                isActive: currentIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => pageController.jumpToPage(2),
              ),
              _NavItem(
                icon: Icons.repeat,
                label: l10n.recurring,
                isActive: currentIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => pageController.jumpToPage(3),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedAiChat01,
                label: l10n.aiChat,
                isActive: currentIndex == 4,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => pageController.jumpToPage(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final dynamic icon; // Support both IconData and List<List> (HugeIcons)
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon is IconData
                ? Icon(icon, color: color, size: 24)
                : HugeIcon(icon: icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
