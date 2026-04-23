import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/ai/background_ai_service.dart';

/// Service to parse bank messages using AI (uses configured provider)
class TransactionParserService {
  final BackgroundAIService _ai;

  TransactionParserService({required BackgroundAIService ai}) : _ai = ai;

  /// Parse a bank SMS/notification message
  Future<ParsedTransaction?> parseMessage({
    required String message,
    required String source, // 'sms' or 'notification'
    String? senderId,
    String? bankName,
    DateTime? messageTime,
  }) async {
    try {
      Log.d('Parsing $source message from $senderId', label: 'TransactionParser');

      final prompt = _buildParsingPrompt(message, senderId, bankName);
      final responseText = await _ai.complete(prompt);

      if (responseText == null || responseText.isEmpty) {
        Log.w('Empty response from AI', label: 'TransactionParser');
        return null;
      }

      Log.d('AI Response: $responseText', label: 'TransactionParser');

      // Parse JSON response
      final parsed = _parseAIResponse(responseText, message, source, senderId, bankName, messageTime);
      return parsed;
    } catch (e, stack) {
      Log.e('Failed to parse message: $e', label: 'TransactionParser');
      Log.e('Stack: $stack', label: 'TransactionParser');
      return null;
    }
  }

  String _buildParsingPrompt(String message, String? senderId, String? bankName) {
    return '''
You are a bank SMS/notification parser. Extract transaction information from the following message.

Message from ${senderId ?? 'Unknown'} (${bankName ?? 'Unknown Bank'}):
"$message"

Extract and return ONLY a JSON object with these fields:
- amount: number (the transaction amount, always positive)
- currency: string (currency code: "VND", "USD", "EUR", "THB", "SGD", "IDR", "MYR", "JPY", "KRW", "CNY", etc.)
- type: "income" or "expense" (income = money received/credited, expense = money spent/debited)
- merchant: string or null (who the payment was to/from, cleaned up and COMPLETED if truncated)
- accountNumber: string or null (last 4 digits of account if visible)
- balance: number or null (account balance after transaction if shown)
- reference: string or null (transaction reference/ID if shown)
- isTransaction: boolean (true if this is a valid transaction message, false if promotional/OTP/other)

Important rules:
- "credit", "received", "deposit", "incoming", "CR" → type: "income"
- "debit", "spent", "paid", "payment", "withdrawal", "DR" → type: "expense"
- Amount should always be a positive number
- CURRENCY (CRITICAL): Extract the EXACT currency stated in the message!
  - "200.00 USD" → currency: "USD"
  - "500,000 VND" → currency: "VND"
  - "100 EUR" → currency: "EUR"
  - "฿500" or "500 THB" → currency: "THB"
  - "¥10,000" from Japanese bank → currency: "JPY"
  - "₩50,000" → currency: "KRW"
  - If no currency explicitly stated, infer from bank/sender context or default to the most common currency for that bank's country
- MERCHANT NAME: Clean up and COMPLETE truncated merchant names (bank SMS often truncates):
  - "CLAUDE.AI SUBSCRIPTI" → "Claude AI Subscription"
  - "GRAB*TRANSPORT SER" → "Grab Transport Service"
  - "NETFLIX.COM INTERNATIO" → "Netflix.com International"
  - "APPLE.COM/BILL CUPER" → "Apple.com/Bill Cupertino"
  - Use proper Title Case, remove unnecessary dots/asterisks
- If the message is not a transaction (OTP, promo, etc.), set isTransaction: false
- Return ONLY the JSON object, no explanation

JSON:''';
  }

  ParsedTransaction? _parseAIResponse(
    String responseText,
    String originalMessage,
    String source,
    String? senderId,
    String? bankName,
    DateTime? messageTime,
  ) {
    try {
      // Extract JSON from response
      String jsonStr = responseText.trim();

      // Handle markdown code blocks
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final Map<String, dynamic> json = jsonDecode(jsonStr);

      // Check if it's a valid transaction
      if (json['isTransaction'] != true) {
        Log.d('Message is not a transaction', label: 'TransactionParser');
        return null;
      }

      final amount = (json['amount'] as num?)?.toDouble();
      if (amount == null || amount <= 0) {
        Log.w('Invalid amount: $amount', label: 'TransactionParser');
        return null;
      }

      final typeStr = json['type'] as String?;
      final type = typeStr == 'income' ? TransactionType.income : TransactionType.expense;

      // Extract currency - default to VND if not provided
      final currency = (json['currency'] as String?) ?? 'VND';

      return ParsedTransaction(
        amount: amount,
        currency: currency.toUpperCase(),
        type: type,
        dateTime: messageTime ?? DateTime.now(),
        merchant: json['merchant'] as String?,
        accountNumber: json['accountNumber'] as String?,
        balance: (json['balance'] as num?)?.toDouble(),
        reference: json['reference'] as String?,
        rawMessage: originalMessage,
        source: source,
        senderId: senderId,
        bankName: bankName,
      );
    } catch (e) {
      Log.e('Failed to parse AI response as JSON: $e', label: 'TransactionParser');
      return null;
    }
  }
}

