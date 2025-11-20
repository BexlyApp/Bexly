import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service to manage budget alert notifications
class BudgetNotificationService {
  /// Check and show notification if budget is exceeded or near limit
  /// Call this after every transaction is added
  static Future<void> checkBudgetAndNotify({
    required BudgetModel budget,
    required double spent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_budget_alerts') ?? true;

      if (!enabled) {
        Log.d('Budget alerts disabled', label: 'notification');
        return;
      }

      final percentage = (spent / budget.amount) * 100;
      final currencyFormat = NumberFormat.currency(
        symbol: budget.wallet.currency,
        decimalDigits: 0,
      );

      String? title;
      String? body;
      int notificationId = budget.id ?? 0 + 10000; // Offset to avoid conflicts

      // Alert at 80% budget used
      if (percentage >= 80 && percentage < 100) {
        title = '⚠️ Budget Alert: ${budget.category.title}';
        body = 'You\'ve used ${percentage.toStringAsFixed(0)}% (${currencyFormat.format(spent)} of ${currencyFormat.format(budget.amount)})';
        notificationId += 1; // Different ID for 80% alert
      }
      // Alert when budget exceeded
      else if (percentage >= 100) {
        title = '🚨 Budget Exceeded: ${budget.category.title}';
        body = 'Over budget by ${currencyFormat.format(spent - budget.amount)}!';
        notificationId += 2; // Different ID for exceeded alert
      }

      if (title != null && body != null) {
        await NotificationService.showInstantNotification(
          id: notificationId,
          title: title,
          body: body,
        );

        Log.i('Budget alert shown for ${budget.category.title}', label: 'notification');
      }
    } catch (e) {
      Log.e('Failed to check budget and notify: $e', label: 'notification');
    }
  }

  /// Show notification when budget is created/updated
  static Future<void> notifyBudgetCreated(BudgetModel budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_budget_alerts') ?? true;

      if (!enabled) return;

      final currencyFormat = NumberFormat.currency(
        symbol: budget.wallet.currency,
        decimalDigits: 0,
      );

      await NotificationService.showInstantNotification(
        id: (budget.id ?? 0) + 10000,
        title: 'Budget Set',
        body: '${currencyFormat.format(budget.amount)} budget for ${budget.category.title}',
      );
    } catch (e) {
      Log.e('Failed to notify budget created: $e', label: 'notification');
    }
  }
}
