import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/constants/app_spacing.dart';

class AuthRequiredDialog extends StatelessWidget {
  final String featureName;
  final String description;

  const AuthRequiredDialog({
    super.key,
    required this.featureName,
    required this.description,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String featureName,
    required String description,
  }) async {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => AuthRequiredDialog(
        featureName: featureName,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomBottomSheet(
      title: 'Sign In Required',
      child: Column(
        spacing: AppSpacing.spacing20,
        children: [
          // Lock icon
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.primary,
          ),

          // Feature name
          Text(
            featureName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Description
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Sign in to sync your data across devices and enable cloud backup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(AppSpacing.spacing12),

          // Buttons
          Row(
            spacing: AppSpacing.spacing12,
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Cancel',
                  isOutlined: true,
                  state: ButtonState.outlinedActive,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              Expanded(
                child: PrimaryButton(
                  label: 'Sign In',
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.push('/login');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}