import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';

class OnboardingSlide2 extends StatelessWidget {
  const OnboardingSlide2({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Gap(AppSpacing.spacing56), // Add top padding
          // Title
          const Text(
            'Powerful Features',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.spacing40),

          // Feature 1
          _FeatureItem(
            icon: HugeIcons.strokeRoundedWallet01 as dynamic,
            title: 'Multi-Wallet & Multi-Currency',
            description: 'Manage multiple wallets in different currencies',
          ),
          const Gap(AppSpacing.spacing24),

          // Feature 2
          _FeatureItem(
            icon: HugeIcons.strokeRoundedAiChat01 as dynamic,
            title: 'AI Chat Assistant',
            description: 'Smart AI helps you track expenses naturally',
          ),
          const Gap(AppSpacing.spacing24),

          // Feature 3
          _FeatureItem(
            icon: HugeIcons.strokeRoundedTargetDollar as dynamic,
            title: 'Budgets & Goals',
            description: 'Set spending limits and savings goals',
          ),
          const Gap(AppSpacing.spacing24),

          // Feature 4
          _FeatureItem(
            icon: HugeIcons.strokeRoundedCloudUpload as dynamic,
            title: 'Cloud Sync',
            description: 'Sync your data across all devices',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: HugeIcon(
            icon: icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const Gap(AppSpacing.spacing16),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(AppSpacing.spacing4),
              Text(
                description,
                style: AppTextStyles.body2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
