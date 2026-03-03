import 'dart:convert';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';
import 'package:bexly/features/email_sync/domain/services/email_parser_service.dart';
import 'package:http/http.dart' as http;

/// LLM-based email parser for better accuracy
/// Supports: Gemini (via proxy), OpenAI (via proxy), and Custom LLM (DOS AI, direct)
class LLMEmailParserService {
  static const _label = 'LLMEmailParser';

  final String provider; // 'gemini', 'openai', or 'custom'
  final String? baseUrl; // For custom LLM
  final String? model; // For custom LLM

  LLMEmailParserService({
    String? provider,
    this.baseUrl,
    this.model,
  }) : provider = provider ?? LLMDefaultConfig.provider;

  /// Parse email using LLM
  Future<ParsedEmail?> parseEmail(GmailMessage email) async {
    try {
      Log.i('Parsing email with LLM: ${email.subject}', label: _label);

      final content = '${email.subject}\n${email.body}';
      final prompt = _buildPrompt(content, email.from);

      String response;
      switch (provider.toLowerCase()) {
        case 'gemini':
          response = await _parseViaProxy(prompt, providerName: 'gemini');
          break;
        case 'openai':
          response = await _parseViaProxy(prompt, providerName: 'openai');
          break;
        case 'custom':
          response = await _parseWithCustomDirect(prompt);
          break;
        default:
          Log.w('Unknown provider: $provider, using Gemini via proxy', label: _label);
          response = await _parseViaProxy(prompt, providerName: 'gemini');
      }

      // Parse JSON response
      final parsed = _parseJsonResponse(response, email);
      if (parsed != null) {
        Log.i('Successfully parsed: ${parsed.merchant} - ${parsed.amount} ${parsed.currency}', label: _label);
      } else {
        Log.w('Failed to parse email: ${email.subject}', label: _label);
      }

      return parsed;
    } catch (e, stack) {
      Log.e('Error parsing email with LLM: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return null;
    }
  }

  /// Build prompt for LLM
  String _buildPrompt(String emailContent, String fromEmail) {
    return '''
You are a banking email transaction parser. Extract transaction information from banking emails.

EMAIL FROM: $fromEmail

EMAIL CONTENT:
$emailContent

---

Extract the following information and respond ONLY with valid JSON (no markdown, no code blocks):

{
  "amount": <number>, // Transaction amount (positive number, no currency symbols)
  "currency": "USD", // ISO currency code extracted from email: "VND", "USD", "EUR", "THB", "JPY", "KRW", etc.
  "transactionType": "expense" or "income", // "expense" for debit/spending, "income" for credit/receiving
  "merchant": "Merchant Name", // Store/business name or transaction description
  "categoryHint": "Category Name", // Suggested category (Food & Dining, Transportation, Shopping, Bills & Utilities, Entertainment, Health, Education, Transfer, Salary, Other)
  "accountLast4": "1234", // Last 4 digits of account (if mentioned)
  "balanceAfter": <number>, // Account balance after transaction (if mentioned)
  "rawAmountText": "Original amount text from email",
  "bankName": "Bank Name", // Extract from email sender or content
  "confidence": 0.9, // Your confidence score (0.0-1.0)
  "sourceDescription": "Short description" // A clean 1-2 line summary of the transaction from original content
}

RULES:
1. Amount must be a positive number (no commas, no currency symbols)
2. CURRENCY: Extract the EXACT currency from the email! "\$200" → "USD", "500,000 VND" → "VND", "€100" → "EUR", "฿500" → "THB", "¥10,000" → "JPY"/"CNY" (based on context). Infer from bank/sender country if not explicit.
3. transactionType: Use "expense" for debit/spending (debit, spent, paid, withdrawal, chi, trừ, rút, thanh toán, ถอน, 支出), "income" for credit/receiving (credit, received, deposit, có, nhận, nạp, ฝาก, 收入)
4. merchant: Extract business name, recipient, or transaction description. COMPLETE truncated names (e.g., "SUBSCRIPTI" → "Subscription")
5. categoryHint: Choose the most appropriate category from the list above
6. If you cannot extract certain fields, use null
7. sourceDescription: Create a clean, short summary (1-2 lines) in the original language. Examples: "ACB: TK xxx9999 -150,000đ to NGUYEN VAN A", "Chase: Card ending 4321 - \$200.00 at NETFLIX.COM"
8. Respond with ONLY the JSON object, no additional text

JSON:''';
  }

  /// Parse email via Supabase Edge Function proxy (Gemini or OpenAI)
  Future<String> _parseViaProxy(String prompt, {required String providerName}) async {
    final token = LLMDefaultConfig.proxyAccessToken;
    if (token == null) {
      throw Exception('Not authenticated — cannot use AI proxy.');
    }

    final modelName = model ??
      (providerName == 'openai'
        ? LLMDefaultConfig.model
        : LLMDefaultConfig.geminiModel);

    Log.d('Using $providerName via proxy, model: $modelName', label: _label);

    final response = await http
        .post(
          Uri.parse(LLMDefaultConfig.proxyUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'provider': providerName,
            'action': 'chat',
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': 500,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('LLM API request timed out');
          },
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) throw Exception(data['error']);
      final content = data['content'] as String;
      Log.d('Proxy response: $content', label: _label);
      return content.trim();
    } else {
      Log.e('Proxy error: ${response.statusCode} - ${response.body}', label: _label);
      throw Exception('LLM proxy error: ${response.statusCode}');
    }
  }

