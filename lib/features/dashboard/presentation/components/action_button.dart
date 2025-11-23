part of '../screens/dashboard_screen.dart';

class ActionButton extends ConsumerWidget {
  const ActionButton({super.key});

  @override
  Widget build(BuildContext context, ref) {
    // Watch for unread notifications
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);

    return Row(
      spacing: context.isDesktopLayout
          ? AppSpacing.spacing16
          : AppSpacing.spacing8,
      children: [
        CustomIconButton(
          context,
          onPressed: () => context.push(Routes.notifications),
          icon: HugeIcons.strokeRoundedNotification02,
          showBadge: hasUnreadNotifications.valueOrNull ?? false,
          themeMode: context.themeMode,
        ),
        CustomIconButton(
          context,
          onPressed: () {
            context.push(Routes.settings);
          },
          icon: HugeIcons.strokeRoundedSettings01,
          themeMode: context.themeMode,
        ),
      ],
    );
  }
}
