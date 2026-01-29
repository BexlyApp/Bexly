import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub provider for realtime sync service (removed Firebase implementation)
/// TODO: Implement Supabase realtime sync
final realtimeSyncServiceProvider = Provider<RealtimeSyncService?>((ref) {
  return null; // No sync service available
});

/// Stub class for realtime sync service
class RealtimeSyncService {
  // Removed Firebase realtime sync implementation
  // TODO: Implement Supabase realtime subscriptions

  // Stub properties
  bool get isAuthenticated => false;

  // Stub methods for DAO compatibility
  Future<void> uploadBudget(dynamic budget) async {}
  Future<void> deleteBudgetFromCloud(String cloudId) async {}
  Future<bool> deleteBudgetFromCloudByMatch({
    required String categoryCloudId,
    required String walletCloudId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
  }) async => false;

  Future<void> uploadCategory(dynamic category) async {}
  Future<void> deleteCategoryFromCloud(String cloudId) async {}

  Future<void> uploadGoal(dynamic goal) async {}
  Future<void> deleteGoalFromCloud(String cloudId) async {}

  Future<void> uploadTransaction(dynamic transaction) async {}
  Future<void> deleteTransactionFromCloud(String cloudId) async {}

  Future<void> uploadWallet(dynamic wallet) async {}
  Future<void> deleteWalletFromCloud(String cloudId) async {}
}
