import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
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
  String get modelName; // Get current model name for display
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

  @override
  String get modelName => model;

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
      Log.d('Sending message to OpenAI via proxy: $message', label: 'OpenAI Service');

      final headers = LLMDefaultConfig.proxyHeaders;
      if (headers == null) {
        throw Exception('Not authenticated — cannot use AI proxy. Please sign in first.');
      }

      // Build messages array with history
      final messages = [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        ..._conversationHistory,
        {
          'role': 'user',
          'content': message,
        }
      ];

      final response = await http
          .post(
            Uri.parse(LLMDefaultConfig.proxyUrl),
            headers: headers,
            body: jsonEncode({
              'provider': 'openai',
              'action': 'chat',
              'model': model,
              'messages': messages,
              'temperature': 0.3,
              'max_tokens': 2000,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timed out. Please check your internet connection and try again.');
            },
          );

      Log.d('Proxy Response status: ${response.statusCode}', label: 'OpenAI Service');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) throw Exception(data['error']);
        final content = data['content'] as String;

        _conversationHistory.add({'role': 'user', 'content': message});
        _conversationHistory.add({'role': 'assistant', 'content': content});

        return content.trim();
      } else {
        final data = jsonDecode(response.body);
        final error = data['error'] ?? 'API Error: ${response.statusCode}';
        throw Exception(error);
      }
    } catch (e) {
      Log.e('Error calling OpenAI via proxy: $e', label: 'OpenAI Service');
      rethrow;
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

  @override
  String get modelName => model;

  // Conversation history (OpenAI-compatible format, proxy handles translation)
  final List<Map<String, String>> _conversationHistory = [];

  GeminiService({
    required this.apiKey,
    String? model,
    this.categories = const [],
    this.categoryHierarchy,
    this.walletCurrency,
    this.walletName,
    this.exchangeRateVndToUsd,
    this.wallets,
  }) : model = model ?? LLMDefaultConfig.geminiModel {
    Log.d('GeminiService initialized with model: ${this.model}, categories: ${categories.length}, wallet: "$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}', label: 'AI Service');
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
    Log.d('Sending message to Gemini via proxy: $message', label: 'Gemini Service');

    final headers = LLMDefaultConfig.proxyHeaders;
    if (headers == null) {
      throw Exception('Not authenticated — cannot use AI proxy. Please sign in first.');
    }

    // Build messages array with history (OpenAI-compatible format)
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._conversationHistory,
      {'role': 'user', 'content': message},
    ];

    Log.d('Starting chat with ${_conversationHistory.length} previous messages', label: 'Gemini Service');

    final response = await http
        .post(
          Uri.parse(LLMDefaultConfig.proxyUrl),
          headers: headers,
          body: jsonEncode({
            'provider': 'gemini',
            'action': 'chat',
            'model': model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 2000,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out. Please check your internet connection and try again.');
          },
        );

    Log.d('Proxy Response status: ${response.statusCode}', label: 'Gemini Service');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) throw Exception(data['error']);
      final content = data['content'] as String;

      _conversationHistory.add({'role': 'user', 'content': message});
      _conversationHistory.add({'role': 'assistant', 'content': content});

      return content.trim();
    } else {
      final data = jsonDecode(response.body);
      final error = data['error'] ?? 'API Error: ${response.statusCode}';
      throw Exception(error);
    }
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

/// Custom LLM Service for self-hosted models (vLLM, Ollama, etc.)
/// Uses OpenAI-compatible API format
class CustomLLMService with AIServicePromptMixin implements AIService {
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

  @override
  String get modelName => model;

  // Conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

