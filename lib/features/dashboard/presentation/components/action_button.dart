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
          onPressed: () => _openNotifications(context),
          icon: HugeIcons.strokeRoundedNotification02,
          showBadge: hasUnreadNotifications.value ?? false,
          themeMode: context.themeMode,
        ),
        // Hide Settings icon on desktop - it's in the sidebar
        if (!context.isDesktopLayout)
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

  void _openNotifications(BuildContext context) {
    // Show as dialog on desktop/web, navigate on mobile
    DesktopDialogHelper.showScreen(
      context,
      desktopWidget: const NotificationListScreen(),
      mobileRoute: Routes.notifications,
    );
  }
}
