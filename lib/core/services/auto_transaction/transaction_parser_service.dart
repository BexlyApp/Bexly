import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';

/// Service to parse bank messages using AI (Gemini)
class TransactionParserService {
  final String apiKey;
  GenerativeModel? _model;

  TransactionParserService({required this.apiKey});

  GenerativeModel get _geminiModel {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Low temperature for consistent parsing
        maxOutputTokens: 500,
      ),
    );
    return _model!;
  }

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
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      final responseText = response.text;

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
- type: "income" or "expense" (income = money received/credited, expense = money spent/debited)
- merchant: string or null (who the payment was to/from)
- accountNumber: string or null (last 4 digits of account if visible)
- balance: number or null (account balance after transaction if shown)
- reference: string or null (transaction reference/ID if shown)
- isTransaction: boolean (true if this is a valid transaction message, false if promotional/OTP/other)

Important rules:
- "credit", "received", "deposit", "incoming", "CR" → type: "income"
- "debit", "spent", "paid", "payment", "withdrawal", "DR" → type: "expense"
- Amount should always be a positive number
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

      return ParsedTransaction(
        amount: amount,
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

/// Service to check for duplicate transactions
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