  /// Parse email with Custom LLM (direct OpenAI-compatible API, e.g., DOS AI)
  Future<String> _parseWithCustomDirect(String prompt) async {
    final endpoint = baseUrl ?? LLMDefaultConfig.customEndpoint;
    final modelName = model ?? LLMDefaultConfig.customModel;
    final apiKey = LLMDefaultConfig.customApiKey;

    Log.d('Using Custom LLM direct: $endpoint, model: $modelName', label: _label);

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
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': 500,
            // Disable Qwen3/3.5 thinking mode for faster responses
            'chat_template_kwargs': {'enable_thinking': false},
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('LLM API request timed out');
          },
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      Log.d('LLM response: $content', label: _label);
      return content.trim();
    } else {
      Log.e('LLM API error: ${response.statusCode} - ${response.body}', label: _label);
      throw Exception('LLM API error: ${response.statusCode}');
    }
  }

  /// Parse JSON response from LLM
  ParsedEmail? _parseJsonResponse(String response, GmailMessage email) {
    try {
      // Clean response - remove markdown code blocks if present
      String cleanJson = response.trim();
      if (cleanJson.startsWith('```')) {
        // Remove ```json and ``` markers
        cleanJson = cleanJson.replaceAll(RegExp(r'```json\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'```\s*$'), '');
        cleanJson = cleanJson.trim();
      }

      // Extract JSON if wrapped in other text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanJson);
      if (jsonMatch != null) {
        cleanJson = jsonMatch.group(0)!;
      }

      final json = jsonDecode(cleanJson) as Map<String, dynamic>;

      // Validate required fields
      final amount = json['amount'];
      if (amount == null) {
        Log.w('No amount in JSON response', label: _label);
        return null;
      }

      return ParsedEmail(
        emailId: email.id,
        emailSubject: email.subject,
        fromEmail: email.from,
        amount: (amount is int) ? amount.toDouble() : (amount as num).toDouble(),
        currency: json['currency'] as String? ?? 'VND',
        transactionType: json['transactionType'] as String? ?? 'expense',
        merchant: json['merchant'] as String?,
        accountLast4: json['accountLast4'] as String?,
        balanceAfter: json['balanceAfter'] != null
            ? (json['balanceAfter'] is int
                ? (json['balanceAfter'] as int).toDouble()
                : json['balanceAfter'] as double?)
            : null,
        transactionDate: email.date, // Use email date as fallback
        emailDate: email.date,
        confidence: json['confidence'] != null
            ? (json['confidence'] is int
                ? (json['confidence'] as int).toDouble()
                : json['confidence'] as double)
            : 0.8,
        rawAmountText: json['rawAmountText'] as String? ?? amount.toString(),
        categoryHint: json['categoryHint'] as String?,
        bankName: json['bankName'] as String? ?? 'Unknown Bank',
        sourceDescription: json['sourceDescription'] as String?,
      );
    } catch (e, stack) {
      Log.e('Error parsing JSON response: $e', label: _label);
      Log.e('Response was: $response', label: _label);
      Log.e('Stack: $stack', label: _label);
      return null;
    }
  }

  /// Parse multiple emails in batch (more efficient)
  Future<List<ParsedEmail>> parseEmailBatch(
    List<GmailMessage> emails,
  ) async {
    final results = <ParsedEmail>[];

    for (final email in emails) {
      try {
        final parsed = await parseEmail(email);
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (e) {
        Log.w('Batch: Failed to parse email ${email.id}: $e', label: _label);
        // Continue with other emails
      }
    }

    Log.i('Batch parsing completed: ${results.length}/${emails.length} succeeded', label: _label);
    return results;
  }
}
