import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class OnboardingSlide1 extends StatelessWidget {
  const OnboardingSlide1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/icon/Bexly-Logo-no-text-1024.png',
            width: 200,
            height: 200,
          ),
          const Gap(AppSpacing.spacing32),

          // Title
          const Text(
            'Welcome to Bexly',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.spacing16),

          // Description
          Text(
            'Your personal finance companion.\nTrack expenses, manage budgets, and achieve your financial goals effortlessly.',
            style: AppTextStyles.body1.copyWith(
              fontVariations: [const FontVariation.weight(500)],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
