import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

/// Bottom sheet explaining SMS permission and privacy
class SmsPermissionBottomSheet extends StatelessWidget {
  const SmsPermissionBottomSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmsPermissionBottomSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMessage01,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.spacing20),

              // Title
              Text(
                context.l10n.autoTransactionSmsTitle,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing16),

              // Description
              Text(
                'Bexly needs access to your SMS messages to automatically detect banking transactions and help you track your finances.',
                style: AppTextStyles.body3.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Privacy features
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedBank,
                title: 'Bank Messages Only',
                description: 'We only read messages from recognized banks',
              ),

              const SizedBox(height: AppSpacing.spacing12),

              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedSmartPhone01,
                title: 'Processed Locally',
                description: 'All SMS data stays on your device',
              ),

              const SizedBox(height: AppSpacing.spacing12),

              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedSecurityLock,
                title: 'Never Shared',
                description: 'Your messages are never sent to any server',
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required List<List> icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.spacing8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.body4.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet explaining Notification permission and privacy
class NotificationPermissionBottomSheet extends StatelessWidget {
  const NotificationPermissionBottomSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPermissionBottomSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.spacing20),

              // Title
              Text(
                context.l10n.autoTransactionNotificationTitle,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing16),

              // Description
              Text(
                'Bexly can listen to push notifications from banking apps to automatically track your transactions in real-time.',
                style: AppTextStyles.body3.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Privacy features
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedBank,
                title: 'Banking Apps Only',
                description: 'We only read notifications from recognized financial apps',
              ),

              const SizedBox(height: AppSpacing.spacing12),

              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedSmartPhone01,
                title: 'Processed Locally',
                description: 'All notification data stays on your device',
              ),

              const SizedBox(height: AppSpacing.spacing12),

              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedSecurityLock,
                title: 'Full Control',
                description: 'Disable anytime from Settings',
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required List<List> icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.spacing8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.body4.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
