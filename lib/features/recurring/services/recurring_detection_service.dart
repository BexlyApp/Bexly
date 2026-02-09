import 'dart:convert';

import 'package:bexly/core/database/daos/recurring_dao.dart';
import 'package:bexly/core/database/daos/transaction_dao.dart';
import 'package:bexly/core/services/ai/background_ai_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/recurring/data/model/recurring_suggestion.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

/// Service that uses AI to detect recurring patterns from transaction history.
///
/// Flow: query transactions → build prompt → send to AI → parse JSON → suggestions
/// Falls back to simple rule-based detection when AI is unavailable.
class RecurringDetectionService {
  static const String _label = 'RecurringDetection';
  static const int _maxTransactionsInPrompt = 200;
  static const int _lookbackDays = 90;
  static const double _minConfidence = 0.5;

  final TransactionDao _transactionDao;
  final RecurringDao _recurringDao;
  final BackgroundAIService _aiService;

  RecurringDetectionService({
    required TransactionDao transactionDao,
    required RecurringDao recurringDao,
    BackgroundAIService? aiService,
  })  : _transactionDao = transactionDao,
        _recurringDao = recurringDao,
        _aiService = aiService ?? BackgroundAIService();

  /// Detect recurring patterns from recent transactions.
  /// Returns a list of suggestions sorted by confidence (highest first).
  Future<List<RecurringSuggestion>> detectPatterns() async {
    Log.d('Starting recurring pattern detection...', label: _label);

    // 1. Get recent transactions
    final transactions = await _transactionDao.getRecentTransactionsForDetection(
      days: _lookbackDays,
    );
    Log.d('Found ${transactions.length} transactions in last $_lookbackDays days', label: _label);

    if (transactions.length < 3) {
      Log.d('Not enough transactions for pattern detection', label: _label);
      return [];
    }

    // 2. Get existing recurring names to exclude
    final existingNames = await _recurringDao.getActiveRecurringNames();
    Log.d('Existing recurring names: $existingNames', label: _label);

    // 3. Try AI-powered detection
    if (BackgroundAIService.isAvailable) {
      try {
        final aiResult = await _detectWithAI(transactions, existingNames);
        if (aiResult.isNotEmpty) {
          Log.d('AI detected ${aiResult.length} patterns', label: _label);
          return aiResult;
        }
      } catch (e) {
        Log.w('AI detection failed, falling back to rule-based: $e', label: _label);
      }
    }

    // 4. Fallback to rule-based detection
    Log.d('Using rule-based fallback detection', label: _label);
    return _fallbackDetection(transactions, existingNames);
  }

  /// AI-powered detection: send transactions to LLM for pattern analysis
  Future<List<RecurringSuggestion>> _detectWithAI(
    List<TransactionModel> transactions,
    Set<String> existingNames,
  ) async {
    final prompt = _buildPrompt(transactions, existingNames);
    Log.d('Sending ${transactions.length.clamp(0, _maxTransactionsInPrompt)} transactions to AI', label: _label);

    final response = await _aiService.complete(prompt, maxTokens: 1000);
    if (response == null || response.isEmpty) {
      throw Exception('AI returned empty response');
    }

    Log.d('AI response length: ${response.length}', label: _label);
    return _parseAIResponse(response, transactions);
  }

  /// Build the AI prompt with transaction data in compact format
  String _buildPrompt(
    List<TransactionModel> transactions,
    Set<String> existingNames,
  ) {
    // Limit transactions to avoid token overflow
    final limited = transactions.take(_maxTransactionsInPrompt).toList();

    // Get wallet currency from first transaction
    final currency = limited.isNotEmpty ? limited.first.wallet.currency : 'VND';

    // Compact format: "title|amount|date|category"
    final dateFormat = DateFormat('yyyy-MM-dd');
    final lines = limited.map((t) {
      final date = dateFormat.format(t.date);
      final cat = t.category.title;
      return '${t.title}|${t.amount.toStringAsFixed(0)}|$date|$cat';
    }).join('\n');

    final existingList = existingNames.isNotEmpty
        ? '\nALREADY TRACKED (exclude these): ${existingNames.join(', ')}'
        : '';

    return '''You are a financial pattern analyzer. Analyze these transactions and identify RECURRING payment patterns.

TRANSACTIONS (title|amount|date|category):
$lines
$existingList
DEFAULT CURRENCY: $currency
TODAY: ${dateFormat.format(DateTime.now())}

RULES:
- Group transactions with similar titles (fuzzy match: "CIRCLE K #123" and "Circle K Bach Khoa" = same merchant)
- A pattern needs at least 3 occurrences
- Detect frequency: weekly (~7d), biweekly (~14d), monthly (~30d), quarterly (~90d), yearly (~365d)
- Ignore irregular purchases at the same store (e.g., varying amounts at a grocery store = NOT recurring)
- For recurring: amounts should be consistent (within 10% variance)
- Suggest a clean, short name for each pattern
- Calculate when the next payment is expected based on the pattern

Return ONLY a valid JSON array (no markdown, no explanation):
[{"name":"Netflix","amount":70000,"currency":"$currency","frequency":"monthly","billing_day":15,"category":"Entertainment","confidence":0.95,"matching_titles":["Netflix Premium","NETFLIX"],"next_expected":"2026-03-15"}]

Return [] if no patterns found.''';
  }

