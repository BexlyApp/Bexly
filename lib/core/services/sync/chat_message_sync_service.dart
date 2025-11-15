import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';

/// Chat message sync service
/// Syncs AI chat messages between local SQLite and Firestore
class ChatMessageSyncService {
  final AppDatabase _localDb;
  final firestore.FirebaseFirestore _firestore;
  final String? _userId;

  ChatMessageSyncService({
    required AppDatabase localDb,
    required firestore.FirebaseFirestore firestore,
    String? userId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _userId = userId;

  bool get isAuthenticated => _userId != null;

  /// Get reference to user's data collection
  firestore.CollectionReference get _userCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  /// Sync a chat message to Firestore
  Future<void> syncMessage(ChatMessage message) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync chat message: User not authenticated', label: 'chat sync');
      return;
    }

    try {
      final data = {
        'messageId': message.messageId,
        'content': message.content,
        'isFromUser': message.isFromUser,
        'timestamp': firestore.Timestamp.fromDate(message.timestamp),
        'error': message.error,
        'isTyping': message.isTyping,
        'createdAt': firestore.Timestamp.fromDate(message.createdAt),
      };

      await _userCollection
          .doc('chat_messages')
          .collection('items')
          .doc(message.messageId)
          .set(data, firestore.SetOptions(merge: true));

      Log.d('Synced chat message ${message.messageId}', label: 'chat sync');
    } catch (e) {
      Log.e('Failed to sync chat message: $e', label: 'chat sync');
    }
  }

  /// Sync all chat messages to Firestore
  Future<void> syncAllMessages() async {
    if (!isAuthenticated) {
      Log.w('Cannot sync: User not authenticated', label: 'chat sync');
      return;
    }

    try {
      final messages = await _localDb.chatMessageDao.getAllMessages();

      // Filter out typing messages - don't sync those
      final messagesToSync = messages.where((m) => !m.isTyping).toList();

      for (final message in messagesToSync) {
        await syncMessage(message);
      }

      Log.i('Synced ${messagesToSync.length} chat messages', label: 'chat sync');
    } catch (e) {
      Log.e('Failed to sync all chat messages: $e', label: 'chat sync');
    }
  }

  /// Delete a chat message from Firestore
  Future<void> deleteMessage(String messageId) async {
    if (!isAuthenticated) return;

    try {
      await _userCollection
          .doc('chat_messages')
          .collection('items')
          .doc(messageId)
          .delete();
      Log.d('Deleted chat message $messageId from cloud', label: 'chat sync');
    } catch (e) {
      Log.e('Failed to delete chat message from cloud: $e', label: 'chat sync');
    }
  }

  /// Clear all chat messages from Firestore
  Future<void> clearAllMessages() async {
    if (!isAuthenticated) return;

    try {
      final snapshot = await _userCollection
          .doc('chat_messages')
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Log.i('Cleared all chat messages from cloud', label: 'chat sync');
    } catch (e) {
      Log.e('Failed to clear chat messages from cloud: $e', label: 'chat sync');
    }
  }

  /// Download all chat messages from Firestore
  Future<List<Map<String, dynamic>>> downloadAllMessages() async {
    if (!isAuthenticated) {
      Log.w('Cannot download: User not authenticated', label: 'chat sync');
      return [];
    }

    try {
      final snapshot = await _userCollection
          .doc('chat_messages')
          .collection('items')
          .orderBy('timestamp')
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'messageId': data['messageId'],
          'content': data['content'],
          'isFromUser': data['isFromUser'],
          'timestamp': (data['timestamp'] as firestore.Timestamp).toDate(),
          'error': data['error'],
          'isTyping': data['isTyping'] ?? false,
          'createdAt': (data['createdAt'] as firestore.Timestamp).toDate(),
        };
      }).toList();

      Log.i('Downloaded ${messages.length} chat messages from cloud', label: 'chat sync');
      return messages;
    } catch (e) {
      Log.e('Failed to download chat messages: $e', label: 'chat sync');
      return [];
    }
  }
}

/// Provider for ChatMessageSyncService
final chatMessageSyncServiceProvider = Provider<ChatMessageSyncService>((ref) {
  final localDb = ref.watch(databaseProvider);
  final firestoreInstance = firestore.FirebaseFirestore.instanceFor(
    app: FirebaseInitService.bexlyApp,
    databaseId: "bexly"
  );
  final userId = ref.watch(userIdProvider);

  return ChatMessageSyncService(
    localDb: localDb,
    firestore: firestoreInstance,
    userId: userId,
  );
});
