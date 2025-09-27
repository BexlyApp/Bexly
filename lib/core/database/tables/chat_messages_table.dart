import 'package:drift/drift.dart';

/// Table for storing AI chat messages
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Unique ID for the message (UUID)
  TextColumn get messageId => text()();

  /// Message content
  TextColumn get content => text()();

  /// Whether message is from user (true) or AI (false)
  BoolColumn get isFromUser => boolean()();

  /// When the message was sent
  DateTimeColumn get timestamp => dateTime()();

  /// Optional error message if something went wrong
  TextColumn get error => text().nullable()();

  /// Whether the message is a typing indicator
  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();

  /// Created at timestamp for database record
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}