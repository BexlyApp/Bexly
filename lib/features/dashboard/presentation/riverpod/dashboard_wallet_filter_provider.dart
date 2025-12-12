import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Local state for dashboard wallet filter
/// This is NOT a global state - only affects Home/Dashboard screen
/// null = show Total (all wallets combined)
class DashboardWalletFilterNotifier extends Notifier<WalletModel?> {
  @override
  WalletModel? build() => null; // Default to null = show Total

  void setWallet(WalletModel? wallet) => state = wallet;
}

final dashboardWalletFilterProvider = NotifierProvider<DashboardWalletFilterNotifier, WalletModel?>(
  DashboardWalletFilterNotifier.new,
);
