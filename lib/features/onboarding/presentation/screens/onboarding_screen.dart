import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/features/theme_switcher/presentation/components/theme_mode_switcher.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/onboarding/presentation/components/onboarding_slide_1.dart';
import 'package:bexly/features/onboarding/presentation/components/onboarding_slide_2.dart';
import 'package:bexly/features/onboarding/presentation/components/onboarding_slide_3.dart';
import 'package:bexly/features/onboarding/presentation/components/avatar_picker.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      actions: [
        // Show Skip button only on first 2 pages
        if (currentPage.value < 2)
          TextButton(
            onPressed: () {
              pageController.animateToPage(
                2, // Jump to slide 3 (setup page)
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text(
              'Skip',
              style: AppTextStyles.body1,
            ),
          )
        else
          const ThemeModeSwitcher(),
      ],
      body: Column(
        children: [
          // PageView
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (index) {
                currentPage.value = index;
              },
              children: const [
                OnboardingSlide1(),
                OnboardingSlide2(),
                OnboardingSlide3(),
              ],
            ),
          ),

          // Bottom section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing24),
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage.value == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentPage.value == index
                            ? AppColors.primary
                            : AppColors.neutral300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.spacing24),

                // Action button
                if (currentPage.value < 2)
                  // Next button for slides 1 & 2
                  PrimaryButton(
                    label: 'Next',
                    onPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  )
                else
                  // Get Started button for slide 3
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () => _handleGetStarted(context, ref),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGetStarted(BuildContext context, WidgetRef ref) async {
    final displayName = ref.read(displayNameProvider);
    final avatarPath = ref.read(avatarPathProvider);
    final wallet = ref.read(activeWalletProvider).valueOrNull;

    // Validation
    if (displayName.trim().isEmpty) {
      Toast.show('Please enter your display name');
      return;
    }

    if (wallet == null) {
      Toast.show('Please setup your first wallet');
      return;
    }

    try {
      // Get current user or create dummy
      final currentUser = ref.read(authStateProvider);

      // Update user with profile info
      final updatedUser = currentUser.copyWith(
        name: displayName,
        profilePicture: avatarPath,
      );

      // Save user profile
      ref.read(authStateProvider.notifier).setUser(updatedUser);

      Log.i('Profile setup complete: ${updatedUser.toJson()}', label: 'onboarding');

      // Navigate to main screen
      if (context.mounted) {
        context.go(Routes.main);
      }
    } catch (e) {
      Log.e('Error completing onboarding: $e', label: 'onboarding');
      if (context.mounted) {
        Toast.show('Error setting up profile');
      }
    }
  }
}
