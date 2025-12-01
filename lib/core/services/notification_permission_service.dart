import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/utils/logger.dart';

/// Key for storing whether we've asked for notification permission
const String kHasAskedNotificationPermissionKey = 'hasAskedNotificationPermission';

/// Service to handle notification permission requests with contextual pre-explanation
class NotificationPermissionService {
  /// Check if notification permission is granted
  static Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if we've already asked for permission
  static Future<bool> hasAskedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kHasAskedNotificationPermissionKey) ?? false;
  }

  /// Mark that we've asked for permission
  static Future<void> markAskedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHasAskedNotificationPermissionKey, true);
  }

  /// Request notification permission
  /// Returns true if permission was granted
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    await markAskedForPermission();
    Log.i('Notification permission status: $status', label: 'NotificationPermission');
    return status.isGranted;
  }

  /// Show contextual permission dialog and request permission if user agrees
  /// Returns true if permission was granted
  static Future<bool> requestWithExplanation(BuildContext context) async {
    // Check if already granted
    if (await isPermissionGranted()) {
      return true;
    }

    // Check if we've already asked
    final hasAsked = await hasAskedForPermission();

    if (!context.mounted) return false;

    // Show explanation bottom sheet
    final shouldRequest = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NotificationPermissionExplanation(
        hasAskedBefore: hasAsked,
      ),
    );

    if (shouldRequest == true) {
      // User agreed, request permission
      return await requestPermission();
    }

    return false;
  }

  /// Open app settings for notification permission
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

/// Bottom sheet explaining why notification permission is needed
class _NotificationPermissionExplanation extends StatelessWidget {
  final bool hasAskedBefore;

  const _NotificationPermissionExplanation({
    required this.hasAskedBefore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing24,
        AppSpacing.spacing8,
        AppSpacing.spacing24,
        AppSpacing.spacing32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedNotification01,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const Gap(AppSpacing.spacing16),
              Expanded(
                child: Text(
                  'Never Miss a Payment',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing24),

          // Description
          Text(
            'Enable notifications to get reminded before your recurring payments are due.',
            style: AppTextStyles.body1,
          ),
          const Gap(AppSpacing.spacing16),

          // Benefits list
          _BenefitItem(
            icon: HugeIcons.strokeRoundedAlarmClock,
            text: 'Get reminders before due dates',
          ),
          const Gap(AppSpacing.spacing12),
          _BenefitItem(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            text: 'Stay on top of your bills',
          ),
          const Gap(AppSpacing.spacing12),
          _BenefitItem(
            icon: HugeIcons.strokeRoundedShield01,
            text: 'Avoid late fees and penalties',
          ),
          const Gap(AppSpacing.spacing32),

          // Buttons
          PrimaryButton(
            label: hasAskedBefore ? 'Open Settings' : 'Enable Notifications',
            onPressed: () {
              if (hasAskedBefore) {
                // Previously denied, open settings
                NotificationPermissionService.openSettings();
                Navigator.of(context).pop(false);
              } else {
                // First time, request permission
                Navigator.of(context).pop(true);
              }
            },
          ),
          const Gap(AppSpacing.spacing12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Now',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const Gap(AppSpacing.spacing12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }
}
