import 'package:drift/drift.dart';

/// Table to store notification history
class Notifications extends Table {
  // Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  // Notification title
  TextColumn get title => text()();

  // Notification body/message
  TextColumn get body => text()();

  // Notification type: daily_reminder, weekly_report, monthly_report, goal_milestone, recurring_payment
  TextColumn get type => text()();

  // Whether the notification has been read by user
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  // When the notification was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // When the notification was scheduled to appear (nullable)
  DateTimeColumn get scheduledFor => dateTime().nullable()();
}
