import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/exchange_rate_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Provider for the default wallet ID setting
/// This wallet is used for:
/// - AI context when viewing "All Wallets"
/// - Base currency derivation for dashboard aggregation
class DefaultWalletIdNotifier extends Notifier<int?> {
  static const _key = 'default_wallet_id';

  @override
  int? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_key);
      if (saved != null) {
        state = saved;
        Log.d('Loaded default wallet ID: $saved', label: 'DefaultWallet');
      } else {
        // Initialize from first wallet
        await _initializeFromFirstWallet();
      }
    } catch (e) {
      Log.e('Error loading default wallet ID: $e', label: 'DefaultWallet');
    }
  }

  /// Public method to re-initialize default wallet from first wallet
  /// Call this after resetting data
  Future<void> initializeFromFirstWallet() async {
    await _initializeFromFirstWallet();
  }

  Future<void> _initializeFromFirstWallet() async {
    try {
      final db = ref.read(databaseProvider);
      final wallets = await db.walletDao.watchAllWallets().first;

      if (wallets.isNotEmpty) {
        // Get first wallet (by ID order)
        final firstWallet = wallets.reduce((a, b) => (a.id ?? 0) < (b.id ?? 0) ? a : b);
        await setDefaultWalletId(firstWallet.id!);
        Log.d('Initialized default wallet from first wallet: ${firstWallet.id}', label: 'DefaultWallet');
      } else {
        state = null;
        Log.d('No wallets found, default wallet is null', label: 'DefaultWallet');
      }
    } catch (e) {
      Log.e('Error initializing default wallet: $e', label: 'DefaultWallet');
      state = null;
    }
  }

  Future<void> setDefaultWalletId(int walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, walletId);
      state = walletId;
      Log.d('Set default wallet ID: $walletId', label: 'DefaultWallet');

      // Sync to Firestore for Telegram bot to use
      await _syncDefaultWalletToCloud(walletId);
    } catch (e) {
      Log.e('Error saving default wallet ID: $e', label: 'DefaultWallet');
    }
  }

  /// Sync default wallet cloudId to Supabase (removed Firestore sync)
  Future<void> _syncDefaultWalletToCloud(int walletId) async {
    // TODO: Implement Supabase sync for default wallet setting
    // This was previously syncing to Firestore for Telegram bot
    // Now we should sync to Supabase user settings table
    Log.d('Default wallet sync to cloud not implemented yet', label: 'DefaultWallet');
  }

  Future<void> clearDefaultWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      state = null;
      Log.d('Cleared default wallet ID', label: 'DefaultWallet');
    } catch (e) {
      Log.e('Error clearing default wallet ID: $e', label: 'DefaultWallet');
    }
  }
}

final defaultWalletIdProvider = NotifierProvider<DefaultWalletIdNotifier, int?>(
  DefaultWalletIdNotifier.new,
);

/// Provider for the default wallet model (resolved from ID)
final defaultWalletProvider = FutureProvider<WalletModel?>((ref) async {
  final defaultWalletId = ref.watch(defaultWalletIdProvider);
  if (defaultWalletId == null) return null;

  final db = ref.read(databaseProvider);
  final wallets = await db.walletDao.watchAllWallets().first;

  return wallets.cast<WalletModel?>().firstWhere(
    (w) => w?.id == defaultWalletId,
    orElse: () => wallets.isNotEmpty ? wallets.first : null,
  );
});

/// Provider for the base currency setting
/// Now derived from default wallet's currency
final baseCurrencyProvider = Provider<String>((ref) {
  final defaultWallet = ref.watch(defaultWalletProvider);
  return defaultWallet.when(
    data: (wallet) => wallet?.currency ?? 'VND',
    loading: () => 'VND',
    error: (_, __) => 'VND',
  );
});

/// Provider for ExchangeRateService
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return ExchangeRateService(geminiApiKey: apiKey);
});

/// Provider for cached exchange rates
/// Key format: "FROM_TO" (e.g., "USD_VND")
/// Cache expires after 1 hour
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

class ExchangeRateCacheNotifier extends Notifier<Map<String, CachedRate>> {
  @override
  Map<String, CachedRate> build() {
    return {};
  }

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
    final service = ref.read(exchangeRateServiceProvider);
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

final exchangeRateCacheProvider = NotifierProvider<ExchangeRateCacheNotifier, Map<String, CachedRate>>(
  ExchangeRateCacheNotifier.new,
);
