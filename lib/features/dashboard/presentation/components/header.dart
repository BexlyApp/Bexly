part of '../screens/dashboard_screen.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing20,
          AppSpacing.spacing8,
          AppSpacing.spacing20,
          AppSpacing.spacing12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: GreetingCard()),
                ActionButton(),
              ],
            ),
            const Gap(AppSpacing.spacing8),
            const MonthNavigator(),
          ],
        ),
      ),
    );
  }
}
