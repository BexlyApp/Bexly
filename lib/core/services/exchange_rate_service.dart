import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service to fetch exchange rates using AI (Gemini)
class ExchangeRateService {
  final String apiKey;
  late final GenerativeModel _model;

  ExchangeRateService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0, // Deterministic for factual data
        maxOutputTokens: 200,
      ),
    );
  }

  /// Get exchange rate from one currency to another
  /// Returns the rate where: amount_in_from * rate = amount_in_to
  /// Example: getExchangeRate('USD', 'VND') might return 25000.0
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      Log.d('Fetching exchange rate: $fromCurrency -> $toCurrency', label: 'ExchangeRate');

      // Same currency = 1.0
      if (fromCurrency == toCurrency) {
        return 1.0;
      }

      final prompt = '''What is the current exchange rate from $fromCurrency to $toCurrency?

IMPORTANT INSTRUCTIONS:
- Return ONLY a single number (the exchange rate)
- No text, no explanation, just the number
- Use the most recent exchange rate available
- Format: If 1 $fromCurrency = X $toCurrency, return X
- Example format: 25000.50

Give me ONLY the number:''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Exchange rate request timed out');
        },
      );

      final rateText = response.text?.trim() ?? '';
      Log.d('AI raw response: $rateText', label: 'ExchangeRate');

      // Extract numeric value from response (handle various formats)
      // Remove common text patterns: "The exchange rate is", "approximately", etc.
      final cleanText = rateText
          .toLowerCase()
          .replaceAll(RegExp(r'[^\d.,\s]'), '') // Keep only digits, dots, commas, spaces
          .replaceAll(',', '') // Remove thousand separators
          .trim()
          .split(RegExp(r'\s+')) // Split by whitespace
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');

      Log.d('Cleaned text: $cleanText', label: 'ExchangeRate');

      // Parse the rate
      final rate = double.tryParse(cleanText);

      if (rate == null || rate <= 0) {
        Log.e('Invalid exchange rate - raw: "$rateText", cleaned: "$cleanText"', label: 'ExchangeRate');
        throw Exception('Could not parse exchange rate from AI response');
      }

      Log.d('Exchange rate: 1 $fromCurrency = $rate $toCurrency', label: 'ExchangeRate');
      return rate;
    } catch (e) {
      Log.e('Error fetching exchange rate: $e', label: 'ExchangeRate');
      rethrow;
    }
  }

  /// Hardcoded fallback rates (updated periodically)
  static const Map<String, double> _fallbackRates = {
    'VND_USD': 0.00004, // 1 VND = 0.00004 USD (1 USD = 25,000 VND)
    'USD_VND': 25000.0, // 1 USD = 25,000 VND
  };

  /// Get multiple exchange rates at once
  /// Returns a map where key is "FROM_TO" and value is the rate
  /// Example: {'USD_VND': 25000.0, 'EUR_VND': 27000.0}
  Future<Map<String, double>> getMultipleRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    try {
      Log.d('Fetching multiple rates to $baseCurrency: $targetCurrencies', label: 'ExchangeRate');

      final rates = <String, double>{};

      for (final targetCurrency in targetCurrencies) {
        if (targetCurrency == baseCurrency) {
          rates['${targetCurrency}_$baseCurrency'] = 1.0;
          continue;
        }

        final rate = await getExchangeRate(targetCurrency, baseCurrency);
        rates['${targetCurrency}_$baseCurrency'] = rate;
      }

      return rates;
    } catch (e) {
      Log.e('Error fetching multiple exchange rates: $e', label: 'ExchangeRate');
      rethrow;
    }
  }

  /// Convert amount from one currency to another
  /// Priority: AI (most accurate) → Hardcoded fallback → Exception
  Future<double> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    // Try AI first (most accurate, real-time rate)
    try {
      final rate = await getExchangeRate(fromCurrency, toCurrency);
      return amount * rate;
    } catch (e) {
      Log.e('AI exchange rate failed: $e, trying fallback', label: 'ExchangeRate');

      // Fallback: Try hardcoded rate
      final rateKey = '${fromCurrency}_$toCurrency';
      if (_fallbackRates.containsKey(rateKey)) {
        final rate = _fallbackRates[rateKey]!;
        Log.d('Using hardcoded fallback rate: 1 $fromCurrency = $rate $toCurrency', label: 'ExchangeRate');
        return amount * rate;
      }

      // Last resort: Reverse lookup of hardcoded rate
      final reverseKey = '${toCurrency}_$fromCurrency';
      if (_fallbackRates.containsKey(reverseKey)) {
        final reverseRate = _fallbackRates[reverseKey]!;
        final rate = 1.0 / reverseRate;
        Log.d('Using reverse hardcoded fallback: 1 $fromCurrency = $rate $toCurrency', label: 'ExchangeRate');
        return amount * rate;
      }

      // No fallback available, rethrow original error
      Log.e('No fallback rate available for $fromCurrency -> $toCurrency', label: 'ExchangeRate');
      rethrow;
    }
  }
}
