import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/core/utils/logger.dart';

/// Lightweight AI service for background tasks (transaction parsing, duplicate check).
///
/// Uses the same provider as the main AI chat (Custom/DOS.AI, Gemini, OpenAI)
/// based on LLMDefaultConfig settings. No conversation history or system prompts.
///
/// OpenAI and Gemini go through the Supabase Edge Function proxy (server-side keys).
/// Custom/DOS.AI calls the endpoint directly (already server-side).
class BackgroundAIService {
  static const String _label = 'BackgroundAI';

  /// Send a prompt and get a text response.
  /// Returns null on failure.
  Future<String?> complete(String prompt, {int? maxTokens}) async {
    final provider = LLMDefaultConfig.providerEnum;

    try {
      switch (provider) {
        case AIProvider.custom:
          return await _completeViaDirect(
            endpoint: LLMDefaultConfig.customEndpoint,
            apiKey: LLMDefaultConfig.customApiKey,
            model: LLMDefaultConfig.customModel,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
            timeoutSeconds: LLMDefaultConfig.customTimeoutSeconds,
          );
        case AIProvider.gemini:
          return await _completeViaProxy(
            provider: 'gemini',
            model: LLMDefaultConfig.geminiModel,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
          );
        case AIProvider.openai:
          return await _completeViaProxy(
            provider: 'openai',
            model: LLMDefaultConfig.model,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
          );
      }
    } catch (e) {
      Log.w('Primary provider ($provider) failed: $e', label: _label);

      // Fallback: if primary was custom/openai, try Gemini via proxy
      if (provider != AIProvider.gemini) {
        try {
          Log.d('Falling back to Gemini via proxy for background task', label: _label);
          return await _completeViaProxy(
            provider: 'gemini',
            model: LLMDefaultConfig.geminiModel,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
          );
        } catch (e2) {
          Log.w('Gemini fallback also failed: $e2', label: _label);
        }
      }

      return null;
    }
  }

  /// Completion via Supabase Edge Function proxy (for OpenAI, Gemini)
  Future<String?> _completeViaProxy({
    required String provider,
    required String model,
    required String prompt,
    required int maxTokens,
  }) async {
    final token = LLMDefaultConfig.proxyAccessToken;
    if (token == null) {
      throw Exception('Not authenticated — cannot use AI proxy for background tasks.');
    }

    final response = await http
        .post(
          Uri.parse(LLMDefaultConfig.proxyUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'provider': provider,
            'action': 'chat',
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Background AI request timed out after 30s');
          },
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) throw Exception(data['error']);
      return (data['content'] as String?)?.trim();
    }

    Log.w('Background AI HTTP ${response.statusCode}: ${response.body}', label: _label);
    throw Exception('Background AI error: ${response.statusCode}');
  }

  /// Direct OpenAI-compatible completion (for Custom/DOS.AI, vLLM, Ollama)
  Future<String?> _completeViaDirect({
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
    required int maxTokens,
    required int timeoutSeconds,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'Bexly/1.0 (Dart; Flutter)',
      'Accept': 'application/json',
    };
    if (apiKey.isNotEmpty && apiKey != 'no-key-required') {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http
        .post(
          Uri.parse('$endpoint/chat/completions'),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': maxTokens,
            // Disable Qwen3/3.5 thinking mode for faster responses
            'chat_template_kwargs': {'enable_thinking': false},
          }),
        )
        .timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw Exception('Background AI request timed out after ${timeoutSeconds}s');
          },
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String?;
      return content?.trim();
    }

    Log.w('Background AI HTTP ${response.statusCode}: ${response.body}', label: _label);
    throw Exception('Background AI error: ${response.statusCode}');
  }

  /// Check if any AI provider is available for background tasks
  static bool get isAvailable {
    final provider = LLMDefaultConfig.providerEnum;
    switch (provider) {
      case AIProvider.custom:
        // Custom always has default endpoint (Bexly Free AI)
        return true;
      case AIProvider.gemini:
      case AIProvider.openai:
        // Need auth token for proxy
        return LLMDefaultConfig.proxyAccessToken != null;
    }
  }
}
