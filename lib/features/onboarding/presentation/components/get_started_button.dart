part of '../screens/onboarding_screen.dart';

class GetStartedButton extends ConsumerWidget {
  const GetStartedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: PrimaryButton(
          label: 'Get Started',
          onPressed: () async {
            // Check if user has created a wallet
            final wallet = ref.read(activeWalletProvider).value;

            if (wallet == null) {
              // No wallet created - show warning
              Toast.show(
                'Please setup your wallet first',
                type: ToastificationType.warning,
              );
              return;
            }

            // Wallet created - proceed to main app
            if (context.mounted) {
              context.go('/'); // Navigate to main app
            }
          },
        ),
      ),
    );
  }
}
