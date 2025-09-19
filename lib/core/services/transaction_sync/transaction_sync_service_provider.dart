import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pockaw/core/services/transaction_sync/transaction_sync_service.dart';

final transactionSyncServiceProvider = Provider<TransactionSyncService>((ref) {
  return TransactionSyncService();
});



