import 'package:flutter/material.dart';
import 'package:bexly/features/gamification/utils/xp_calculator.dart';

/// Small tappable chip showing current level: "✦ Lv.5"
/// Used in the dashboard header next to the user's name.
class LevelBadgeWidget extends StatelessWidget {
  const LevelBadgeWidget({
    super.key,
    required this.totalXp,
    this.onTap,
  });

  final int totalXp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lvl = levelFromXp(totalXp);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'Lv.${lvl.level}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
