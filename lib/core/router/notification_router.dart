import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/notification/presentation/screens/notification_list_screen.dart';

class NotificationRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.notifications,
      builder: (context, state) => const NotificationListScreen(),
    ),
  ];
}