  /// Parse AI response and extract RecurringSuggestion list
  List<RecurringSuggestion> _parseAIResponse(
    String response,
    List<TransactionModel> transactions,
  ) {
    // Extract JSON array from response (AI might include extra text)
    String jsonStr = response.trim();

    // Try to find JSON array in response
    final bracketStart = jsonStr.indexOf('[');
    final bracketEnd = jsonStr.lastIndexOf(']');
    if (bracketStart != -1 && bracketEnd > bracketStart) {
      jsonStr = jsonStr.substring(bracketStart, bracketEnd + 1);
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList
          .map((json) => RecurringSuggestion.fromJson(json as Map<String, dynamic>))
          .where((s) => s.confidence >= _minConfidence && s.name.isNotEmpty)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
    } catch (e) {
      Log.w('Failed to parse AI response as JSON: $e', label: _label);
      Log.d('Raw AI response: $jsonStr', label: _label);
      return [];
    }
  }

  /// Simple rule-based fallback when AI is unavailable.
  /// Groups by exact title match, checks amount consistency and interval regularity.
  List<RecurringSuggestion> _fallbackDetection(
    List<TransactionModel> transactions,
    Set<String> existingNames,
  ) {
    // Group by normalized title
    final groups = groupBy(
      transactions,
      (TransactionModel t) => t.title.toLowerCase().trim(),
    );

    final suggestions = <RecurringSuggestion>[];

    for (final entry in groups.entries) {
      final title = entry.key;
      final txns = entry.value;

      // Need at least 3 occurrences
      if (txns.length < 3) continue;

      // Skip if already tracked
      if (existingNames.contains(title)) continue;

      // Check amount consistency (within 10% of median)
      final amounts = txns.map((t) => t.amount).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      final allConsistent = amounts.every(
        (a) => (a - median).abs() / median < 0.1,
      );
      if (!allConsistent) continue;

      // Detect frequency from intervals
      final dates = txns.map((t) => t.date).toList()..sort();
      final frequency = _detectFrequencyFromDates(dates);
      if (frequency == null) continue;

      // Calculate next expected date
      final lastDate = dates.last;
      final nextExpected = _calculateNextExpected(lastDate, frequency);

      // Calculate confidence
      final intervals = <int>[];
      for (int i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inDays);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final intervalVariance = intervals
              .map((i) => (i - avgInterval).abs())
              .reduce((a, b) => a + b) /
          intervals.length;

      double confidence = 0.3; // Base
      if (txns.length >= 4) confidence += 0.2;
      if (txns.length >= 6) confidence += 0.1;
      if (allConsistent) confidence += 0.2;
      if (intervalVariance < 3) confidence += 0.2;

      suggestions.add(RecurringSuggestion(
        name: txns.first.title, // Use original casing from first transaction
        amount: median,
        currency: txns.first.wallet.currency,
        frequency: frequency,
        billingDay: lastDate.day,
        category: txns.first.category.title,
        confidence: confidence.clamp(0.0, 1.0),
        matchingTitles: txns.map((t) => t.title).toSet().toList(),
        nextExpected: nextExpected,
      ));
    }

    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.where((s) => s.confidence >= _minConfidence).toList();
  }

  /// Detect frequency from a sorted list of dates
  String? _detectFrequencyFromDates(List<DateTime> dates) {
    if (dates.length < 3) return null;

    final intervals = <int>[];
    for (int i = 1; i < dates.length; i++) {
      intervals.add(dates[i].difference(dates[i - 1]).inDays);
    }

    final median = (intervals..sort())[intervals.length ~/ 2];

    if (median >= 5 && median <= 9) return 'weekly';
    if (median >= 12 && median <= 18) return 'biweekly';
    if (median >= 25 && median <= 35) return 'monthly';
    if (median >= 80 && median <= 100) return 'quarterly';
    if (median >= 350 && median <= 380) return 'yearly';

    return null;
  }

  /// Calculate next expected date based on last date and frequency
  DateTime _calculateNextExpected(DateTime lastDate, String frequency) {
    switch (frequency) {
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'biweekly':
        return lastDate.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case 'quarterly':
        return DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
      case 'yearly':
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
      default:
        return lastDate.add(const Duration(days: 30));
    }
  }
}
