part of '../screens/login_screen.dart';

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/icon/Bexly-logo-no-bg.png', width: size, height: size),
          const Gap(AppSpacing.spacing12),
        ],
      ),
    );
  }
}