  CustomLLMService({
    required this.baseUrl,
    this.apiKey = 'no-key-required',
    this.model = 'default',
    this.categories = const [],
    this.categoryHierarchy,
    this.walletCurrency,
    this.walletName,
    this.exchangeRateVndToUsd,
    this.wallets,
  }) {
    Log.d('CustomLLMService initialized with endpoint: $baseUrl, model: $model, categories: ${categories.length}', label: 'AI Service');
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'Custom LLM');
  }

  @override
  void updateBudgetsContext(String budgetsContext) {
    _budgetsContext = budgetsContext;
    Log.d('Updated budgets context (${budgetsContext.length} chars)', label: 'Custom LLM');
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

    Log.d('✅ Updated AI context: wallet="$walletName" ($walletCurrency)', label: 'Custom LLM');
  }

  @override
  void clearHistory() {
    _conversationHistory.clear();
    Log.d('Conversation history cleared', label: 'Custom LLM');
  }

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
          Log.d('🔄 Retry attempt $attempt/$maxRetries', label: 'Custom LLM');
        }
        return await operation();
      } catch (e) {
        // Don't retry on API key, quota, or timeout errors
        if (e.toString().contains('API key') ||
            e.toString().contains('quota') ||
            e.toString().contains('DOS_AI_TIMEOUT') ||
            attempt >= maxRetries) {
          rethrow;
        }

        // Retry on timeout/network errors
        if (attempt < maxRetries) {
          Log.w('⚠️ Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms...', label: 'Custom LLM');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
  }

  Future<String> _sendMessageInternal(String message) async {
    Log.d('Sending message to Custom LLM ($baseUrl): $message', label: 'Custom LLM');

    // Build messages array with history
    final messages = [
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ..._conversationHistory,
      {
        'role': 'user',
        'content': message,
      }
    ];

    // Prepare headers
    // User-Agent is REQUIRED - Cloudflare WAF blocks requests without a proper UA
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'Bexly/1.0 (Dart; Flutter)',
      'Accept': 'application/json',
    };

    // Add Authorization header if API key is provided
    if (apiKey.isNotEmpty && apiKey != 'no-key-required') {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final timeoutSeconds = LLMDefaultConfig.customTimeoutSeconds;

    final response = await http
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 2000,
            // Disable Qwen3/3.5 thinking mode (top-level for raw HTTP, not inside extra_body)
            'chat_template_kwargs': {'enable_thinking': false},
          }),
        )
        .timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            Log.e('Custom LLM request timed out after ${timeoutSeconds}s', label: 'Custom LLM');
            throw Exception('DOS_AI_TIMEOUT');
          },
        );

    Log.d('Custom LLM Response status: ${response.statusCode}', label: 'Custom LLM');

    // Cloudflare WAF block detection
    if (response.statusCode == 403) {
      Log.e('403 Forbidden - likely Cloudflare WAF block. Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}', label: 'Custom LLM');
      throw Exception('DOS AI blocked by firewall (403). Please try again.');
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        Log.d('Custom LLM Response: $content', label: 'Custom LLM');

        // Save conversation to history
        _conversationHistory.add({
          'role': 'user',
          'content': message,
        });
        _conversationHistory.add({
          'role': 'assistant',
          'content': content,
        });

        return content.trim();
      } catch (e) {
        Log.e('Failed to parse Custom LLM response: $e', label: 'Custom LLM');
        throw Exception('Invalid response format from Custom LLM.');
      }
    } else {
      Log.e('Custom LLM API error: ${response.statusCode} - ${response.body}', label: 'Custom LLM');

      if (response.statusCode == 503) {
        throw Exception('Self-hosted LLM server is not available. Please check if vLLM/Ollama is running.');
      } else {
        throw Exception('Custom LLM Error: ${response.statusCode}');
      }
    }
  }

  @override
  Future<String> sendMessage(String message) async {
    try {
      return await _retryWithBackoff(
        () => _sendMessageInternal(message),
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 500),
      );
    } catch (e) {
      Log.e('Error calling Custom LLM API: $e', label: 'Custom LLM');
      rethrow;
    }
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    final response = await sendMessage(message);
    yield response;
  }
}
