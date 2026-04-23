import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/main/presentation/screens/main_screen.dart';
import 'package:bexly/features/auth/presentation/login_screen.dart';

class AuthenticationRouter {
  static final routes = <GoRoute>[
    // Login screen - shown after sign out
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.getStarted,
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: Routes.main,
      builder: (context, state) => const MainScreen(),
    ),
  ];
}
