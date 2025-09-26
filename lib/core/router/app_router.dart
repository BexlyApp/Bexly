import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/app.dart';
import 'package:bexly/core/components/placeholders/placeholder_screen.dart';

import 'package:bexly/core/router/authentication_router.dart';
import 'package:bexly/core/router/budget_router.dart';
import 'package:bexly/core/router/category_router.dart';
import 'package:bexly/core/router/currency_router.dart';
import 'package:bexly/core/router/goal_router.dart'; // ← import your GoalRouter
import 'package:bexly/core/router/onboarding_router.dart';
import 'package:bexly/core/router/report_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/router/settings_router.dart';
import 'package:bexly/core/router/transaction_router.dart';
import 'package:bexly/core/router/wallet_router.dart';
import 'package:bexly/features/splash/presentation/screens/bexly_splash_screen.dart';

final rootNavKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavKey,
  initialLocation: Routes.splash,
  observers: <NavigatorObserver>[MyApp.observer],
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const BexlySplashScreen(),
    ),
    GoRoute(
      path: Routes.comingSoon,
      builder: (context, state) => const PlaceholderScreen(),
    ),

    // feature‐specific sub‐routers:
    ...OnboardingRouter.routes,
    ...AuthenticationRouter.routes,
    ...TransactionRouter.routes,
    ...CategoryRouter.routes,
    ...GoalRouter.routes,
    ...BudgetRouter.routes,
    ...SettingsRouter.routes,
    ...CurrencyRouter.routes,
    ...WalletRouter.routes,
    ...ReportRouter.routes,
  ],
);
