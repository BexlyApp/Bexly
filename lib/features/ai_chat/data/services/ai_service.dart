import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/ai_chat/data/config/ai_prompts.dart';

abstract class AIService {
  Future<String> sendMessage(String message);
  Stream<String> sendMessageStream(String message);
  void updateRecentTransactions(String recentTransactionsContext);
}

/// Mixin for shared prompt generation logic across AI services
mixin AIServicePromptMixin {
  List<String> get categories;
  String get recentTransactionsContext;

  /// Build complete system prompt using centralized config
  String get systemPrompt => AIPrompts.buildSystemPrompt(
        categories: categories,
        recentTransactionsContext: recentTransactionsContext,
      );

  // Legacy getters for backwards compatibility (all delegate to AIPrompts)
  String get systemInstruction => AIPrompts.systemInstruction;
  String get contextSection => AIPrompts.buildContextSection(categories);
  String get amountParsingRules => AIPrompts.amountParsingRules;
  String get actionSchemas => AIPrompts.actionSchemas;
  String get businessRules => AIPrompts.businessRules;
  String get exampleSection => AIPrompts.examples;
  String get recentTransactionsSection =>
      AIPrompts.buildRecentTransactionsSection(recentTransactionsContext);
}

class OpenAIService with AIServicePromptMixin implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;

  @override
  final List<String> categories;

  String _recentTransactionsContext = '';

  @override
  String get recentTransactionsContext => _recentTransactionsContext;

  OpenAIService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.categories = const [],
  }) {
    Log.d('OpenAIService initialized with model: $model, categories: ${categories.length}', label: 'AI Service');
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'AI Service');
  }

  // All prompts are now managed by AIServicePromptMixin which delegates to AIPrompts config

  @override
  Future<String> sendMessage(String message) async {
    try {
      Log.d('Sending message to OpenAI: $message', label: 'OpenAI Service');

      // Better API key validation and logging
      if (apiKey == 'USER_MUST_PROVIDE_API_KEY' || apiKey.isEmpty) {
        throw Exception('No API key configured. Please add OPENAI_API_KEY to your .env file.');
      }

      // Validate API key format (should start with sk-)
      if (!apiKey.startsWith('sk-')) {
        Log.e('Invalid API key format. OpenAI keys should start with "sk-"', label: 'OpenAI Service');
      }

      final maskedKey = apiKey.length > 10
          ? '${apiKey.substring(0, 7)}...${apiKey.substring(apiKey.length - 4)}'
          : 'Invalid key';
      Log.d('Using API key: $maskedKey', label: 'OpenAI Service');

      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          // Force deterministic output for schema adherence
          'temperature': 0,
          // Encourage JSON structure even if not strict JSON mode
          'response_format': { 'type': 'text' },
          'max_tokens': 500,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              Log.e('OpenAI API request timed out after 30 seconds', label: 'OpenAI Service');
              throw Exception('Request timed out. Please check your internet connection and try again.');
            },
          );

      Log.d('OpenAI Response status: ${response.statusCode}', label: 'OpenAI Service');
      Log.d('OpenAI Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}', label: 'OpenAI Service');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'];
          Log.d('OpenAI Response content: $content', label: 'OpenAI Service');
          return content.trim();
        } catch (e) {
          Log.e('Failed to parse OpenAI response as JSON: $e', label: 'OpenAI Service');
          Log.e('Response body: ${response.body}', label: 'OpenAI Service');
          throw Exception('Invalid response format from OpenAI API. Response was not valid JSON.');
        }
      } else {
        Log.e('OpenAI API error: ${response.statusCode} - ${response.body}', label: 'OpenAI Service');

        // Parse error details for better user feedback
        String errorMessage = 'API Error';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error']['message'] ?? 'Unknown error';
          }
        } catch (_) {
          errorMessage = 'API Error: ${response.statusCode}';
        }

        // Check for specific error codes
        if (response.statusCode == 401) {
          throw Exception('Invalid API key. Please check your OpenAI API key.');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode == 500 || response.statusCode == 503) {
          throw Exception('OpenAI service is temporarily unavailable. Please try again later.');
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      Log.e('Error calling OpenAI API: $e', label: 'OpenAI Service');
      throw e;
    }
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    // For now, just use non-streaming version
    // TODO: Implement SSE streaming later
    final response = await sendMessage(message);
    yield response;
  }
}

class GeminiService with AIServicePromptMixin implements AIService {
  final String apiKey;
  final String model;

  @override
  final List<String> categories;

  String _recentTransactionsContext = '';

  @override
  String get recentTransactionsContext => _recentTransactionsContext;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.categories = const [],
  }) {
    Log.d('GeminiService initialized with model: $model, categories: ${categories.length}', label: 'AI Service');
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'AI Service');
  }

  // All prompts are now managed by AIServicePromptMixin which delegates to AIPrompts config

  @override
  Future<String> sendMessage(String message) async {
    try {
      Log.d('Sending message to Gemini: $message', label: 'Gemini Service');

      // Validate API key
      if (apiKey.isEmpty || apiKey == 'USER_MUST_PROVIDE_API_KEY') {
        throw Exception('No Gemini API key configured. Please add GEMINI_API_KEY to your .env file.');
      }

      // Create model with system instruction (cached, not counted in tokens!)
      final modelWithSystemPrompt = GenerativeModel(
        model: model,
        apiKey: apiKey,
        systemInstruction: Content.text(systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );

      // Create chat (no history needed, system instruction is separate)
      final chat = modelWithSystemPrompt.startChat();

      // Send user message
      final response = await chat.sendMessage(
        Content.text(message),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Log.e('Gemini API request timed out after 30 seconds', label: 'Gemini Service');
          throw Exception('Request timed out. Please check your internet connection and try again.');
        },
      );

      final content = response.text ?? '';
      Log.d('Gemini Response content: $content', label: 'Gemini Service');

      return content.trim();
    } catch (e) {
      Log.e('Error calling Gemini API: $e', label: 'Gemini Service');
      
      // Parse error for user-friendly message
      String userFriendlyMessage = 'Sorry, an error occurred with Gemini AI.';
      
      if (e.toString().contains('API key')) {
        userFriendlyMessage = 'Invalid Gemini API key. Please check your configuration.';
      } else if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        userFriendlyMessage = 'Gemini API quota exceeded. Please try again later.';
      } else if (e.toString().contains('timeout')) {
        userFriendlyMessage = 'Request timed out. Please check your internet connection.';
      }
      
      throw Exception(userFriendlyMessage);
    }
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    // For now, just use non-streaming version
    // TODO: Implement streaming later if needed
    final response = await sendMessage(message);
    yield response;
  }
}
