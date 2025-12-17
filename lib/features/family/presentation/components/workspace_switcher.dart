import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/family/domain/enums/workspace_type.dart';
import 'package:bexly/features/family/presentation/riverpod/workspace_provider.dart';
import 'package:bexly/features/family/presentation/riverpod/family_providers.dart';

/// A tab bar widget to switch between Personal and Family workspaces
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorkspace = ref.watch(currentWorkspaceProvider);
    final hasFamily = ref.watch(hasActiveFamilyProvider);

    // Don't show switcher if user doesn't have a family
    if (!hasFamily) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.purpleBorderLighter),
      ),
      child: Row(
        children: [
          Expanded(
            child: _WorkspaceTab(
              label: 'Personal',
              icon: Icons.person_outline,
              isSelected: currentWorkspace == WorkspaceType.personal,
              onTap: () => ref
                  .read(currentWorkspaceProvider.notifier)
                  .setWorkspace(WorkspaceType.personal),
            ),
          ),
          Expanded(
            child: _WorkspaceTab(
              label: 'Family',
              icon: Icons.family_restroom_outlined,
              isSelected: currentWorkspace == WorkspaceType.family,
              onTap: () => ref
                  .read(currentWorkspaceProvider.notifier)
                  .setWorkspace(WorkspaceType.family),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkspaceTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.spacing8,
          horizontal: AppSpacing.spacing12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.neutral500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body4.copyWith(
                color: isSelected ? Colors.white : AppColors.neutral500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
