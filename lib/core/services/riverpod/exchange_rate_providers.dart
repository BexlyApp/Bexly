import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/exchange_rate_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Provider for the base currency setting (default: VND)
final baseCurrencyProvider = StateNotifierProvider<BaseCurrencyNotifier, String>((ref) {
  return BaseCurrencyNotifier(ref);
});

class BaseCurrencyNotifier extends StateNotifier<String> {
  static const _key = 'base_currency';
  final Ref _ref;

  BaseCurrencyNotifier(this._ref) : super('VND') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.isNotEmpty) {
        state = saved;
        Log.d('Loaded base currency: $saved', label: 'BaseCurrency');
      } else {
        // Initialize from first wallet currency
        await _initializeFromFirstWallet();
      }
    } catch (e) {
      Log.e('Error loading base currency: $e', label: 'BaseCurrency');
    }
  }

  /// Public method to re-initialize base currency from first wallet
  /// Call this after resetting data
  Future<void> initializeFromFirstWallet() async {
    await _initializeFromFirstWallet();
  }

  Future<void> _initializeFromFirstWallet() async {
    try {
      final db = _ref.read(databaseProvider);
      final wallets = await db.walletDao.watchAllWallets().first;

      if (wallets.isNotEmpty) {
        // Get first wallet (by ID order)
        final firstWallet = wallets.reduce((a, b) => (a.id ?? 0) < (b.id ?? 0) ? a : b);
        final currency = firstWallet.currency;
        await setBaseCurrency(currency);
        Log.d('Initialized base currency from first wallet: $currency', label: 'BaseCurrency');
      } else {
        // Fallback to VND if no wallets
        state = 'VND';
        Log.d('No wallets found, using VND as fallback', label: 'BaseCurrency');
      }
    } catch (e) {
      Log.e('Error initializing base currency from wallet: $e', label: 'BaseCurrency');
      state = 'VND'; // Fallback
    }
  }

  Future<void> setBaseCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, currency);
      state = currency;
      Log.d('Set base currency: $currency', label: 'BaseCurrency');
    } catch (e) {
      Log.e('Error saving base currency: $e', label: 'BaseCurrency');
    }
  }
}

/// Provider for ExchangeRateService
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return ExchangeRateService(geminiApiKey: apiKey);
});

/// Provider for cached exchange rates
/// Key format: "FROM_TO" (e.g., "USD_VND")
/// Cache expires after 1 hour
final exchangeRateCacheProvider = StateNotifierProvider<ExchangeRateCacheNotifier, Map<String, CachedRate>>((ref) {
  return ExchangeRateCacheNotifier(ref);
});

class CachedRate {
  final double rate;
  final DateTime fetchedAt;

  CachedRate({required this.rate, required this.fetchedAt});

  bool get isExpired {
    final now = DateTime.now();
    final diff = now.difference(fetchedAt);
    return diff.inHours >= 1; // Cache for 1 hour
  }
}

class ExchangeRateCacheNotifier extends StateNotifier<Map<String, CachedRate>> {
  final Ref _ref;

  ExchangeRateCacheNotifier(this._ref) : super({});

  /// Get exchange rate with caching
  Future<double> getRate(String fromCurrency, String toCurrency) async {
    final key = '${fromCurrency}_$toCurrency';

    // Check cache
    final cached = state[key];
    if (cached != null && !cached.isExpired) {
      Log.d('Using cached rate for $key: ${cached.rate}', label: 'ExchangeRate');
      return cached.rate;
    }

    // Fetch new rate
    Log.d('Fetching new rate for $key', label: 'ExchangeRate');
    final service = _ref.read(exchangeRateServiceProvider);
    final rate = await service.getExchangeRate(fromCurrency, toCurrency);

    // Update cache
    state = {
      ...state,
      key: CachedRate(rate: rate, fetchedAt: DateTime.now()),
    };

    return rate;
  }

  /// Clear all cached rates
  void clearCache() {
    state = {};
    Log.d('Cleared exchange rate cache', label: 'ExchangeRate');
  }

  /// Clear specific rate from cache
  void clearRate(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency}_$toCurrency';
    state = Map.from(state)..remove(key);
    Log.d('Cleared cached rate for $key', label: 'ExchangeRate');
  }
}
