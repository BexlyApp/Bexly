import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/utils/logger.dart';

abstract class AIService {
  Future<String> sendMessage(String message);
  Stream<String> sendMessageStream(String message);
  void updateRecentTransactions(String recentTransactionsContext);
}

/// Mixin for shared prompt generation logic across AI services
mixin AIServicePromptMixin {
  List<String> get categories;
  String get recentTransactionsContext;

  /// System instruction defining AI's core behavior and personality
  String get systemInstruction => '''You are Bexly AI - a personal finance assistant helping users manage their money through natural conversation.

LANGUAGE RULES:
- ALWAYS respond in the same language as the user's message
- Vietnamese input → Vietnamese response
- English input → English response
- Be friendly, concise, and helpful''';

  /// Context about available categories and wallet information
  String get contextSection => '''
AVAILABLE CATEGORIES:
${categories.isEmpty ? '(No categories configured)' : categories.join(', ')}

CATEGORY MATCHING RULES:
- MUST use EXACT category name from the list above
- Graphics card / VGA / màn hình / monitor / PC parts → "Electronics"
- Phone / laptop / tablet / computer → "Electronics"
- Clothes / áo / quần → "Clothing"
- Food / ăn uống / cafe / restaurant → "Food & Drinks"
- Taxi / xe bus / grab → "Transportation"
- Only use "Others" if NO category matches''';

  /// Amount parsing rules for Vietnamese and English
  String get amountParsingRules => '''
AMOUNT RECOGNITION RULES:

Vietnamese shorthand:
- "300k" → 300,000 VND
- "2.5tr" / "2tr5" → 2,500,000 VND
- "70tr" → 70,000,000 VND
- Numbers may use dots/spaces as separators (1.000.000 or 1 000 000)

Currency detection:
- "\$100" OR "100 đô" → 100 USD (đô = dollar)
- "100 đồng" OR "100 đồng Việt Nam" OR "100 VND" → 100 VND
- "1 triệu đô" → 1,000,000 USD (NOT VND!)
- "1 triệu đồng" → 1,000,000 VND (NOT USD!)

CRITICAL: Always include "currency" field in ACTION_JSON ("USD" or "VND")''';

  /// JSON schema definitions for all available actions
  String get actionSchemas => '''
ACTION JSON SCHEMAS:

After your response, return ACTION_JSON on a new line with ONE of these schemas:

1. create_expense:
{"action":"create_expense","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

2. create_income:
{"action":"create_income","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

3. create_budget:
{"action":"create_budget","amount":<number>,"currency":"USD|VND","category":"<string>","period":"monthly|weekly|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"isRoutine":<boolean>?}

4. create_goal:
{"action":"create_goal","title":"<string>","targetAmount":<number>,"currency":"USD|VND","currentAmount":<number>?,"deadline":"YYYY-MM-DD"?,"notes":"<string>"?}

5. get_balance:
{"action":"get_balance"}

6. get_summary:
{"action":"get_summary","range":"today|week|month|quarter|year|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?}

7. list_transactions:
{"action":"list_transactions","range":"today|week|month|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"limit":<number>?}

8. update_transaction:
{"action":"update_transaction","transactionId":<number>,"amount":<number>?,"currency":"USD|VND"?,"description":"<string>"?,"category":"<string>"?,"date":"YYYY-MM-DD"?}

9. delete_transaction:
{"action":"delete_transaction","transactionId":<number>}

10. create_wallet:
{"action":"create_wallet","name":"<string>","currency":"USD|VND","initialBalance":<number>?,"iconName":"<string>"?,"colorHex":"<string>"?}

Format: ACTION_JSON: <json_object>''';

  /// Business rules for handling different request types
  String get businessRules => '''
BUSINESS RULES:

1. Spending/expenses → create_expense
2. Income/salary/bonus → create_income
3. Budget/budget planning → create_budget (default: monthly period)
4. Financial goals/savings targets → create_goal
5. Balance inquiry → get_balance
6. Summary/reports → get_summary
7. Transaction listing → list_transactions
8. Edit/update existing transaction → update_transaction (requires transactionId)
9. Delete/remove transaction → delete_transaction (requires transactionId)
10. Create new wallet → create_wallet (initialBalance defaults to 0 if not specified)

EXPENSE vs INCOME CLASSIFICATION - CRITICAL:

ALWAYS EXPENSE (create_expense):
- Trả nợ / Pay debt / Repay loan → EXPENSE (money going OUT)
- Mua / Buy / Purchase → EXPENSE
- Trả tiền / Payment → EXPENSE
- Chi phí / Cost / Fee → EXPENSE
- Nợ / Debt payment → EXPENSE
- Cho vay / Lend money → EXPENSE (money going OUT)

ALWAYS INCOME (create_income):
- Thu nhập / Income / Salary → INCOME
- Nhận tiền / Receive money → INCOME
- Bán / Sell → INCOME
- Thưởng / Bonus → INCOME
- Lãi / Interest earned → INCOME
- Vay / Borrow money → INCOME (money coming IN)
- Thu nợ / Collect debt → INCOME (money coming IN)

TRANSACTION ID CONTEXT:
- Recent transactions will be provided in conversation history
- When user says "sửa giao dịch vừa rồi" or "update last transaction", use the most recent transaction ID
- When user specifies which transaction (e.g., "the 265tr purchase"), find matching transaction by amount or description

IMPORTANT RESTRICTIONS:
- NEVER modify wallet balance directly
- If user wants to "set balance to X", explain they must record transactions
- Goals have target amounts, NOT current money (currentAmount is optional progress tracker)

CONTEXT AWARENESS - CRITICAL:
- ONLY return ACTION_JSON when user is CREATING or REQUESTING something
- DO NOT return ACTION_JSON when:
  * User is answering YOUR question
  * User is providing clarification or additional info
  * User is having a conversation without clear intent to create transaction
- If unsure, ask for confirmation before creating ACTION_JSON

Example of WRONG behavior:
AI: "Ban da mua card man hinh NVIDA RTX Pro 6000, nhung minh can biet gia cua no de ghi nhan chi tieu. Ban co the cho minh biet gia khong?"
User: "A toi mua het 265tr"
AI: [WRONG] Returns ACTION_JSON to create expense
AI: [CORRECT] "Đã ghi nhận chi tiêu 265,000,000 VND... ACTION_JSON: {..."

The difference: User was ANSWERING a question vs INITIATING a new request.''';

  /// Example showing expected format
  String get exampleSection => '''
EXAMPLES:

Correct - User initiates:
User: "lunch 300k"
AI: "Đã ghi nhận chi tiêu 300,000 VND cho bữa trưa.
ACTION_JSON: {"action":"create_expense","amount":300000,"currency":"VND","description":"Lunch","category":"Food & Dining"}"

Correct - AI asks first, user confirms:
User: "Tôi mua card đồ họa"
AI: "Bạn đã mua card đồ họa, nhưng mình cần biết giá để ghi nhận chi tiêu. Bạn có thể cho mình biết giá không?"
User: "265tr"
AI: "Đã ghi nhận chi tiêu 265,000,000 VND cho card đồ họa.
ACTION_JSON: {"action":"create_expense","amount":265000000,"currency":"VND","description":"Graphics card","category":"Others"}"''';

  /// Recent transactions context section
  String get recentTransactionsSection => recentTransactionsContext.isEmpty
      ? ''
      : '''
RECENT TRANSACTIONS:
$recentTransactionsContext

When user references transactions (e.g., "sửa giao dịch vừa rồi", "xóa cái 265tr"), use the transaction ID from this list.''';

  /// Build complete system prompt
  String get systemPrompt => '''$systemInstruction

$contextSection

$recentTransactionsSection

$amountParsingRules

$actionSchemas

$businessRules

$exampleSection''';
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

  /// System instruction defining AI's core behavior and personality
  String get _systemInstruction => '''You are Bexly AI - a personal finance assistant helping users manage their money through natural conversation.

LANGUAGE RULES:
- ALWAYS respond in the same language as the user's message
- Vietnamese input → Vietnamese response
- English input → English response
- Be friendly, concise, and helpful''';

  /// Context about available categories and wallet information
  String get _contextSection => '''
AVAILABLE CATEGORIES:
${categories.isEmpty ? '(No categories configured)' : categories.join(', ')}

CATEGORY MATCHING RULES:
- MUST use EXACT category name from the list above
- Graphics card / VGA / màn hình / monitor / PC parts → "Electronics"
- Phone / laptop / tablet / computer → "Electronics"
- Clothes / áo / quần → "Clothing"
- Food / ăn uống / cafe / restaurant → "Food & Drinks"
- Taxi / xe bus / grab → "Transportation"
- Only use "Others" if NO category matches''';

  /// Amount parsing rules for Vietnamese and English
  String get _amountParsingRules => '''
AMOUNT RECOGNITION RULES:

Vietnamese shorthand:
- "300k" → 300,000 VND
- "2.5tr" / "2tr5" → 2,500,000 VND
- "70tr" → 70,000,000 VND
- Numbers may use dots/spaces as separators (1.000.000 or 1 000 000)

Currency detection:
- "\$100" OR "100 đô" → 100 USD (đô = dollar)
- "100 đồng" OR "100 đồng Việt Nam" OR "100 VND" → 100 VND
- "1 triệu đô" → 1,000,000 USD (NOT VND!)
- "1 triệu đồng" → 1,000,000 VND (NOT USD!)

CRITICAL: Always include "currency" field in ACTION_JSON ("USD" or "VND")''';

  /// JSON schema definitions for all available actions
  String get _actionSchemas => '''
ACTION JSON SCHEMAS:

After your response, return ACTION_JSON on a new line with ONE of these schemas:

1. create_expense:
{"action":"create_expense","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

2. create_income:
{"action":"create_income","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

3. create_budget:
{"action":"create_budget","amount":<number>,"currency":"USD|VND","category":"<string>","period":"monthly|weekly|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"isRoutine":<boolean>?}

4. create_goal:
{"action":"create_goal","title":"<string>","targetAmount":<number>,"currency":"USD|VND","currentAmount":<number>?,"deadline":"YYYY-MM-DD"?,"notes":"<string>"?}

5. get_balance:
{"action":"get_balance"}

6. get_summary:
{"action":"get_summary","range":"today|week|month|quarter|year|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?}

7. list_transactions:
{"action":"list_transactions","range":"today|week|month|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"limit":<number>?}

8. update_transaction:
{"action":"update_transaction","transactionId":<number>,"amount":<number>?,"currency":"USD|VND"?,"description":"<string>"?,"category":"<string>"?,"date":"YYYY-MM-DD"?}

9. delete_transaction:
{"action":"delete_transaction","transactionId":<number>}

Format: ACTION_JSON: <json_object>''';

  /// Business rules for handling different request types
  String get _businessRules => '''
BUSINESS RULES:

1. Spending/expenses → create_expense
2. Income/salary/bonus → create_income
3. Budget/budget planning → create_budget (default: monthly period)
4. Financial goals/savings targets → create_goal
5. Balance inquiry → get_balance
6. Summary/reports → get_summary
7. Transaction listing → list_transactions
8. Edit/update existing transaction → update_transaction (requires transactionId)
9. Delete/remove transaction → delete_transaction (requires transactionId)

TRANSACTION ID CONTEXT:
- Recent transactions will be provided in conversation history
- When user says "sửa giao dịch vừa rồi" or "update last transaction", use the most recent transaction ID
- When user specifies which transaction (e.g., "the 265tr purchase"), find matching transaction by amount or description

IMPORTANT RESTRICTIONS:
- NEVER modify wallet balance directly
- If user wants to "set balance to X", explain they must record transactions
- Goals have target amounts, NOT current money (currentAmount is optional progress tracker)

CONTEXT AWARENESS - CRITICAL:
- ONLY return ACTION_JSON when user is CREATING or REQUESTING something
- DO NOT return ACTION_JSON when:
  * User is answering YOUR question
  * User is providing clarification or additional info
  * User is having a conversation without clear intent to create transaction
- If unsure, ask for confirmation before creating ACTION_JSON

Example of WRONG behavior:
AI: "Ban da mua card man hinh NVIDA RTX Pro 6000, nhung minh can biet gia cua no de ghi nhan chi tieu. Ban co the cho minh biet gia khong?"
User: "A toi mua het 265tr"
AI: [WRONG] Returns ACTION_JSON to create expense
AI: [CORRECT] "Đã ghi nhận chi tiêu 265,000,000 VND... ACTION_JSON: {..."

The difference: User was ANSWERING a question vs INITIATING a new request.''';

  /// Example showing expected format
  String get _exampleSection => '''
EXAMPLES:

Correct - User initiates:
User: "lunch 300k"
AI: "Đã ghi nhận chi tiêu 300,000 VND cho bữa trưa.
ACTION_JSON: {"action":"create_expense","amount":300000,"currency":"VND","description":"Lunch","category":"Food & Dining"}"

Correct - AI asks first, user confirms:
User: "Tôi mua card đồ họa"
AI: "Bạn đã mua card đồ họa, nhưng mình cần biết giá để ghi nhận chi tiêu. Bạn có thể cho mình biết giá không?"
User: "265tr"
AI: "Đã ghi nhận chi tiêu 265,000,000 VND cho card đồ họa.
ACTION_JSON: {"action":"create_expense","amount":265000000,"currency":"VND","description":"Graphics card","category":"Others"}"''';

  /// Recent transactions context section
  String get _recentTransactionsSection => _recentTransactionsContext.isEmpty
      ? ''
      : '''
RECENT TRANSACTIONS:
$_recentTransactionsContext

When user references transactions (e.g., "sửa giao dịch vừa rồi", "xóa cái 265tr"), use the transaction ID from this list.''';

  /// Build complete system prompt
  String get _systemPrompt => '''$_systemInstruction

$_contextSection

$_recentTransactionsSection

$_amountParsingRules

$_actionSchemas

$_businessRules

$_exampleSection''';

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

  late final GenerativeModel _model;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.categories = const [],
  }) {
    Log.d('GeminiService initialized with model: $model, categories: ${categories.length}', label: 'AI Service');
    _model = GenerativeModel(
      model: model,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
    );
  }

  @override
  void updateRecentTransactions(String recentTransactionsContext) {
    _recentTransactionsContext = recentTransactionsContext;
    Log.d('Updated recent transactions context (${recentTransactionsContext.length} chars)', label: 'AI Service');
  }

  /// System instruction defining AI's core behavior and personality
  String get _systemInstruction => '''You are Bexly AI - a personal finance assistant helping users manage their money through natural conversation.

LANGUAGE RULES:
- ALWAYS respond in the same language as the user's message
- Vietnamese input → Vietnamese response
- English input → English response
- Be friendly, concise, and helpful''';

  /// Context about available categories and wallet information
  String get _contextSection => '''
AVAILABLE CATEGORIES:
${categories.isEmpty ? '(No categories configured)' : categories.join(', ')}

CATEGORY MATCHING RULES:
- MUST use EXACT category name from the list above
- Graphics card / VGA / màn hình / monitor / PC parts → "Electronics"
- Phone / laptop / tablet / computer → "Electronics"
- Clothes / áo / quần → "Clothing"
- Food / ăn uống / cafe / restaurant → "Food & Drinks"
- Taxi / xe bus / grab → "Transportation"
- Only use "Others" if NO category matches''';

  /// Amount parsing rules for Vietnamese and English
  String get _amountParsingRules => '''
AMOUNT RECOGNITION RULES:

Vietnamese shorthand:
- "300k" → 300,000 VND
- "2.5tr" / "2tr5" → 2,500,000 VND
- "70tr" → 70,000,000 VND
- Numbers may use dots/spaces as separators (1.000.000 or 1 000 000)

Currency detection:
- "\$100" OR "100 đô" → 100 USD (đô = dollar)
- "100 đồng" OR "100 đồng Việt Nam" OR "100 VND" → 100 VND
- "1 triệu đô" → 1,000,000 USD (NOT VND!)
- "1 triệu đồng" → 1,000,000 VND (NOT USD!)

CRITICAL: Always include "currency" field in ACTION_JSON ("USD" or "VND")''';

  /// JSON schema definitions for all available actions
  String get _actionSchemas => '''
ACTION JSON SCHEMAS:

After your response, return ACTION_JSON on a new line with ONE of these schemas:

1. create_expense:
{"action":"create_expense","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

2. create_income:
{"action":"create_income","amount":<number>,"currency":"USD|VND","description":"<string>","category":"<string>"}

3. create_budget:
{"action":"create_budget","amount":<number>,"currency":"USD|VND","category":"<string>","period":"monthly|weekly|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"isRoutine":<boolean>?}

4. create_goal:
{"action":"create_goal","title":"<string>","targetAmount":<number>,"currency":"USD|VND","currentAmount":<number>?,"deadline":"YYYY-MM-DD"?,"notes":"<string>"?}

5. get_balance:
{"action":"get_balance"}

6. get_summary:
{"action":"get_summary","range":"today|week|month|quarter|year|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?}

7. list_transactions:
{"action":"list_transactions","range":"today|week|month|custom","startDate":"YYYY-MM-DD"?,"endDate":"YYYY-MM-DD"?,"limit":<number>?}

8. update_transaction:
{"action":"update_transaction","transactionId":<number>,"amount":<number>?,"currency":"USD|VND"?,"description":"<string>"?,"category":"<string>"?,"date":"YYYY-MM-DD"?}

9. delete_transaction:
{"action":"delete_transaction","transactionId":<number>}

Format: ACTION_JSON: <json_object>''';

  /// Business rules for handling different request types
  String get _businessRules => '''
BUSINESS RULES:

1. Spending/expenses → create_expense
2. Income/salary/bonus → create_income
3. Budget/budget planning → create_budget (default: monthly period)
4. Financial goals/savings targets → create_goal
5. Balance inquiry → get_balance
6. Summary/reports → get_summary
7. Transaction listing → list_transactions
8. Edit/update existing transaction → update_transaction (requires transactionId)
9. Delete/remove transaction → delete_transaction (requires transactionId)

TRANSACTION ID CONTEXT:
- Recent transactions will be provided in conversation history
- When user says "sửa giao dịch vừa rồi" or "update last transaction", use the most recent transaction ID
- When user specifies which transaction (e.g., "the 265tr purchase"), find matching transaction by amount or description

IMPORTANT RESTRICTIONS:
- NEVER modify wallet balance directly
- If user wants to "set balance to X", explain they must record transactions
- Goals have target amounts, NOT current money (currentAmount is optional progress tracker)

CONTEXT AWARENESS - CRITICAL:
- ONLY return ACTION_JSON when user is CREATING or REQUESTING something
- DO NOT return ACTION_JSON when:
  * User is answering YOUR question
  * User is providing clarification or additional info
  * User is having a conversation without clear intent to create transaction
- If unsure, ask for confirmation before creating ACTION_JSON

Example of WRONG behavior:
AI: "Ban da mua card man hinh NVIDA RTX Pro 6000, nhung minh can biet gia cua no de ghi nhan chi tieu. Ban co the cho minh biet gia khong?"
User: "A toi mua het 265tr"
AI: [WRONG] Returns ACTION_JSON to create expense
AI: [CORRECT] "Đã ghi nhận chi tiêu 265,000,000 VND... ACTION_JSON: {..."

The difference: User was ANSWERING a question vs INITIATING a new request.''';

  /// Example showing expected format
  String get _exampleSection => '''
EXAMPLES:

Correct - User initiates:
User: "lunch 300k"
AI: "Đã ghi nhận chi tiêu 300,000 VND cho bữa trưa.
ACTION_JSON: {"action":"create_expense","amount":300000,"currency":"VND","description":"Lunch","category":"Food & Dining"}"

Correct - AI asks first, user confirms:
User: "Tôi mua card đồ họa"
AI: "Bạn đã mua card đồ họa, nhưng mình cần biết giá để ghi nhận chi tiêu. Bạn có thể cho mình biết giá không?"
User: "265tr"
AI: "Đã ghi nhận chi tiêu 265,000,000 VND cho card đồ họa.
ACTION_JSON: {"action":"create_expense","amount":265000000,"currency":"VND","description":"Graphics card","category":"Others"}"''';

  /// Recent transactions context section
  String get _recentTransactionsSection => _recentTransactionsContext.isEmpty
      ? ''
      : '''
RECENT TRANSACTIONS:
$_recentTransactionsContext

When user references transactions (e.g., "sửa giao dịch vừa rồi", "xóa cái 265tr"), use the transaction ID from this list.''';

  /// Build complete system prompt
  String get _systemPrompt => '''$_systemInstruction

$_contextSection

$_recentTransactionsSection

$_amountParsingRules

$_actionSchemas

$_businessRules

$_exampleSection''';

  @override
  Future<String> sendMessage(String message) async {
    try {
      Log.d('Sending message to Gemini: $message', label: 'Gemini Service');

      // Validate API key
      if (apiKey.isEmpty || apiKey == 'USER_MUST_PROVIDE_API_KEY') {
        throw Exception('No Gemini API key configured. Please add GEMINI_API_KEY to your .env file.');
      }

      // Create chat with system instruction
      final chat = _model.startChat(
        history: [
          Content.text(systemPrompt),
        ],
      );

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
