import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/auth/presentation/login_screen.dart';
import 'package:bexly/features/auth/presentation/signup_screen.dart';
import 'package:bexly/features/auth/presentation/forgot_password_screen.dart';
import 'package:bexly/features/main/presentation/screens/main_screen.dart';

class AuthenticationRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.getStarted,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: Routes.main,
      builder: (context, state) => const MainScreen(),
    ),
  ];
}
