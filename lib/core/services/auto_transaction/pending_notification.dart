import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/utils/logger.dart';

/// Represents a pending notification that was captured but not yet processed
class PendingNotification {
  final String id;
  final String packageName;
  final String? appName;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isProcessed;
  final String? bankCode; // Detected bank code (VCB, TCB, etc.)
  final String? accountId; // Detected account identifier (last 4 digits)
  final String? accountType; // 'credit', 'debit', 'savings', 'checking'
  final double? amount; // Detected transaction amount
  final String? transactionType; // 'income' or 'expense'

  PendingNotification({
    required this.id,
    required this.packageName,
    this.appName,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isProcessed = false,
    this.bankCode,
    this.accountId,
    this.accountType,
    this.amount,
    this.transactionType,
  });

  /// Full message content (title + body)
  String get fullMessage => '$title\n$body'.trim();

  /// Copy with processed status
  PendingNotification copyWithProcessed(bool processed) {
    return PendingNotification(
      id: id,
      packageName: packageName,
      appName: appName,
      title: title,
      body: body,
      receivedAt: receivedAt,
      isProcessed: processed,
      bankCode: bankCode,
      accountId: accountId,
      accountType: accountType,
      amount: amount,
      transactionType: transactionType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'isProcessed': isProcessed,
        'bankCode': bankCode,
        'accountId': accountId,
        'accountType': accountType,
        'amount': amount,
        'transactionType': transactionType,
      };

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isProcessed: json['isProcessed'] as bool? ?? false,
      bankCode: json['bankCode'] as String?,
      accountId: json['accountId'] as String?,
      accountType: json['accountType'] as String?,
      amount: json['amount'] as double?,
      transactionType: json['transactionType'] as String?,
    );
  }

  @override
  String toString() =>
      'PendingNotification(${appName ?? packageName}: $title, processed: $isProcessed)';
}

/// Service to manage pending notifications storage
class PendingNotificationStorage {
  static const String _storageKey = 'pending_notifications';
  static const String _lastCheckedKey = 'pending_notifications_last_checked';
  static const int _maxPendingNotifications = 100; // Limit to avoid storage bloat

