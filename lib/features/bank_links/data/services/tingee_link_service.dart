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
    final body = await _call({'action': 'list_banks'});
    final raw = (body is Map && body['data'] is List)
        ? body['data'] as List
        : (body is List ? body : const []);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TingeeBank.fromJson)
        .where((b) => b.code.isNotEmpty)
        .toList();
  }

  /// Step 1 of linking: send account info to Tingee, returns confirmId.
  Future<TingeeStepResult> createVa({
    required String bankBin,
    required String accountNumber,
    required String accountName,
    required String identity,
    required String mobile,
    String accountType = 'personal-account',
    String? label,
  }) async {
    final body = await _call({
      'action': 'create_va',
      'bankBin': bankBin,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'identity': identity,
      'mobile': mobile,
      'accountType': accountType,
      if (label != null) 'label': label,
    });
    return TingeeStepResult.fromJson(body as Map<String, dynamic>);
  }

  /// Step 2 of linking: confirm with OTP. Edge Function persists the local
  /// linked_bank_accounts row + auto-fires register_notify on success.
  Future<TingeeStepResult> confirmVa({
    required String bankBin,
    required String confirmId,
    String? otpNumber,
  }) async {
    final body = await _call({
      'action': 'confirm_va',
      'bankBin': bankBin,
      'confirmId': confirmId,
      if (otpNumber != null) 'otpNumber': otpNumber,
    });
    return TingeeStepResult.fromJson(body as Map<String, dynamic>);
  }

  /// Confirm the register-notify step explicitly (gateway auto-fires
  /// register-notify after confirm-va; OTP for it goes here if Tingee
  /// requests one).
  Future<TingeeStepResult> confirmRegisterNotify({
    required String bankBin,
    required String confirmId,
    String? otpNumber,
  }) async {
    final body = await _call({
      'action': 'confirm_register_notify',
      'bankBin': bankBin,
      'confirmId': confirmId,
      if (otpNumber != null) 'otpNumber': otpNumber,
    });
    return TingeeStepResult.fromJson(body as Map<String, dynamic>);
  }

  /// Begin unlinking — returns confirmId.
  Future<TingeeStepResult> deleteVa({
    required String bankBin,
    required String vaAccountNumber,
  }) async {
    final body = await _call({
      'action': 'delete_va',
      'bankBin': bankBin,
      'vaAccountNumber': vaAccountNumber,
    });
    return TingeeStepResult.fromJson(body as Map<String, dynamic>);
  }

  /// Confirm unlink — Edge Function flips linked_bank_accounts.status to 'unlinked'.
  Future<TingeeStepResult> confirmDeleteVa({
    required String bankBin,
    required String confirmId,
    required String vaAccountNumber,
    String? otpNumber,
  }) async {
    final body = await _call({
      'action': 'confirm_delete_va',
      'bankBin': bankBin,
      'confirmId': confirmId,
      'vaAccountNumber': vaAccountNumber,
      if (otpNumber != null) 'otpNumber': otpNumber,
    });
    return TingeeStepResult.fromJson(body as Map<String, dynamic>);
  }

  Future<dynamic> _call(Map<String, dynamic> body) async {
    final headers = _authHeaders();
    if (headers == null) {
      throw StateError('Bạn cần đăng nhập để liên kết tài khoản ngân hàng.');
    }

    final res = await http
        .post(
          Uri.parse(_endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(res.body);
    if (res.statusCode != 200) {
      Log.e('${body['action']} ${res.statusCode}: ${res.body}', label: _label);
      final msg = (decoded is Map && decoded['message'] is String)
          ? decoded['message'] as String
          : 'Tingee request failed (${res.statusCode}).';
      throw Exception(msg);
    }
    return decoded;
  }
}

/// Common shape for Tingee multi-step responses ({ code, message, data }).
class TingeeStepResult {
  final String code;
  final String? message;
  final Map<String, dynamic>? data;

  const TingeeStepResult({
    required this.code,
    this.message,
    this.data,
  });

  bool get isOk => code == '00';
  String? get confirmId => data?['confirmId'] as String?;
  String? get vaAccountNumber => data?['vaAccountNumber'] as String?;

  factory TingeeStepResult.fromJson(Map<String, dynamic> json) {
    return TingeeStepResult(
      code: (json['code'] ?? 'unknown') as String,
      message: json['message'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
