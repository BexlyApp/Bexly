import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/core/utils/logger.dart';

/// Lightweight AI service for background tasks (transaction parsing, duplicate check).
///
/// Uses the same provider as the main AI chat (Custom/DOS.AI, Gemini, OpenAI)
/// based on LLMDefaultConfig settings. No conversation history or system prompts.
class BackgroundAIService {
  static const String _label = 'BackgroundAI';

  /// Send a prompt and get a text response.
  /// Returns null on failure.
  Future<String?> complete(String prompt, {int? maxTokens}) async {
    final provider = LLMDefaultConfig.providerEnum;

    try {
      switch (provider) {
        case AIProvider.custom:
          return await _completeViaOpenAICompatible(
            endpoint: LLMDefaultConfig.customEndpoint,
            apiKey: LLMDefaultConfig.customApiKey,
            model: LLMDefaultConfig.customModel,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
            timeoutSeconds: LLMDefaultConfig.customTimeoutSeconds,
          );
        case AIProvider.gemini:
          return await _completeViaGemini(prompt, maxTokens: maxTokens ?? 500);
        case AIProvider.openai:
          return await _completeViaOpenAICompatible(
            endpoint: 'https://api.openai.com/v1',
            apiKey: LLMDefaultConfig.apiKey,
            model: LLMDefaultConfig.model,
            prompt: prompt,
            maxTokens: maxTokens ?? 500,
            timeoutSeconds: 30,
          );
      }
    } catch (e) {
      Log.w('Primary provider ($provider) failed: $e', label: _label);

      // Fallback: if primary was custom/openai and Gemini key exists, try Gemini
      if (provider != AIProvider.gemini && LLMDefaultConfig.geminiApiKey.isNotEmpty) {
        try {
          Log.d('Falling back to Gemini for background task', label: _label);
          return await _completeViaGemini(prompt, maxTokens: maxTokens ?? 500);
        } catch (e2) {
          Log.w('Gemini fallback also failed: $e2', label: _label);
        }
      }

      return null;
    }
  }

  /// OpenAI-compatible completion (works for Custom/DOS.AI, OpenAI, vLLM, Ollama)
  Future<String?> _completeViaOpenAICompatible({
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
    required int maxTokens,
    required int timeoutSeconds,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
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

  /// Gemini completion via google_generative_ai package
  Future<String?> _completeViaGemini(String prompt, {required int maxTokens}) async {
    final apiKey = LLMDefaultConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    final model = GenerativeModel(
      model: LLMDefaultConfig.geminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: maxTokens,
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Gemini background request timed out');
      },
    );

    return response.text?.trim();
  }

  /// Check if any AI provider is available for background tasks
  static bool get isAvailable {
    final provider = LLMDefaultConfig.providerEnum;
    switch (provider) {
      case AIProvider.custom:
        // Custom always has default endpoint (Bexly Free AI)
        return true;
      case AIProvider.gemini:
        return LLMDefaultConfig.geminiApiKey.isNotEmpty;
      case AIProvider.openai:
        return LLMDefaultConfig.apiKey.isNotEmpty;
    }
  }
}