  /// Get all pending notifications
  Future<List<PendingNotification>> getPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      return jsonList.map((json) {
        return PendingNotification.fromJson(jsonDecode(json));
      }).toList();
    } catch (e) {
      Log.e('Error loading pending notifications: $e',
          label: 'PendingNotification');
      return [];
    }
  }

  /// Get only unprocessed notifications
  Future<List<PendingNotification>> getUnprocessedNotifications() async {
    final all = await getPendingNotifications();
    return all.where((n) => !n.isProcessed).toList();
  }

  /// Get pending count (for badge display)
  Future<int> getPendingCount() async {
    final unprocessed = await getUnprocessedNotifications();
    return unprocessed.length;
  }

  /// Add a new pending notification
  Future<void> addNotification(PendingNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      // Check for duplicates (same id)
      final existingIndex = jsonList.indexWhere((json) {
        final existing = PendingNotification.fromJson(jsonDecode(json));
        return existing.id == notification.id;
      });

      if (existingIndex >= 0) {
        // Update existing
        jsonList[existingIndex] = jsonEncode(notification.toJson());
      } else {
        // Add new
        jsonList.add(jsonEncode(notification.toJson()));
      }

      // Trim old notifications if exceeding limit
      if (jsonList.length > _maxPendingNotifications) {
        // Sort by date (oldest first) and remove oldest
        final notifications = jsonList
            .map((json) => PendingNotification.fromJson(jsonDecode(json)))
            .toList()
          ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));

        // Keep only the newest ones
        final toKeep =
            notifications.skip(notifications.length - _maxPendingNotifications);
        jsonList.clear();
        jsonList.addAll(toKeep.map((n) => jsonEncode(n.toJson())));
      }

      await prefs.setStringList(_storageKey, jsonList);

      Log.d('Added pending notification: ${notification.id}',
          label: 'PendingNotification');
    } catch (e) {
      Log.e('Error adding pending notification: $e',
          label: 'PendingNotification');
    }
  }

  /// Mark a notification as processed
  Future<void> markAsProcessed(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      final updatedList = jsonList.map((json) {
        final notification = PendingNotification.fromJson(jsonDecode(json));
        if (notification.id == notificationId) {
          return jsonEncode(notification.copyWithProcessed(true).toJson());
        }
        return json;
      }).toList();

      await prefs.setStringList(_storageKey, updatedList);

      Log.d('Marked notification as processed: $notificationId',
          label: 'PendingNotification');
    } catch (e) {
      Log.e('Error marking notification as processed: $e',
          label: 'PendingNotification');
    }
  }

  /// Mark multiple notifications as processed
  Future<void> markMultipleAsProcessed(List<String> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final idsSet = notificationIds.toSet();

      final updatedList = jsonList.map((json) {
        final notification = PendingNotification.fromJson(jsonDecode(json));
        if (idsSet.contains(notification.id)) {
          return jsonEncode(notification.copyWithProcessed(true).toJson());
        }
        return json;
      }).toList();

      await prefs.setStringList(_storageKey, updatedList);

      Log.d('Marked ${notificationIds.length} notifications as processed',
          label: 'PendingNotification');
    } catch (e) {
      Log.e('Error marking notifications as processed: $e',
          label: 'PendingNotification');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      jsonList.removeWhere((json) {
        final notification = PendingNotification.fromJson(jsonDecode(json));
        return notification.id == notificationId;
      });

      await prefs.setStringList(_storageKey, jsonList);

      Log.d('Deleted notification: $notificationId',
          label: 'PendingNotification');
    } catch (e) {
      Log.e('Error deleting notification: $e', label: 'PendingNotification');
    }
  }

  /// Delete all processed notifications
  Future<void> clearProcessedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      jsonList.removeWhere((json) {
        final notification = PendingNotification.fromJson(jsonDecode(json));
        return notification.isProcessed;
      });

      await prefs.setStringList(_storageKey, jsonList);

      Log.d('Cleared all processed notifications',
          label: 'PendingNotification');
    } catch (e) {
      Log.e('Error clearing processed notifications: $e',
          label: 'PendingNotification');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      Log.d('Cleared all pending notifications', label: 'PendingNotification');
    } catch (e) {
      Log.e('Error clearing all notifications: $e',
          label: 'PendingNotification');
    }
  }

  /// Get last checked timestamp
  Future<DateTime?> getLastCheckedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastCheckedKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      Log.e('Error getting last checked time: $e',
          label: 'PendingNotification');
      return null;
    }
  }

  /// Update last checked timestamp
  Future<void> updateLastCheckedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckedKey, DateTime.now().toIso8601String());
    } catch (e) {
      Log.e('Error updating last checked time: $e',
          label: 'PendingNotification');
    }
  }

  /// Check if there are any pending notifications to process
  Future<bool> hasPendingNotifications() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Group pending notifications by bank code
  Future<Map<String, List<PendingNotification>>>
      groupNotificationsByBank() async {
    final unprocessed = await getUnprocessedNotifications();
    final grouped = <String, List<PendingNotification>>{};

    for (final notification in unprocessed) {
      final key = notification.bankCode ?? 'unknown';
      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  /// Group pending notifications by bank code and account ID
  Future<Map<String, List<PendingNotification>>>
      groupNotificationsByBankAndAccount() async {
    final unprocessed = await getUnprocessedNotifications();
    final grouped = <String, List<PendingNotification>>{};

    for (final notification in unprocessed) {
      final bankKey = notification.bankCode ?? 'unknown';
      final accountKey = notification.accountId ?? 'default';
      final key = '${bankKey}_$accountKey';
      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }
}
