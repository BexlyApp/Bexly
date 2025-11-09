import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/theme_switcher/presentation/components/theme_mode_switcher.dart';
import 'package:bexly/features/authentication/presentation/components/create_first_wallet_field.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:toastification/toastification.dart';

part '../components/get_started_button.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      actions: [ThemeModeSwitcher()],
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Gap(60),
                Image.asset(
                  'assets/icon/Bexly-Logo-1024.png',
                  width: 160,
                ),
                const Gap(16),
                const Text(
                  'Welcome to',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Bexly!',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                Text(
                  'Simple and intuitive finance buddy. Track your expenses, set goals, '
                  'organize your pocket and wallet sized finance — everything effortlessly. 🚀',
                  style: AppTextStyles.body1.copyWith(
                    fontVariations: [const FontVariation.weight(500)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(40),
                // Wallet setup field
                const Text(
                  'Setup your first wallet',
                  style: AppTextStyles.heading4,
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                const CreateFirstWalletField(),
                const Gap(120),
              ],
            ),
          ),
          const GetStartedButton(),
        ],
      ),
    );
  }
}
