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
  void updateBudgetsContext(String budgetsContext); // Update budgets list for AI
  void updateContext({
    String? walletName,
    String? walletCurrency,
    List<String>? wallets,
    double? exchangeRate,
  }); // Update wallet context dynamically
  void clearHistory(); // Clear conversation history
}

/// Mixin for shared prompt generation logic across AI services
mixin AIServicePromptMixin {
  List<String> get categories;
  String get recentTransactionsContext;
  String get budgetsContext; // Current budgets for AI context
  String? get categoryHierarchy => null; // Optional hierarchy text
  String? get walletCurrency => null; // Optional wallet currency for conversion notification
  String? get walletName => null; // Optional wallet name for personalized responses
  double? get exchangeRateVndToUsd => null; // Optional exchange rate VND to USD
  List<String>? get wallets => null; // Optional list of available wallets

  /// Build complete system prompt using centralized config
  String get systemPrompt => AIPrompts.buildSystemPrompt(
        categories: categories,
        recentTransactionsContext: recentTransactionsContext,
        categoryHierarchy: categoryHierarchy,
        walletCurrency: walletCurrency,
        walletName: walletName,
        exchangeRateVndToUsd: exchangeRateVndToUsd,
        wallets: wallets,
        budgetsContext: budgetsContext,
      );

  // Legacy getters for backwards compatibility (all delegate to AIPrompts)
  String get systemInstruction => AIPrompts.systemInstruction;
  String get contextSection => AIPrompts.buildContextSection(categories, categoryHierarchy: categoryHierarchy, wallets: wallets);
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

  @override
  final String? categoryHierarchy;

  @override
  String? walletCurrency;

  @override
  String? walletName;

  @override
  double? exchangeRateVndToUsd;

  @override
  List<String>? wallets;

  String _recentTransactionsContext = '';
  String _budgetsContext = '';

  @override
  String get recentTransactionsContext => _recentTransactionsContext;

  @override
  String get budgetsContext => _budgetsContext;

  // Conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

  OpenAIService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.categories = const [],
    this.categoryHierarchy,
    this.walletCurrency,
    this.walletName,
    this.exchangeRateVndToUsd,
    this.wallets,
  }) {
    Log.d('OpenAIService initialized with model: $model, categories: ${categories.length}, wallet: "$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}', label: 'AI Service');
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'AI Service');
  }

  @override
  void updateBudgetsContext(String budgetsContext) {
    _budgetsContext = budgetsContext;
    Log.d('Updated budgets context (${budgetsContext.length} chars)', label: 'AI Service');
  }

  @override
  void updateContext({
    String? walletName,
    String? walletCurrency,
    List<String>? wallets,
    double? exchangeRate,
  }) {
    if (walletName != null) this.walletName = walletName;
    if (walletCurrency != null) this.walletCurrency = walletCurrency;
    if (wallets != null) this.wallets = wallets;
    if (exchangeRate != null) exchangeRateVndToUsd = exchangeRate;

    Log.d('✅ Updated AI context: wallet="$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}, exchangeRate: $exchangeRate → stored: $exchangeRateVndToUsd', label: 'AI Service');
    if (wallets != null && wallets.isNotEmpty) {
      Log.d('   Wallet list: ${wallets.join(", ")}', label: 'AI Service');
    }
  }

  @override
  void clearHistory() {
    _conversationHistory.clear();
    Log.d('Conversation history cleared', label: 'AI Service');
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

      // Build messages array with history
      final messages = [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        ..._conversationHistory, // Include previous messages
        {
          'role': 'user',
          'content': message,
        }
      ];

      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
          'model': model,
          'messages': messages,
          // Lower temperature for more focused responses
          'temperature': 0.3,
          // Encourage JSON structure even if not strict JSON mode
          'response_format': { 'type': 'text' },
          'max_tokens': 2000, // Increased for reasoning + JSON
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

          // Save conversation to history
          _conversationHistory.add({
            'role': 'user',
            'content': message,
          });
          _conversationHistory.add({
            'role': 'assistant',
            'content': content,
          });

          Log.d('Conversation history updated (${_conversationHistory.length} messages)', label: 'AI Service');

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

  @override
  final String? categoryHierarchy;

  @override
  String? walletCurrency;

  @override
  String? walletName;

  @override
  double? exchangeRateVndToUsd;

  @override
  List<String>? wallets;

  String _recentTransactionsContext = '';
  String _budgetsContext = '';

  @override
  String get recentTransactionsContext => _recentTransactionsContext;

  @override
  String get budgetsContext => _budgetsContext;

  // Conversation history for context (using Gemini's Content format)
  final List<Content> _conversationHistory = [];

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.categories = const [],
    this.categoryHierarchy,
    this.walletCurrency,
    this.walletName,
    this.exchangeRateVndToUsd,
    this.wallets,
  }) {
    Log.d('GeminiService initialized with model: $model, categories: ${categories.length}, wallet: "$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}', label: 'AI Service');
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'Gemini Service');
  }

  @override
  void updateBudgetsContext(String budgetsContext) {
    _budgetsContext = budgetsContext;
    Log.d('Updated budgets context (${budgetsContext.length} chars)', label: 'Gemini Service');
  }

  @override
  void updateContext({
    String? walletName,
    String? walletCurrency,
    List<String>? wallets,
    double? exchangeRate,
  }) {
    if (walletName != null) this.walletName = walletName;
    if (walletCurrency != null) this.walletCurrency = walletCurrency;
    if (wallets != null) this.wallets = wallets;
    if (exchangeRate != null) exchangeRateVndToUsd = exchangeRate;

    Log.d('✅ Updated AI context: wallet="$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}, exchangeRate: $exchangeRate → stored: $exchangeRateVndToUsd', label: 'AI Service');
    if (wallets != null && wallets.isNotEmpty) {
      Log.d('   Wallet list: ${wallets.join(", ")}', label: 'AI Service');
    }
  }

  @override
  void clearHistory() {
    _conversationHistory.clear();
    Log.d('Conversation history cleared', label: 'AI Service');
  }

  // All prompts are now managed by AIServicePromptMixin which delegates to AIPrompts config

  // Retry helper with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        if (attempt > 1) {
          Log.d('🔄 Retry attempt $attempt/$maxRetries', label: 'Gemini Service');
        }
        return await operation();
      } catch (e) {
        // Don't retry on these errors
        if (e.toString().contains('API key') ||
            e.toString().contains('quota') ||
            attempt >= maxRetries) {
          rethrow;
        }

        // Retry on network/timeout errors
        if (attempt < maxRetries) {
          Log.w('⚠️ Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms...', label: 'Gemini Service');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
  }

  Future<String> _sendMessageInternal(String message) async {
    Log.d('🔵 === GEMINI API CALL START ===', label: 'Gemini Service');
    Log.d('🔵 User input: "$message"', label: 'Gemini Service');
    Log.d('🔵 Input length: ${message.length} characters', label: 'Gemini Service');
    Log.d('🔵 Input encoding (first 50 chars): ${message.length > 50 ? message.substring(0, 50).codeUnits : message.codeUnits}', label: 'Gemini Service');

    // Log if Chinese characters detected
    final hasChinese = message.contains(RegExp(r'[\u4e00-\u9fa5]'));
    final hasJapanese = message.contains(RegExp(r'[\u3040-\u309f\u30a0-\u30ff]'));
    if (hasChinese) {
      Log.d('🔍 Chinese characters detected in input', label: 'Gemini Service');
    }
    if (hasJapanese) {
      Log.d('🔍 Japanese characters detected in input', label: 'Gemini Service');
    }

    // Validate API key
    if (apiKey.isEmpty || apiKey == 'USER_MUST_PROVIDE_API_KEY') {
      throw Exception('No Gemini API key configured. Please add GEMINI_API_KEY to your .env file.');
    }

    // Log system prompt for debugging
    Log.d('System Prompt:\n$systemPrompt', label: 'Gemini Service');
    print('====== SYSTEM PROMPT DEBUG ======');
    print(systemPrompt);
    print('=================================');

    // Create model with system instruction (cached, not counted in tokens!)
    final modelWithSystemPrompt = GenerativeModel(
      model: model,
      apiKey: apiKey,
      systemInstruction: Content.text(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temp for more focused responses
        maxOutputTokens: 2000, // Increase limit for reasoning + JSON
      ),
    );

    // Create chat with conversation history
    final chat = modelWithSystemPrompt.startChat(history: _conversationHistory);

    Log.d('Starting chat with ${_conversationHistory.length} previous messages', label: 'Gemini Service');

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

    // FORCE print for debugging - works in release mode
    print('========== GEMINI RAW RESPONSE ==========');
    print(content);
    print('=========================================');

    // Save conversation to history
    _conversationHistory.add(Content.text(message)); // User message
    _conversationHistory.add(Content.model([TextPart(content)])); // AI response

    Log.d('Conversation history updated (${_conversationHistory.length} messages)', label: 'AI Service');

    return content.trim();
  }

  @override
  Future<String> sendMessage(String message) async {
    try {
      return await _retryWithBackoff(
        () => _sendMessageInternal(message),
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 500),
      );
    } catch (e, stackTrace) {
      Log.e('❌ Error calling Gemini API: $e', label: 'Gemini Service');
      Log.e('❌ Stack trace: $stackTrace', label: 'Gemini Service');
      Log.e('❌ Error type: ${e.runtimeType}', label: 'Gemini Service');
      Log.e('❌ Error toString: ${e.toString()}', label: 'Gemini Service');

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
