import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_database.dart';
import '../tables/chat_messages_table.dart';
import '../../utils/logger.dart';
import '../../services/sync/supabase_sync_provider.dart';

part 'chat_message_dao.g.dart';

@DriftAccessor(tables: [ChatMessages])
class ChatMessageDao extends DatabaseAccessor<AppDatabase> with _$ChatMessageDaoMixin {
  final Ref? _ref;

  ChatMessageDao(AppDatabase db, [this._ref]) : super(db);

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

  /// Add a new message with auto-sync to Supabase
  Future<int> addMessage(ChatMessagesCompanion message) async {
    Log.d('Adding new chat message', label: 'chat');

    // 1. Save to local database
    final result = await into(chatMessages).insert(message);

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          // Query the saved message to get ChatMessage object for sync
          final savedMessage = await (select(chatMessages)
                ..where((t) => t.messageId.equals(message.messageId.value)))
              .getSingleOrNull();

          if (savedMessage != null) {
            await syncService.uploadChatMessage(savedMessage);
            Log.d('✅ [CHAT SYNC] Chat message uploaded successfully', label: 'sync');
          }
        } catch (e, stack) {
          Log.e('Failed to upload chat message to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local save succeeded
        }
      }
    }

    return result;
  }

  /// Delete all messages (clear chat history) with cloud sync
  Future<void> clearAllMessages() async {
    Log.d('Clearing all chat messages', label: 'chat');

    // 1. Delete from local database
    await delete(chatMessages).go();

    // 2. Delete from cloud (if sync available)
    if (_ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.clearAllChatMessagesFromCloud();
          Log.d('✅ [CHAT SYNC] All chat messages cleared from cloud', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to clear chat messages from cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local delete succeeded
        }
      }
    }
  }

  /// Delete a specific message with cloud sync
  Future<int> deleteMessage(String messageId) async {
    Log.d('Deleting chat message: $messageId', label: 'chat');

    // 1. Delete from local database
    final count = await (delete(chatMessages)..where((t) => t.messageId.equals(messageId))).go();

    // 2. Delete from cloud (if sync available)
    if (count > 0 && _ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.deleteChatMessageFromCloud(messageId);
          Log.d('✅ [CHAT SYNC] Chat message deleted from cloud', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to delete chat message from cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local delete succeeded
        }
      }
    }

    return count;
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

  /// Update message content by messageId
  Future<int> updateMessageContent(String messageId, String newContent) {
    return (update(chatMessages)..where((t) => t.messageId.equals(messageId)))
        .write(ChatMessagesCompanion(content: Value(newContent)));
  }
}