import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/pockaw_database.dart';
import 'package:bexly/core/database/daos/chat_message_dao.dart';

// Provider for ChatMessageDao
final chatMessageDaoProvider = Provider<ChatMessageDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.chatMessageDao;
});

// Stream provider for all chat messages from database
final chatMessagesStreamProvider = StreamProvider<List<ChatMessage>>((ref) {
  final dao = ref.watch(chatMessageDaoProvider);
  return dao.watchAllMessages();
});