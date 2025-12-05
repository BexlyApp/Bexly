import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:bexly/core/constants/app_constants.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';

class CurrencyLocalDataSource {
  Future<List<dynamic>> getCurrencies() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/currencies.json',
    );
    final jsonList = jsonDecode(jsonString);
    Log.d(jsonList, label: 'currencies', logToFile: false);
    // Log.d('currencies: ${jsonList.runtimeType}');
    return jsonList['currencies'];
  }

  static const Currency dummy = Currency(
    symbol: AppConstants.defaultCurrencySymbol,
    name: 'United States Dollar',
    decimalDigits: 2,
    rounding: 0,
    isoCode: 'USD',
    namePlural: 'US Dollars',
    country: 'United States',
    countryCode: 'US',
  );

  /// Mapping of country/language codes to currency ISO codes
  /// Used to detect default currency from device locale
  static const Map<String, String> _localeToCurrency = {
    // Country codes (from Locale.countryCode)
    'VN': 'VND',
    'US': 'USD',
    'GB': 'GBP',
    'AU': 'AUD',
    'CA': 'CAD',
    'JP': 'JPY',
    'CN': 'CNY',
    'KR': 'KRW',
    'TH': 'THB',
    'ID': 'IDR',
    'MY': 'MYR',
    'SG': 'SGD',
    'PH': 'PHP',
    'IN': 'INR',
    'BR': 'BRL',
    'MX': 'MXN',
    'CH': 'CHF',
    'HK': 'HKD',
    'TW': 'TWD',
    'NZ': 'NZD',
    // Language codes (fallback when country code is not available)
    'vi': 'VND',
    'en': 'USD',
    'ja': 'JPY',
    'zh': 'CNY',
    'ko': 'KRW',
    'th': 'THB',
    'id': 'IDR',
    'ms': 'MYR',
    'tl': 'PHP',
    'hi': 'INR',
    'pt': 'BRL',
    'es': 'MXN',
    'fr': 'EUR',
    'de': 'EUR',
    'it': 'EUR',
  };

  /// Get currency ISO code from locale
  /// Priority: country code -> language code -> USD (default)
  static String getCurrencyCodeFromLocale(String? countryCode, String? languageCode) {
    // Try country code first (more accurate)
    if (countryCode != null && _localeToCurrency.containsKey(countryCode)) {
      return _localeToCurrency[countryCode]!;
    }
    // Fallback to language code
    if (languageCode != null && _localeToCurrency.containsKey(languageCode)) {
      return _localeToCurrency[languageCode]!;
    }
    // Default to USD
    return 'USD';
  }

  List<String> getAvailableCurrencies() {
    return ['ID', 'SG', 'MY', 'CN', 'JP', 'US', 'GB'];
  }
}
