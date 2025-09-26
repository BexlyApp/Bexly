import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/goal/presentation/screens/goal_details_screen.dart';

class GoalRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.goalDetails,
      builder: (context, state) {
        final goalId = state.extra as int;
        Log.d('🗂️  Routing to GoalDetailsScreen for goalId=$goalId');
        return GoalDetailsScreen(goalId: goalId);
      },
    ),
  ];
}
