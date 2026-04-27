import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/bank_links/domain/models/tingee_bank.dart';

/// Calls the `tingee-link` Edge Function. The function holds the Tingee
/// secret and proxies HMAC-signed requests upstream — the client never
/// touches the secret.
class TingeeLinkService {
  static const _label = 'TingeeLink';

  String get _endpoint =>
      '${SupabaseConfig.url}/functions/v1/tingee-link';

  Map<String, String>? _authHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// Fetch the list of banks Tingee supports.
  Future<List<TingeeBank>> listBanks() async {
    final headers = _authHeaders();
    if (headers == null) {
      throw StateError('Bạn cần đăng nhập để liên kết tài khoản ngân hàng.');
    }

    final res = await http
        .post(
          Uri.parse(_endpoint),
          headers: headers,
          body: jsonEncode({'action': 'list_banks'}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      Log.e('list_banks ${res.statusCode}: ${res.body}', label: _label);
      throw Exception('Không tải được danh sách ngân hàng (${res.statusCode}).');
    }

    final body = jsonDecode(res.body);
    final raw = (body is Map && body['data'] is List)
        ? body['data'] as List
        : (body is List ? body : const []);

    return raw
        .whereType<Map<String, dynamic>>()
        .map(TingeeBank.fromJson)
        .where((b) => b.code.isNotEmpty)
        .toList();
  }
}
