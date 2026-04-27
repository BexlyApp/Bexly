import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/bank_links/domain/models/linked_bank_account.dart';

/// Streams the current user's linked bank accounts from
/// `bexly.linked_bank_accounts`. Filters to status='active'.
///
/// Returns an empty list when the user is not signed in (anonymous mode).
final linkedAccountsProvider =
    StreamProvider<List<LinkedBankAccount>>((ref) async* {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    yield const [];
    return;
  }

  // Initial fetch
  try {
    final rows = await Supabase.instance.client
        .schema('bexly')
        .from('linked_bank_accounts')
        .select()
        .eq('user_id', session.user.id)
        .eq('status', 'active')
        .order('linked_at', ascending: false);

    yield (rows as List)
        .cast<Map<String, dynamic>>()
        .map(LinkedBankAccount.fromJson)
        .toList();
  } catch (e) {
    Log.e('Failed to load linked accounts: $e', label: 'BankLinks');
    yield const [];
  }

  // TODO(tingee): subscribe to Supabase Realtime for live updates once the
  // link/unlink flow is implemented. Phase A just polls on screen open.
});
