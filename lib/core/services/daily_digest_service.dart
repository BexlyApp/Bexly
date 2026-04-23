import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Daily Financial Digest — generates personalized spending summary
/// and sends as push notification every morning.
class DailyDigestService {
  static const int notificationId = 9003;
  static const String taskName = 'daily_digest';
  static const String _enabledKey = 'notif_daily_digest';
  static const String _lastDigestKey = 'daily_digest_last_date';

  /// Schedule daily digest notification at 8 AM
  static Future<void> schedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_enabledKey) ?? true; // enabled by default

      if (!enabled) {
        await NotificationService.cancelNotification(notificationId);
        return;
      }

      await NotificationService.scheduleDailyNotification(
        id: notificationId,
        title: 'Daily Financial Digest',
        body: 'Your personalized spending summary is ready',
        hour: 8,
        minute: 0,
      );

      Log.i('Daily digest scheduled for 8:00 AM', label: 'DailyDigest');
    } catch (e) {
      Log.e('Failed to schedule daily digest: $e', label: 'DailyDigest');
    }
  }

  /// Generate and show the digest notification with personalized content
  static Future<void> generateAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debounce: only run once per day
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastRun = prefs.getString(_lastDigestKey);
      if (lastRun == today) return;
      prefs.setString(_lastDigestKey, today);

      final db = AppDatabase();
      final digest = await _buildDigest(db);

      if (digest == null) return; // No data to digest

      await NotificationService.showInstantNotification(
        id: notificationId,
        title: digest.title,
        body: digest.body,
        payload: 'daily_digest',
      );

      // Save to notification database
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          title: Value(digest.title),
          body: Value(digest.body),
          type: const Value('daily_digest'),
          isRead: const Value(false),
        ),
      );

      Log.i('Daily digest sent: ${digest.title}', label: 'DailyDigest');
    } catch (e) {
      Log.e('Failed to generate daily digest: $e', label: 'DailyDigest');
    }
  }

  /// Build personalized digest from yesterday's transactions
  static Future<_DigestContent?> _buildDigest(AppDatabase db) async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final todayStart = DateTime(now.year, now.month, now.day);

    // Get yesterday's transactions
    final allTx = await db.transactionDao
        .watchAllTransactionsWithDetails()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => []);

    final yesterdayTx = allTx.where((t) =>
        !t.date.isBefore(yesterday) && t.date.isBefore(todayStart)).toList();

    // Month-to-date totals
    final monthStart = DateTime(now.year, now.month, 1);
    final mtdTx = allTx.where((t) =>
        !t.date.isBefore(monthStart) && t.date.isBefore(todayStart)).toList();

    final mtdIncome = mtdTx
        .where((t) => t.transactionType == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final mtdExpense = mtdTx
        .where((t) => t.transactionType == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    String fmt(num v) => v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    if (yesterdayTx.isEmpty && mtdTx.isEmpty) return null;

    // Yesterday summary
    final ydIncome = yesterdayTx
        .where((t) => t.transactionType == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final ydExpense = yesterdayTx
        .where((t) => t.transactionType == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    // Top category yesterday
    final catSpend = <String, double>{};
    for (final t in yesterdayTx.where((t) => t.transactionType == TransactionType.expense)) {
      catSpend[t.category.title] = (catSpend[t.category.title] ?? 0) + t.amount;
    }
    final topCat = catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final budgetPace = daysInMonth > 0 ? (mtdExpense / dayOfMonth * daysInMonth) : mtdExpense;

    // Build notification content
    String title;
    if (yesterdayTx.isEmpty) {
      title = 'No transactions yesterday';
    } else {
      title = 'Yesterday: ${fmt(ydExpense)} spent'
          '${ydIncome > 0 ? ', ${fmt(ydIncome)} earned' : ''}';
    }

    final lines = <String>[];

    if (topCat.isNotEmpty) {
      lines.add('Top: ${topCat.first.key} (${fmt(topCat.first.value)})');
    }

    lines.add('MTD: ${fmt(mtdExpense)} spent / ${fmt(mtdIncome)} earned');

    if (budgetPace > mtdIncome && mtdIncome > 0) {
      lines.add('At this pace you\'ll spend ${fmt(budgetPace)} this month');
    }

    final net = mtdIncome - mtdExpense;
    if (net > 0) {
      lines.add('Net savings so far: +${fmt(net)}');
    } else if (net < 0) {
      lines.add('Over budget by ${fmt(net.abs())}');
    }

    return _DigestContent(
      title: title,
      body: lines.join(' | '),
    );
  }
}

class _DigestContent {
  final String title;
  final String body;
  const _DigestContent({required this.title, required this.body});
}
