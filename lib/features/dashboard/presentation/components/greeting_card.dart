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
    // Use local auth state for user profile
    final auth = ref.watch(authStateProvider);
    final displayName = auth.name;
    final photoUrl = auth.profilePicture;

    return Row(
      children: [
        _UserAvatar(photoUrl: photoUrl, radius: 25),
        const Gap(AppSpacing.spacing12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getGreeting(context)},', style: AppTextStyles.body4),
            Row(
              children: [
                Text(displayName, style: AppTextStyles.body2),
                const SizedBox(width: 6),
                LevelBadgeWidget(
                  totalXp: 420, // Phase 0: mock XP — replace with real provider in Phase 2
                  onTap: () => context.push(Routes.gamificationProfile),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.photoUrl, required this.radius});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) return _fallback();

    if (!photoUrl!.startsWith('http')) {
      return CircleAvatar(
        backgroundImage: FileImage(File(photoUrl!)),
        radius: radius,
      );
    }

    // Network image with error fallback for 404/broken URLs
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _fallback();
        },
      ),
    );
  }

  Widget _fallback() => CircleIconButton(
        icon: HugeIcons.strokeRoundedUser,
        radius: radius,
        backgroundColor: AppColors.secondary100,
        foregroundColor: AppColors.secondary800,
      );
}
