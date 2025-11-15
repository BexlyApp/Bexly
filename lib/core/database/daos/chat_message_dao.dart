import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chat_messages_table.dart';
import '../../utils/logger.dart';

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

  /// Check if message exists by messageId
  Future<bool> messageExists(String messageId) async {
    final result = await (select(chatMessages)
          ..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
    return result != null;
  }

  /// Get message by messageId
  Future<ChatMessage?> getMessageById(String messageId) {
    return (select(chatMessages)..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
  }

  /// Add message only if it doesn't exist (prevents duplicates)
  Future<int> addMessageIfNotExists(ChatMessagesCompanion message) async {
    // Extract messageId from companion
    final messageId = message.messageId.value;

    // Check if already exists
    final exists = await messageExists(messageId);
    if (exists) {
      Log.d('Message already exists: $messageId', label: 'CHAT_DEDUP');
      return 0; // Return 0 to indicate no insert
    }

    // Insert if not exists
    Log.d('Inserting new message: $messageId', label: 'CHAT_DEDUP');
    return await into(chatMessages).insert(message);
  }

  /// Get messages for a specific date range
  Future<List<ChatMessage>> getMessagesInRange(DateTime start, DateTime end) {
    return (select(chatMessages)
          ..where((t) => t.timestamp.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }
}