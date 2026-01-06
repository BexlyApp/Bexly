import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';

/// Service to fetch and cache exchange rates
/// Priority: Free API (cached 24h) → Gemini AI → Emergency fallback
class ExchangeRateService {
  final String geminiApiKey;
  late final GenerativeModel _model;

  // Cache keys
  static const String _cachePrefix = 'exchange_rate_';
  static const String _cacheTimestampPrefix = 'exchange_rate_ts_';
  static const Duration _cacheDuration = Duration(hours: 24);

  // Free exchange rate API (no API key required, 1500 requests/month free)
  static const String _apiBaseUrl = 'https://api.exchangerate-api.com/v4/latest';

  ExchangeRateService({required this.geminiApiKey}) {
    _model = GenerativeModel(
      model: LLMDefaultConfig.geminiModel,
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0,
        maxOutputTokens: 200,
      ),
    );
  }

  /// Get exchange rate with 24h caching
  /// Priority: Cache → Free API → Gemini AI → Emergency fallback
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    print('[ExchangeRate] 🔍 getExchangeRate called: $fromCurrency → $toCurrency');
    Log.i('🔍 getExchangeRate called: $fromCurrency → $toCurrency', label: 'ExchangeRate');

    // Same currency = 1.0
    if (fromCurrency == toCurrency) {
      print('[ExchangeRate] Same currency, returning 1.0');
      return 1.0;
    }

    final cacheKey = '$_cachePrefix${fromCurrency}_$toCurrency';
    final timestampKey = '$_cacheTimestampPrefix${fromCurrency}_$toCurrency';

    try {
      // 1. Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedRate = prefs.getDouble(cacheKey);
      final cachedTimestamp = prefs.getInt(timestampKey);

      print('[ExchangeRate] Cache check: cachedRate=$cachedRate, cachedTimestamp=$cachedTimestamp');

      if (cachedRate != null && cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        print('[ExchangeRate] Cache age: ${Duration(milliseconds: cacheAge).inHours}h (max: ${_cacheDuration.inHours}h)');

        if (cacheAge < _cacheDuration.inMilliseconds) {
          print('[ExchangeRate] ✅ Cache HIT! Using cached rate: $cachedRate');
          Log.d('Using cached rate: 1 $fromCurrency = $cachedRate $toCurrency (age: ${Duration(milliseconds: cacheAge).inHours}h)',
                label: 'ExchangeRate');
          return cachedRate;
        } else {
          print('[ExchangeRate] ⏰ Cache expired, fetching new rate...');
        }
      } else {
        print('[ExchangeRate] ❌ No cache found, fetching from API...');
      }

      // 2. Try free API
      print('[ExchangeRate] 🌐 Trying free API...');
      try {
        final rate = await _fetchFromAPI(fromCurrency, toCurrency);
        // Cache the result
        await prefs.setDouble(cacheKey, rate);
        await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
        print('[ExchangeRate] ✅ API SUCCESS! Rate: $rate');
        Log.d('Fetched from API and cached: 1 $fromCurrency = $rate $toCurrency', label: 'ExchangeRate');
        return rate;
      } catch (apiError) {
        print('[ExchangeRate] ❌ API FAILED: $apiError');
        Log.w('Free API failed: $apiError, trying Gemini', label: 'ExchangeRate');

        // 3. Fallback to Gemini AI
        print('[ExchangeRate] 🤖 Trying Gemini AI...');
        try {
          final rate = await _fetchFromGemini(fromCurrency, toCurrency);
          // Cache the result
          await prefs.setDouble(cacheKey, rate);
          await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
          print('[ExchangeRate] ✅ GEMINI SUCCESS! Rate: $rate');
          Log.d('Fetched from Gemini and cached: 1 $fromCurrency = $rate $toCurrency', label: 'ExchangeRate');
          return rate;
        } catch (geminiError) {
          print('[ExchangeRate] ❌ GEMINI FAILED: $geminiError');
          Log.e('Gemini also failed: $geminiError', label: 'ExchangeRate');

          // 4. Last resort: Emergency fallback (if exists)
          final fallbackRate = _getEmergencyFallback(fromCurrency, toCurrency);
          if (fallbackRate != null) {
            print('[ExchangeRate] ⚠️ Using EMERGENCY FALLBACK: $fallbackRate');
            Log.w('Using emergency fallback: 1 $fromCurrency = $fallbackRate $toCurrency', label: 'ExchangeRate');
            return fallbackRate;
          }

          throw Exception('All exchange rate sources failed');
        }
      }
    } catch (e) {
      Log.e('Critical error in getExchangeRate: $e', label: 'ExchangeRate');
      rethrow;
    }
  }

  /// Fetch from free API (exchangerate-api.com)
  Future<double> _fetchFromAPI(String fromCurrency, String toCurrency) async {
    final url = '$_apiBaseUrl/$fromCurrency';

    final response = await http.get(
      Uri.parse(url),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('API returned ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>;

    if (!rates.containsKey(toCurrency)) {
      throw Exception('Currency $toCurrency not found in API response');
    }

    final rate = (rates[toCurrency] as num).toDouble();

    if (rate <= 0) {
      throw Exception('Invalid rate: $rate');
    }

    return rate;
  }

  /// Fetch from Gemini AI (fallback)
  Future<double> _fetchFromGemini(String fromCurrency, String toCurrency) async {
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
        throw Exception('Gemini request timed out');
      },
    );

    final rateText = response.text?.trim() ?? '';

    // Extract numeric value
    final cleanText = rateText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\d.,\s]'), '')
        .replaceAll(',', '')
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final rate = double.tryParse(cleanText);

    if (rate == null || rate <= 0) {
      throw Exception('Could not parse Gemini response: "$rateText"');
    }

    return rate;
  }

  /// Emergency fallback rates (only for critical currency pairs)
  /// Updated manually when API and AI both fail
  double? _getEmergencyFallback(String fromCurrency, String toCurrency) {
    // Only keep a few critical pairs as absolute last resort
    final fallbacks = {
      'USD_VND': 27500.0,
      'VND_USD': 0.0000364,
      'USD_EUR': 0.92,
      'EUR_USD': 1.09,
    };

    final key = '${fromCurrency}_$toCurrency';
    if (fallbacks.containsKey(key)) {
      return fallbacks[key];
    }

    // Try reverse
    final reverseKey = '${toCurrency}_$fromCurrency';
    if (fallbacks.containsKey(reverseKey)) {
      return 1.0 / fallbacks[reverseKey]!;
    }

    return null;
  }

  /// Convert amount from one currency to another
  Future<double> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Get multiple exchange rates at once (with caching)
  Future<Map<String, double>> getMultipleRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    final rates = <String, double>{};

    for (final targetCurrency in targetCurrencies) {
      if (targetCurrency == baseCurrency) {
        rates['${targetCurrency}_$baseCurrency'] = 1.0;
        continue;
      }

      try {
        final rate = await getExchangeRate(targetCurrency, baseCurrency);
        rates['${targetCurrency}_$baseCurrency'] = rate;
      } catch (e) {
        Log.w('Failed to get rate for $targetCurrency: $e', label: 'ExchangeRate');
        // Continue with other currencies even if one fails
      }
    }

    return rates;
  }

  /// Clear all cached rates (useful for debugging or forcing refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }

      Log.d('Cleared all cached exchange rates', label: 'ExchangeRate');
    } catch (e) {
      Log.e('Failed to clear cache: $e', label: 'ExchangeRate');
    }
  }
}
