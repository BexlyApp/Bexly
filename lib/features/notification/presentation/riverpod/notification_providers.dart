import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';

/// Provider to check if there are any unread notifications
final hasUnreadNotificationsProvider = StreamProvider<bool>((ref) {
  final database = ref.watch(databaseProvider);
  return database.notificationDao
      .watchUnreadNotificationsCount()
      .map((count) => count > 0);
});

/// Provider to get count of unread notifications
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  return database.notificationDao.watchUnreadNotificationsCount();
});

/// Provider to get all notifications (for notification list screen)
final allNotificationsProvider = StreamProvider((ref) {
  final database = ref.watch(databaseProvider);
  return database.notificationDao.watchAllNotifications();
});
