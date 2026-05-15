import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Typed event sum type (Phase 3.4A SSE protocol)
// ---------------------------------------------------------------------------

/// Sealed base for all events yielded by [BexlyAgentService.chat].
///
/// The Bexly Agent endpoint emits Server-Sent Events in the form:
/// ```
/// event: text
/// data: {"text":"hello"}
///
/// event: tool_call
/// data: {"id":"tc_1","name":"record_transaction","args":{...}}
/// ```
/// Each SSE frame is parsed into one of the concrete sub-types below.
sealed class AgentEvent {
  const AgentEvent();
}

/// Incremental text content from the agent.
class AgentTextDelta extends AgentEvent {
  const AgentTextDelta(this.text);

  final String text;
}

/// A tool the agent invoked on the server side (already executed).
class AgentToolCall extends AgentEvent {
  const AgentToolCall({
    required this.id,
    required this.name,
    required this.args,
  });

  final String id;
  final String name;
  final Map<String, dynamic> args;
}

/// The result of a server-side tool execution.
class AgentToolResult extends AgentEvent {
  const AgentToolResult({
    required this.id,
    required this.result,
    required this.isError,
  });

  final String id;
  final Object? result;
  final bool isError;
}

/// An error reported by the agent stream.
class AgentStreamError extends AgentEvent {
  const AgentStreamError({required this.message, this.code});

  final String message;
  final String? code;
}

/// Signals the agent stream has finished normally.
class AgentStreamDone extends AgentEvent {
  const AgentStreamDone();
}

// ---------------------------------------------------------------------------
// SSE frame parser (top-level so it can be tested with @visibleForTesting)
// ---------------------------------------------------------------------------

/// Parses a single SSE frame (the text between two blank lines) into a typed
/// [AgentEvent].  Returns `null` for empty, comment-only, or malformed frames.
///
/// Frame format expected from the Bexly Agent (Phase 3.4A):
/// ```
/// event: <type>
/// data: <json>
/// ```
@visibleForTesting
AgentEvent? parseSseFrame(String frame) {
  String? eventType;
  String? dataLine;

  for (final line in frame.split('\n')) {
    if (line.startsWith('event:')) {
      eventType = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final chunk = line.substring(5).trim();
      dataLine = dataLine == null ? chunk : '$dataLine\n$chunk';
    }
  }

  if (eventType == null || dataLine == null) return null;

  try {
    final data = jsonDecode(dataLine);
    switch (eventType) {
      case 'text':
        return AgentTextDelta((data as Map)['text'] as String? ?? '');
      case 'tool_call':
        final m = data as Map;
        return AgentToolCall(
          id: m['id'] as String,
          name: m['name'] as String,
          args: ((m['args'] as Map?) ?? const {}).cast<String, dynamic>(),
        );
      case 'tool_result':
        final m = data as Map;
        return AgentToolResult(
          id: m['id'] as String,
          result: m['result'],
          isError: m['isError'] == true,
        );
      case 'error':
        final m = data as Map;
        return AgentStreamError(
          message: m['message'] as String? ?? 'Unknown agent error',
          code: m['code'] as String?,
        );
      case 'done':
        return const AgentStreamDone();
    }
  } catch (_) {
    return null;
  }

  return null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Calls Bexly Agent's `/api/agent/chat` and yields typed [AgentEvent]s
/// parsed from the Server-Sent Events stream the endpoint emits (Phase 3.4A).
///
/// Phase history:
/// - Phase 3.1: plain-text streaming, `Stream<String>`.
/// - Phase 3.4B (this): structured SSE, `Stream<AgentEvent>`.
class BexlyAgentService {
  static const _label = 'BexlyAgentService';
  static const _baseUrl = String.fromEnvironment(
    'BEXLY_AGENT_URL',
    defaultValue: 'https://api.bexly.app',
  );

  /// Streams [AgentEvent]s from the Bexly Agent for [message].
  ///
  /// Throws [BexlyAgentAuthException] if there is no active session or if the
  /// server returns 401/403.  Throws [BexlyAgentException] for other HTTP
  /// errors.  Individual stream errors from the agent are emitted as
  /// [AgentStreamError] events rather than thrown, unless they are fatal
  /// connection errors.
  Stream<AgentEvent> chat({
    required String message,
    String? threadId,
    String locale = 'vi',
  }) async* {
    // Defensive session access - Supabase.instance can throw on cold-start
    // race or hot-restart before initialization completes.
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
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode({
          'message': message,
          if (threadId != null) 'threadId': threadId,
          'locale': locale,
        });

      final streamed = await client.send(req).timeout(const Duration(seconds: 120));

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

      // Parse SSE stream: frames are separated by a blank line (\n\n).
      // Each frame contains `event: <type>` and `data: <json>` lines.
      var buffer = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final sep = buffer.indexOf('\n\n');
          if (sep < 0) break;
          final frame = buffer.substring(0, sep);
          buffer = buffer.substring(sep + 2);
          final event = parseSseFrame(frame);
          if (event != null) yield event;
        }
      }
    } finally {
      client.close();
    }
  }
}
