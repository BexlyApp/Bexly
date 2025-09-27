import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';

abstract class AIService {
  Future<String> sendMessage(String message);
  Stream<String> sendMessageStream(String message);
}

class OpenAIService implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final List<String> categories;

  OpenAIService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.categories = const [],
  }) {
    Log.d('OpenAIService initialized with model: $model, categories: ${categories.length}', label: 'AI Service');
  }

  @override
  Future<String> sendMessage(String message) async {
    try {
      Log.d('Sending message to OpenAI: $message', label: 'OpenAI Service');
      Log.d('Using API key: ${apiKey.substring(0, 10)}...', label: 'OpenAI Service');

      final response = await http.post(
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
              'content': '''You are Bexly AI - a personal finance assistant. Always respond in English and return ACTION_JSON with proper schema.

Available categories: ${categories.join(', ')}. If no exact match, use "Others".

Amount recognition rules (Vietnamese/English):
- "300k" => 300000; "2.5tr" => 2500000; "70tr" => 70000000; "\$100" => 100 (USD)
- Numbers may have dots/spaces as separators

Valid ACTION_JSON (always on new line after response):
- create_expense: {"action":"create_expense","amount":<number>,"description":"<string>","category":"<string>"}
- create_income: {"action":"create_income","amount":<number>,"description":"<string>","category":"<string>"}
- create_budget: {"action":"create_budget","amount":<number>,"category":"<string>","period":"monthly|weekly|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"isRoutine":<boolean>?}
- get_balance: {"action":"get_balance"}
- get_summary: {"action":"get_summary","range":"today|week|month|quarter|year|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?}
- list_transactions: {"action":"list_transactions","range":"today|week|month|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"limit":<number>?}

IMPORTANT RULES:
1) For spending/income => return create_expense/create_income
2) For budget/budget planning => return create_budget with appropriate period (default monthly)
3) For balance inquiry => return get_balance
4) For summary => return get_summary with appropriate range
5) For listing => return list_transactions with range/limit
6) If user wants to UPDATE/SET wallet balance directly, explain that you cannot modify wallet balance directly - they must record income or expense transactions
7) ACTION_JSON must start with "ACTION_JSON:" prefix and contain valid JSON only

Example: "lunch 300k"
"I've recorded an expense of 300,000 VND for lunch.
ACTION_JSON: {"action":"create_expense","amount":300000,"description":"Lunch","category":"Food & Dining"}"
'''
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
      );

      Log.d('OpenAI Response status: ${response.statusCode}', label: 'OpenAI Service');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        Log.d('OpenAI Response content: $content', label: 'OpenAI Service');
        return content.trim();
      } else {
        Log.e('OpenAI API error: ${response.statusCode} - ${response.body}', label: 'OpenAI Service');

        throw Exception('OpenAI API error: ${response.statusCode}');
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
