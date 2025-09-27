import 'package:drift/drift.dart';
import '../pockaw_database.dart';
import '../tables/chat_messages_table.dart';

part 'chat_message_dao.g.dart';

@DriftAccessor(tables: [ChatMessages])
class ChatMessageDao extends DatabaseAccessor<AppDatabase> with _$ChatMessageDaoMixin {
  ChatMessageDao(AppDatabase db) : super(db);

  /// Get all chat messages ordered by timestamp
  Future<List<ChatMessage>> getAllMessages() {
    return (select(chatMessages)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }

  /// Stream of all chat messages
  Stream<List<ChatMessage>> watchAllMessages() {
    return (select(chatMessages)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .watch();
  }

  /// Add a new message
  Future<int> addMessage(ChatMessagesCompanion message) {
    return into(chatMessages).insert(message);
  }

  /// Delete all messages (clear chat history)
  Future<void> clearAllMessages() {
    return delete(chatMessages).go();
  }

  /// Delete a specific message
  Future<int> deleteMessage(String messageId) {
    return (delete(chatMessages)..where((t) => t.messageId.equals(messageId))).go();
  }

  /// Get messages for a specific date range
  Future<List<ChatMessage>> getMessagesInRange(DateTime start, DateTime end) {
    return (select(chatMessages)
          ..where((t) => t.timestamp.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }
}