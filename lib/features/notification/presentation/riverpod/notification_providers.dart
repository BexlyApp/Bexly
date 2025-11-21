import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/services/notification_service.dart';

/// Provider to check if there are any pending notifications
final hasPendingNotificationsProvider = FutureProvider<bool>((ref) async {
  final pendingNotifications = await NotificationService.getPendingNotifications();
  return pendingNotifications.isNotEmpty;
});

/// Provider to get count of pending notifications
final pendingNotificationsCountProvider = FutureProvider<int>((ref) async {
  final pendingNotifications = await NotificationService.getPendingNotifications();
  return pendingNotifications.length;
});
