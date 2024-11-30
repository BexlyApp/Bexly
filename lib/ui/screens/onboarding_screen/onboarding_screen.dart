import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pockaw/config/app_router.dart';
import 'package:pockaw/ui/themes/app_colors.dart';
import 'package:pockaw/ui/widgets/buttons/buttons.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            // color: Colors.yellow,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/icon/icon-transparent-full.png',
                  width: 160,
                ),
                const Gap(16),
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 38,
                    fontVariations: [FontVariation.weight(900)],
                    color: AppColors.primary900,
                    height: 1,
                  ),
                ),
                const Text(
                  'Pockaw!',
                  style: TextStyle(
                    fontSize: 38,
                    fontVariations: [FontVariation.weight(900)],
                    color: AppColors.secondary,
                  ),
                ),
                const Gap(16),
                const Text(
                  'Simple and intuitive finance buddy. Track your expenses, set goals, '
                  'organize your pocket and wallet sized finance — everything effortlessly. 🚀',
                  style: TextStyle(
                    fontSize: 18,
                    fontVariations: [FontVariation.weight(600)],
                    color: AppColors.primary700,
                  ),
                ),
                const Gap(150),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.light,
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
              child: Button(
                label: 'Get Started',
                onPressed: () => context.push(AppRouter.login),
              ),
            ),
          )
        ],
      ),
    );
  }
}
