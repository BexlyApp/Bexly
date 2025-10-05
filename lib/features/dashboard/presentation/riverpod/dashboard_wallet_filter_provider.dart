import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Local state for dashboard wallet filter
/// This is NOT a global state - only affects Home/Dashboard screen
/// null = show Total (all wallets combined)
final dashboardWalletFilterProvider = StateProvider<WalletModel?>((ref) {
  // Default to null = show Total
  return null;
});
