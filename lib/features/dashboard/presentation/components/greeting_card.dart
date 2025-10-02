part of '../screens/dashboard_screen.dart';

class GreetingCard extends ConsumerWidget {
  const GreetingCard({super.key});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.l10n.goodMorning;
    } else if (hour < 17) {
      return context.l10n.goodAfternoon;
    } else {
      return context.l10n.goodEvening;
    }
  }

  @override
  Widget build(BuildContext context, ref) {
    final auth = ref.watch(authStateProvider);

    return Row(
      children: [
        auth.profilePicture == null
            ? const CircleIconButton(
                icon: HugeIcons.strokeRoundedUser,
                radius: 25,
                backgroundColor: AppColors.secondary100,
                foregroundColor: AppColors.secondary800,
              )
            : CircleAvatar(
                backgroundImage: FileImage(File(auth.profilePicture!)),
              ),
        const Gap(AppSpacing.spacing12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getGreeting(context)},', style: AppTextStyles.body4),
            Text(auth.name, style: AppTextStyles.body2),
          ],
        ),
      ],
    );
  }
}
