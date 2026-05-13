import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/pending_transaction_table.dart';
import 'package:bexly/core/utils/logger.dart';

/// Subscribes to `bexly.tingee_transactions` via Supabase Realtime and pushes
/// every new row into the local `pending_transactions` queue so the user
/// reviews it through the existing pending-transactions UI (same flow as
/// SMS / notification / email sources).
///
/// Lifecycle: call [start] when the user signs in, [stop] on sign-out or
/// app dispose. Idempotent - calling [start] twice is a no-op.
class TingeeRealtimeService {
  TingeeRealtimeService(this._db);

  static const _label = 'TingeeRealtime';
  final AppDatabase _db;

  RealtimeChannel? _channel;
  String? _subscribedUserId;

  bool get isRunning => _channel != null;

  Future<void> start() async {
    final session = Supabase.instance.client.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null) {
      Log.d('Skip - user not signed in', label: _label);
      return;
    }
    if (isRunning && _subscribedUserId == userId) {
      return; // already subscribed for this user
    }
    if (isRunning) {
      await stop();
    }

    _subscribedUserId = userId;
    final channel = Supabase.instance.client.channel('bexly_tingee_$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'bexly',
          table: 'tingee_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .subscribe();

    _channel = channel;
    Log.i('Subscribed to bexly.tingee_transactions for user $userId',
        label: _label);

    // Also drain any unprocessed rows that arrived while the app was offline.
    await _drainBacklog(userId);
  }

  Future<void> stop() async {
    final ch = _channel;
    if (ch == null) return;
    await Supabase.instance.client.removeChannel(ch);
    _channel = null;
    _subscribedUserId = null;
    Log.i('Unsubscribed', label: _label);
  }

  Future<void> _drainBacklog(String userId) async {
    try {
      final rows = await Supabase.instance.client
          .schema('bexly')
          .from('tingee_transactions')
          .select()
          .eq('user_id', userId)
          .isFilter('processed_at', null)
          .order('received_at', ascending: true);

      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        await _handleInsert(row);
      }
      if (rows.isNotEmpty) {
        Log.i('Drained ${rows.length} backlog tingee tx', label: _label);
      }
    } catch (e) {
      Log.e('Backlog drain failed: $e', label: _label);
    }
  }

  Future<void> _handleInsert(Map<String, dynamic> row) async {
    try {
      final tingeeId = row['tingee_transaction_id'] as String?;
      final amountRaw = row['amount'];
      if (tingeeId == null || amountRaw == null) return;

      final amount = (amountRaw is num)
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw.toString()) ?? 0;
      if (amount == 0) return;

      final direction = row['direction'] as String? ?? 'in';
      final isIncome = direction == 'in';
      final bankCode = row['bank_code'] as String? ?? 'Bank';
      final accountMasked = row['account_number'] as String? ?? '';
      final description = row['description'] as String? ?? '';

      final occurredRaw = row['occurred_at'] as String?;
      final occurredAt = occurredRaw != null
          ? DateTime.tryParse(occurredRaw) ?? DateTime.now()
          : DateTime.now();

      await _db.pendingTransactionDao.insertOrIgnore(
        PendingTransactionsCompanion.insert(
          source: PendingTransactionSource.bankLink.name,
          sourceId: tingeeId,
          amount: amount.abs(),
          transactionType: isIncome ? 'income' : 'expense',
          title: description.isNotEmpty
              ? description
              : '$bankCode ${isIncome ? 'received' : 'spent'}',
          transactionDate: occurredAt,
          sourceDisplayName: bankCode,
          merchant: Value(_extractMerchant(description)),
          accountIdentifier: Value(accountMasked),
          rawSourceData: Value(row.toString()),
        ),
      );
    } catch (e) {
      Log.e('Insert handler failed: $e', label: _label);
    }
  }

  /// Best-effort merchant guess from the description. Bank notification
  /// content varies wildly; the AI categorizer in the pending review
  /// screen will refine this when the user opens the queue.
  String? _extractMerchant(String description) {
    if (description.isEmpty) return null;
    // Take the first comma- or hyphen-separated chunk as a rough hint.
    final parts = description.split(RegExp(r'[,\--]'));
    return parts.first.trim().isEmpty ? null : parts.first.trim();
  }
}
