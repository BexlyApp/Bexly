import 'dart:math';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/notification_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detects anomalous spending and alerts the user.
/// An anomaly is defined as a transaction that exceeds 3x the rolling
/// 30-day average for its category, or a single-day spend exceeding
/// 50% of the month's budget pace.
class SpendingAnomalyService {
  static const int _notificationId = 9010;

  final AppDatabase _db;

  SpendingAnomalyService(this._db);

  /// Check a newly created transaction for anomalies.
  /// Returns an anomaly description if detected, null otherwise.
  Future<SpendingAnomaly?> checkTransaction(TransactionModel tx) async {
    try {
      if (tx.transactionType != TransactionType.expense) return null;

      final categoryId = tx.category.id;
      if (categoryId == null) return null;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get recent transactions in the same category
      final allTx = await _db.transactionDao
          .watchAllTransactionsWithDetails()
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () => []);

      final categoryTx = allTx.where((t) =>
          t.transactionType == TransactionType.expense &&
          t.category.id == categoryId &&
          t.date.isAfter(thirtyDaysAgo) &&
          t.id != tx.id).toList();

      if (categoryTx.length < 3) return null; // Need enough history

      // Calculate rolling average
      final totalSpent = categoryTx.fold<double>(0, (s, t) => s + t.amount);
      final avgAmount = totalSpent / categoryTx.length;

      // Anomaly threshold: 3x the average
      final threshold = avgAmount * 3;

      if (tx.amount > threshold && tx.amount > avgAmount + 50000) {
        // Also check it's not a trivially small difference
        final multiplier = (tx.amount / avgAmount).toStringAsFixed(1);

        final anomaly = SpendingAnomaly(
          categoryName: tx.category.title,
          amount: tx.amount,
          averageAmount: avgAmount,
          multiplier: double.parse(multiplier),
          message: '${tx.category.title} spending of ${_fmt(tx.amount)} is '
              '${multiplier}x your average (${_fmt(avgAmount)})',
        );

        // Send notification
        await _sendAlert(anomaly);

        return anomaly;
      }

      // Check single-day spike: if today's total in this category exceeds
      // what would be expected for the entire week
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayTotal = allTx.where((t) =>
          t.transactionType == TransactionType.expense &&
          t.category.id == categoryId &&
          !t.date.isBefore(todayStart)).fold<double>(0, (s, t) => s + t.amount);

      final weeklyPace = avgAmount * min(categoryTx.length, 7);
      if (todayTotal > weeklyPace && todayTotal > 200000) {
        final anomaly = SpendingAnomaly(
          categoryName: tx.category.title,
          amount: todayTotal,
          averageAmount: avgAmount,
          multiplier: todayTotal / avgAmount,
          message: 'You\'ve spent ${_fmt(todayTotal)} on ${tx.category.title} '
              'today — more than a typical week',
        );

        await _sendAlert(anomaly);
        return anomaly;
      }

      return null;
    } catch (e) {
      Log.e('Anomaly check failed: $e', label: 'SpendingAnomaly');
      return null;
    }
  }

  Future<void> _sendAlert(SpendingAnomaly anomaly) async {
    try {
      await NotificationService.showInstantNotification(
        id: _notificationId,
        title: 'Unusual Spending Detected',
        body: anomaly.message,
        payload: 'spending_anomaly',
      );

      await _db.notificationDao.insertNotification(
        NotificationsCompanion(
          title: const Value('Unusual Spending Detected'),
          body: Value(anomaly.message),
          type: const Value('spending_anomaly'),
          isRead: const Value(false),
        ),
      );
    } catch (e) {
      Log.e('Failed to send anomaly alert: $e', label: 'SpendingAnomaly');
    }
  }

  static String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

/// Represents a detected spending anomaly
class SpendingAnomaly {
  final String categoryName;
  final double amount;
  final double averageAmount;
  final double multiplier;
  final String message;

  const SpendingAnomaly({
    required this.categoryName,
    required this.amount,
    required this.averageAmount,
    required this.multiplier,
    required this.message,
  });
}

/// Riverpod provider for SpendingAnomalyService
final spendingAnomalyServiceProvider = Provider<SpendingAnomalyService>((ref) {
  final db = ref.watch(databaseProvider);
  return SpendingAnomalyService(db);
});