/// Service to check for semantic duplicates using AI
///
/// Pre-filters candidates by amount/date in DB, then asks AI
/// to determine if the new transaction is a duplicate.
class AIDuplicateCheckService {
  final BackgroundAIService _ai;

  AIDuplicateCheckService({required BackgroundAIService ai}) : _ai = ai;

  /// Check if a parsed transaction is a duplicate of any existing transaction.
  ///
  /// [parsed] - The new transaction to check
  /// [candidates] - Recent DB transactions with similar amount/date (pre-filtered)
  ///   Each map should have: amount, date, title, notes
  ///
  /// Returns true if AI determines this is likely a duplicate.
  Future<bool> isDuplicate({
    required ParsedTransaction parsed,
    required List<Map<String, dynamic>> candidates,
  }) async {
    if (candidates.isEmpty) return false;

    try {
      final prompt = _buildDuplicateCheckPrompt(parsed, candidates);
      final text = await _ai.complete(prompt, maxTokens: 200);

      if (text == null || text.isEmpty) {
        Log.w('Empty AI duplicate check response', label: 'AIDuplicateCheck');
        return false;
      }

      Log.d('AI duplicate check response: $text', label: 'AIDuplicateCheck');

      // Parse response
      String jsonStr = text;
      if (jsonStr.startsWith('```json')) jsonStr = jsonStr.substring(7);
      if (jsonStr.startsWith('```')) jsonStr = jsonStr.substring(3);
      if (jsonStr.endsWith('```')) jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json['isDuplicate'] == true;
    } catch (e) {
      Log.w('AI duplicate check failed, assuming not duplicate: $e',
          label: 'AIDuplicateCheck');
      return false; // On error, allow the transaction through
    }
  }

  String _buildDuplicateCheckPrompt(
    ParsedTransaction parsed,
    List<Map<String, dynamic>> candidates,
  ) {
    final candidateLines = candidates.asMap().entries.map((e) {
      final c = e.value;
      return '${e.key + 1}. Amount: ${c['amount']}, Date: ${c['date']}, '
          'Title: "${c['title']}", Notes: "${c['notes'] ?? ''}"';
    }).join('\n');

    return '''
You are a financial transaction duplicate detector. Determine if the NEW transaction is a duplicate of any EXISTING transaction.

NEW transaction (from ${parsed.source}):
- Amount: ${parsed.amount}
- Date: ${parsed.dateTime.toIso8601String()}
- Merchant: "${parsed.merchant ?? 'unknown'}"
- Bank: "${parsed.bankName ?? 'unknown'}"
- Reference: "${parsed.reference ?? ''}"

EXISTING transactions in database:
$candidateLines

Rules:
- Same amount within 1 day AND similar merchant/description → DUPLICATE
- Same amount within 1 hour even with different description → LIKELY DUPLICATE
- Different amounts → NOT duplicate
- Same amount but more than 3 days apart → NOT duplicate (could be recurring)

Return ONLY JSON: {"isDuplicate": true/false, "reason": "brief explanation"}
JSON:''';
  }
}

/// Service to check for duplicate transactions using hash cache
class TransactionDeduplicationService {
  static const String _cacheKey = 'auto_transaction_hashes';
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(days: 30);

  /// Check if a transaction already exists (is duplicate)
  Future<bool> isDuplicate(ParsedTransaction transaction) async {
    final hash = _generateHash(transaction);
    final cache = await _loadCache();

    return cache.containsKey(hash);
  }

  /// Mark a transaction as processed (add to cache)
  Future<void> markProcessed(ParsedTransaction transaction) async {
    final hash = _generateHash(transaction);
    final cache = await _loadCache();

    cache[hash] = DateTime.now().millisecondsSinceEpoch;

    // Clean old entries if cache is too large
    if (cache.length > _maxCacheSize) {
      _cleanOldEntries(cache);
    }

    await _saveCache(cache);
  }

  String _generateHash(ParsedTransaction transaction) {
    // Hash based on: amount + datetime (rounded to minute) + merchant
    final roundedTime = DateTime(
      transaction.dateTime.year,
      transaction.dateTime.month,
      transaction.dateTime.day,
      transaction.dateTime.hour,
      transaction.dateTime.minute,
    );

    final data = '${transaction.amount.toStringAsFixed(2)}_'
        '${roundedTime.millisecondsSinceEpoch}_'
        '${transaction.merchant ?? 'unknown'}';

    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, int>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      Log.e('Failed to load dedup cache: $e', label: 'Deduplication');
      return {};
    }
  }

  Future<void> _saveCache(Map<String, int> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      Log.e('Failed to save dedup cache: $e', label: 'Deduplication');
    }
  }

  void _cleanOldEntries(Map<String, int> cache) {
    final cutoff = DateTime.now().subtract(_cacheExpiry).millisecondsSinceEpoch;

    cache.removeWhere((key, timestamp) => timestamp < cutoff);

    // If still too large, remove oldest entries
    if (cache.length > _maxCacheSize) {
      final entries = cache.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = entries.take(cache.length - _maxCacheSize + 100);
      for (final entry in toRemove) {
        cache.remove(entry.key);
      }
    }
  }
}
