import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/utils/logger.dart';

class BexlyAgentException implements Exception {
  BexlyAgentException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'BexlyAgentException(${statusCode ?? "?"}): $message';
}

class BexlyAgentAuthException extends BexlyAgentException {
  BexlyAgentAuthException(super.message) : super(statusCode: 401);
}

/// Calls Bexly Agent's `/api/agent/chat` and streams plain-text chunks.
///
/// Phase 3.1 ships text-only streaming (no Vercel AI SDK protocol). Tool calls
/// execute server-side and surface as part of the agent reply. Phase 3.4 will
/// switch to structured event streaming so the mobile can render action
/// confirmation cards inline.
class BexlyAgentService {
  static const _label = 'BexlyAgentService';
  static const _baseUrl = String.fromEnvironment(
    'BEXLY_AGENT_URL',
    defaultValue: 'https://bexly-agent.dos.ai',
  );

  Stream<String> chat({
    required String message,
    String? threadId,
    String locale = 'vi',
  }) async* {
    // Wrap currentSession access defensively - Supabase.instance throws if
    // not initialized (hot-restart edge case, cold-start race). Treat as
    // "no session" rather than crashing the chat flow.
    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }
    if (session == null) {
      throw BexlyAgentAuthException('Cannot chat: no active session.');
    }

    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse('$_baseUrl/api/agent/chat'))
        ..headers['Authorization'] = 'Bearer ${session.accessToken}'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'message': message,
          if (threadId != null) 'threadId': threadId,
          'locale': locale,
        });

      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 120));

      if (streamed.statusCode == 401 || streamed.statusCode == 403) {
        final body = await streamed.stream.bytesToString();
        Log.w('agent ${streamed.statusCode}: $body', label: _label);
        throw BexlyAgentAuthException('JWT invalid - please re-login.');
      }
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        Log.e('agent ${streamed.statusCode}: $body', label: _label);
        throw BexlyAgentException(
          'Agent error ${streamed.statusCode}: $body',
          statusCode: streamed.statusCode,
        );
      }

      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        if (chunk.isNotEmpty) yield chunk;
      }
    } finally {
      client.close();
    }
  }
}
