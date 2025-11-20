import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service to manage goal milestone notifications
class GoalNotificationService {
  /// Check and show notification for goal milestones
  /// Call this when goal progress is updated
  static Future<void> checkGoalMilestoneAndNotify({
    required GoalModel goal,
    required double currentAmount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_goal_milestones') ?? true;

      if (!enabled) {
        Log.d('Goal milestone notifications disabled', label: 'notification');
        return;
      }

      final percentage = (currentAmount / goal.targetAmount) * 100;
      final currencyFormat = NumberFormat.currency(
        symbol: goal.currency,
        decimalDigits: 0,
      );

      String? title;
      String? body;
      int notificationId = (goal.id ?? 0) + 20000; // Offset for goals

      // Celebrate milestones: 25%, 50%, 75%, 100%
      if (percentage >= 25 && percentage < 26) {
        title = '🎯 25% Progress!';
        body = '${goal.title}: ${currencyFormat.format(currentAmount)} of ${currencyFormat.format(goal.targetAmount)}';
        notificationId += 1;
      } else if (percentage >= 50 && percentage < 51) {
        title = '🎉 Halfway There!';
        body = '${goal.title}: You\'ve reached 50% of your goal!';
        notificationId += 2;
      } else if (percentage >= 75 && percentage < 76) {
        title = '🚀 75% Complete!';
        body = '${goal.title}: Almost there! Just ${currencyFormat.format(goal.targetAmount - currentAmount)} more';
        notificationId += 3;
      } else if (percentage >= 100) {
        title = '🏆 Goal Achieved!';
        body = 'Congratulations! You\'ve reached your ${goal.title} goal of ${currencyFormat.format(goal.targetAmount)}!';
        notificationId += 4;
      }

      if (title != null && body != null) {
        await NotificationService.showInstantNotification(
          id: notificationId,
          title: title,
          body: body,
        );

        Log.i('Goal milestone notification shown for ${goal.title}', label: 'notification');
      }
    } catch (e) {
      Log.e('Failed to check goal milestone: $e', label: 'notification');
    }
  }

  /// Notify when a new goal is created
  static Future<void> notifyGoalCreated(GoalModel goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_goal_milestones') ?? true;

      if (!enabled) return;

      final currencyFormat = NumberFormat.currency(
        symbol: goal.currency,
        decimalDigits: 0,
      );

      await NotificationService.showInstantNotification(
        id: (goal.id ?? 0) + 20000,
        title: 'New Goal Set',
        body: '${goal.title}: ${currencyFormat.format(goal.targetAmount)} by ${DateFormat.yMMMd().format(goal.targetDate)}',
      );
    } catch (e) {
      Log.e('Failed to notify goal created: $e', label: 'notification');
    }
  }
}
