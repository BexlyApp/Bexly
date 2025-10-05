import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
// import 'package:bexly/features/wallet/data/repositories/wallet_repo.dart'; // No longer needed for hardcoded list

/// Provider to stream all wallets from the database.
final allWalletsStreamProvider = StreamProvider.autoDispose<List<WalletModel>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.walletDao.watchAllWallets();
});

final walletAmountVisibilityProvider = StateProvider<bool>((ref) {
  // set default to visible
  return true;
});

/// StateNotifier for managing the active wallet.
class ActiveWalletNotifier extends StateNotifier<AsyncValue<WalletModel?>> {
  final Ref _ref;

  ActiveWalletNotifier(this._ref) : super(const AsyncValue.loading()) {
    initializeActiveWallet();
  }

  // Initialize with null to show total balance by default
  Future<void> initializeActiveWallet() async {
    try {
      // Default to showing total balance (null = show all wallets combined)
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void setActiveWallet(WalletModel? wallet) {
    state = AsyncValue.data(wallet);
  }

  void updateActiveWallet(WalletModel? newWalletData) {
    final currentActiveWallet = state.valueOrNull;
    final currentActiveWalletId = currentActiveWallet?.id;

    if (newWalletData != null && newWalletData.id == currentActiveWalletId) {
      // If the incoming wallet data is for the currently active wallet ID
      Log.d(
        'Updating active wallet ID ${newWalletData.id} with new data: ${newWalletData.toJson()}',
        label: 'ActiveWalletNotifier',
      );
      // Update the state with the new WalletModel instance.
      // This ensures watchers receive the new object.
      state = AsyncValue.data(newWalletData);
    } else if (newWalletData != null && currentActiveWalletId == null) {
      // This case is more for setActiveWallet, but if update is called when no active wallet, set it.
      Log.d(
        'Setting active wallet (was null) to ID ${newWalletData.id} via updateActiveWallet: ${newWalletData.toJson()}',
        label: 'ActiveWalletNotifier',
      );
      state = AsyncValue.data(newWalletData);
    } else if (newWalletData == null && currentActiveWalletId != null) {
      Log.d(
        'Clearing active wallet (was ID $currentActiveWalletId) via updateActiveWallet.',
        label: 'ActiveWalletNotifier',
      );
      state = const AsyncValue.data(null);
    }
  }

  /// Refreshes the data for the currently active wallet from the database.
  /// Useful if the wallet data might have changed externally or by other operations.
  Future<void> refreshActiveWallet() async {
    final currentWalletId = state.valueOrNull?.id;
    if (currentWalletId != null) {
      try {
        final db = _ref.read(databaseProvider);
        final refreshedWallet = await db.walletDao
            .watchWalletById(currentWalletId)
            .first;
        state = AsyncValue.data(refreshedWallet);
      } catch (e, s) {
        // Keep the old state but log error, or set to error state
        state = AsyncValue.error(e, s);
      }
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for the ActiveWalletNotifier, managing the currently selected wallet.
final activeWalletProvider =
    StateNotifierProvider<ActiveWalletNotifier, AsyncValue<WalletModel?>>((
      ref,
    ) {
      return ActiveWalletNotifier(ref);
    });

/// Provider to calculate total balance grouped by currency from all wallets.
/// Returns a Map where key is currency ISO code and value is total balance.
final totalBalanceProvider = Provider<Map<String, double>>((ref) {
  final walletsAsync = ref.watch(allWalletsStreamProvider);

  return walletsAsync.when(
    data: (wallets) {
      final Map<String, double> totals = {};

      for (final wallet in wallets) {
        final currency = wallet.currency;
        totals[currency] = (totals[currency] ?? 0.0) + wallet.balance;
      }

      return totals;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider to calculate total balance converted to base currency
/// This is async because it needs to fetch exchange rates
final totalBalanceConvertedProvider = FutureProvider<double>((ref) async {
  try {
    final walletsAsync = ref.watch(allWalletsStreamProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final rateCache = ref.watch(exchangeRateCacheProvider.notifier);

    // Wait for wallets to load
    final wallets = walletsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <WalletModel>[],
    );

    if (wallets.isEmpty) {
      return 0.0;
    }

    double total = 0.0;

    for (final wallet in wallets) {
      if (wallet.currency == baseCurrency) {
        // Same currency, just add
        total += wallet.balance;
      } else {
        // Convert to base currency
        try {
          final rate = await rateCache.getRate(wallet.currency, baseCurrency);
          total += wallet.balance * rate;
        } catch (e) {
          Log.e('Failed to get exchange rate for ${wallet.currency} -> $baseCurrency: $e', label: 'TotalBalance');
          // If rate fetch fails, just add the amount as-is (fallback)
          total += wallet.balance;
        }
      }
    }

    return total;
  } catch (e) {
    Log.e('Error calculating total balance: $e', label: 'TotalBalance');
    return 0.0;
  }
});
