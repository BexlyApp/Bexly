import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/notifications_table.dart';

part 'notification_dao.g.dart';

/// DAO for managing notification records
@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(AppDatabase db) : super(db);

  /// Get all notifications ordered by creation date (newest first)
  Future<List<Notification>> getAllNotifications() async {
    return (select(notifications)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Get only unread notifications
  Future<List<Notification>> getUnreadNotifications() async {
    return (select(notifications)
          ..where((tbl) => tbl.isRead.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Get count of unread notifications
  Future<int> getUnreadNotificationsCount() async {
    final query = selectOnly(notifications)
      ..addColumns([notifications.id.count()])
      ..where(notifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(notifications.id.count()) ?? 0;
  }

  /// Insert a new notification
  Future<int> insertNotification(NotificationsCompanion notification) async {
    return into(notifications).insert(notification);
  }

  /// Mark a notification as read
  Future<bool> markAsRead(int notificationId) async {
    final count = await (update(notifications)..where((tbl) => tbl.id.equals(notificationId)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    return count > 0;
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    return (update(notifications)
          ..where((tbl) => tbl.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// Delete a specific notification
  Future<int> deleteNotification(int notificationId) async {
    return (delete(notifications)..where((tbl) => tbl.id.equals(notificationId)))
        .go();
  }

  /// Delete all notifications
  Future<int> deleteAllNotifications() async {
    return delete(notifications).go();
  }

  /// Delete notifications older than specified days
  Future<int> deleteOldNotifications({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return (delete(notifications)
          ..where((tbl) => tbl.createdAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Watch all notifications (for real-time updates)
  Stream<List<Notification>> watchAllNotifications() {
    return (select(notifications)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// Watch unread notifications count
  Stream<int> watchUnreadNotificationsCount() {
    final query = selectOnly(notifications)
      ..addColumns([notifications.id.count()])
      ..where(notifications.isRead.equals(false));

    return query.watchSingle().map((row) => row.read(notifications.id.count()) ?? 0);
  }
}
