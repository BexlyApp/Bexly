import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/utils/logger.dart';

/// Key for storing privacy consent in SharedPreferences
const String kPrivacyConsentKey = 'hasAcceptedPrivacy';
const String kPrivacyConsentDateKey = 'privacyConsentDate';

/// Privacy consent bottom sheet for GDPR/CCPA compliance
class PrivacyConsentBottomSheet extends StatelessWidget {
  final VoidCallback onAccept;

  const PrivacyConsentBottomSheet({
    super.key,
    required this.onAccept,
  });

  /// Check if user has already accepted privacy policy
  static Future<bool> hasAcceptedPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kPrivacyConsentKey) ?? false;
  }

  /// Save privacy consent
  static Future<void> saveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrivacyConsentKey, true);
    await prefs.setString(kPrivacyConsentDateKey, DateTime.now().toIso8601String());
    Log.i('Privacy consent saved', label: 'PrivacyConsent');
  }

  /// Open Privacy Policy URL
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://bexly.app/privacy');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Log.e('Failed to open Privacy Policy: $e', label: 'PrivacyConsent');
    }
  }

  /// Open Terms of Service URL
  Future<void> _openTermsOfService() async {
    final uri = Uri.parse('https://bexly.app/terms');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Log.e('Failed to open Terms of Service: $e', label: 'PrivacyConsent');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing24,
        AppSpacing.spacing16,
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
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const Gap(AppSpacing.spacing16),
              Expanded(
                child: Text(
                  'Your Privacy Matters',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing24),

          // Description
          Text(
            'We collect and process your data to provide you with the best experience:',
            style: AppTextStyles.body1,
          ),
          const Gap(AppSpacing.spacing16),

          // Data usage items
          _DataUsageItem(
            icon: HugeIcons.strokeRoundedAnalytics01,
            title: 'Analytics',
            description: 'To improve app performance and features',
          ),
          const Gap(AppSpacing.spacing12),
          _DataUsageItem(
            icon: HugeIcons.strokeRoundedCloudUpload,
            title: 'Cloud Sync',
            description: 'To sync your data across devices',
          ),
          const Gap(AppSpacing.spacing12),
          _DataUsageItem(
            icon: HugeIcons.strokeRoundedBug01,
            title: 'Crash Reports',
            description: 'To fix bugs and improve stability',
          ),
          const Gap(AppSpacing.spacing24),

          // Privacy links
          RichText(
            text: TextSpan(
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Terms of Service',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _openTermsOfService,
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const Gap(AppSpacing.spacing32),

          // Accept button
          PrimaryButton(
            label: 'Agree & Continue',
            onPressed: () async {
              await saveConsent();
              onAccept();
            },
          ),
        ],
      ),
    );
  }
}

class _DataUsageItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String description;

  const _DataUsageItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(
          icon: icon,
          color: AppColors.neutral500,
          size: 20,
        ),
        const Gap(AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.body3.copyWith(
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
