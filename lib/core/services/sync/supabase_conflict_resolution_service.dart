import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/data_population_service/wallet_population_service.dart';

/// Data structure for sync conflict information
class SupabaseSyncConflictInfo {
  final int localItemCount;
  final int cloudItemCount;
  final DateTime? localLastUpdate;
  final DateTime? cloudLastUpdate;
  final String? latestLocalTransaction;
  final String? latestCloudTransaction;
  final int localWalletCount;
  final int cloudWalletCount;
  final int localTransactionCount;
  final int cloudTransactionCount;
  final int localGoalCount;
  final int cloudGoalCount;
  final int localBudgetCount;
  final int cloudBudgetCount;

  SupabaseSyncConflictInfo({
    required this.localItemCount,
    required this.cloudItemCount,
    this.localLastUpdate,
    this.cloudLastUpdate,
    this.latestLocalTransaction,
    this.latestCloudTransaction,
    required this.localWalletCount,
    required this.cloudWalletCount,
    required this.localTransactionCount,
    required this.cloudTransactionCount,
    required this.localGoalCount,
    required this.cloudGoalCount,
    required this.localBudgetCount,
    required this.cloudBudgetCount,
  });
}

/// Service to handle conflict detection and resolution for Supabase sync
class SupabaseConflictResolutionService {
  final AppDatabase _localDb;
  final SupabaseClient _supabase;
  final String _userId;
  final WalletDao? _walletDao;

  static const String _label = 'SupabaseConflictResolution';

  SupabaseConflictResolutionService({
    required AppDatabase localDb,
    required SupabaseClient supabase,
    required String userId,
    WalletDao? walletDao,
  })  : _localDb = localDb,
        _supabase = supabase,
        _userId = userId,
        _walletDao = walletDao;

  /// Check if there's a conflict between local and cloud data
  Future<SupabaseSyncConflictInfo?> detectConflict() async {
    try {
      Log.i('🔍 Checking for sync conflicts...', label: _label);

      // Count cloud data
      final cloudWalletsCount = await _supabase
          .schema('bexly')
          .from('wallets')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', _userId)
          .count();

      final cloudTransactionsCount = await _supabase
          .schema('bexly')
          .from('transactions')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', _userId)
          .count();

      final cloudGoalsCount = await _supabase
          .schema('bexly')
          .from('goals')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', _userId)
          .count();

      final cloudBudgetsCount = await _supabase
          .schema('bexly')
          .from('budgets')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', _userId)
          .count();

      // If no cloud data exists, no conflict
      if (cloudWalletsCount == 0 &&
          cloudTransactionsCount == 0 &&
          cloudGoalsCount == 0 &&
          cloudBudgetsCount == 0) {
        Log.i('No cloud data found, no conflict', label: _label);
        return null;
      }

      // Get local data counts
      final localWallets = await _localDb.walletDao.getAllWallets();
      final localTransactions = await _localDb.transactionDao.getAllTransactions();
      final localGoals = await _localDb.goalDao.getAllGoals();
      final localBudgets = await _localDb.budgetDao.getAllBudgets();

      // If no local data, no conflict (can safely download cloud data)
      if (localWallets.isEmpty &&
          localTransactions.isEmpty &&
          localGoals.isEmpty &&
          localBudgets.isEmpty) {
        Log.i('No local data found, no conflict', label: _label);
        return null;
      }

      // Both local and cloud have data - potential conflict detected!
      Log.w('Potential conflict: both local and cloud have data', label: _label);

      // AUTO-RESOLVE LOGIC: Check if this is a trivial conflict that can be auto-resolved

      // Rule 1: If data is already synced (matching cloudIds) → No conflict
      final localWalletsWithCloudId = localWallets.where((w) => w.cloudId != null).length;
      final localTransactionsWithCloudId = localTransactions.where((t) => t.cloudId != null).length;
      final localGoalsWithCloudId = localGoals.where((g) => g.cloudId != null).length;
      final localBudgetsWithCloudId = localBudgets.where((b) => b.cloudId != null).length;

      // If all local items have cloudId and counts match, data is synced
      if (localWalletsWithCloudId == localWallets.length &&
          localTransactionsWithCloudId == localTransactions.length &&
          localGoalsWithCloudId == localGoals.length &&
          localBudgetsWithCloudId == localBudgets.length &&
          localWallets.length == cloudWalletsCount &&
          localTransactions.length == cloudTransactionsCount &&
          localGoals.length == cloudGoalsCount &&
          localBudgets.length == cloudBudgetsCount) {
        Log.i('✅ Auto-resolve: All local data already synced to cloud (matching cloudIds). No conflict needed.', label: _label);
        return null;
      }

      // Rule 2: If both have same counts and ZERO transactions → Auto-merge (no data loss risk)
      if (localWallets.length == cloudWalletsCount &&
          localTransactions.isEmpty &&
          cloudTransactionsCount == 0 &&
          localGoals.isEmpty &&
          cloudGoalsCount == 0 &&
          localBudgets.isEmpty &&
          cloudBudgetsCount == 0) {
        Log.i('✅ Auto-resolve: Same wallet count and no transactions/goals/budgets on either side. No conflict needed.', label: _label);
        return null;
      }

      // If we reach here, it's a real conflict that needs user decision
      Log.w('⚠️ Real conflict detected - user decision required', label: _label);

      // Get latest transaction info
      String? latestLocalTx;
      DateTime? localLastUpdate;
      if (localTransactions.isNotEmpty) {
        final latest = localTransactions.reduce((a, b) =>
            a.updatedAt.isAfter(b.updatedAt) ? a : b);
        latestLocalTx = '${latest.title} (${latest.amount})';
        localLastUpdate = latest.updatedAt;
      }

      // Get latest cloud transaction
      String? latestCloudTx;
      DateTime? cloudLastUpdate;
      try {
        final latestCloudTransaction = await _supabase
            .schema('bexly')
            .from('transactions')
            .select()
            .eq('user_id', _userId)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (latestCloudTransaction != null) {
          cloudLastUpdate = latestCloudTransaction['updated_at'] != null
              ? DateTime.parse(latestCloudTransaction['updated_at'])
              : null;
          latestCloudTx = '${latestCloudTransaction['title']} (${latestCloudTransaction['amount']})';
        }
      } catch (e) {
        Log.w('Failed to get latest cloud transaction: $e', label: _label);
      }

      return SupabaseSyncConflictInfo(
        localItemCount: localWallets.length + localTransactions.length + localGoals.length + localBudgets.length,
        cloudItemCount: cloudWalletsCount + cloudTransactionsCount + cloudGoalsCount + cloudBudgetsCount,
        localLastUpdate: localLastUpdate,
        cloudLastUpdate: cloudLastUpdate,
        latestLocalTransaction: latestLocalTx,
        latestCloudTransaction: latestCloudTx,
        localWalletCount: localWallets.length,
        cloudWalletCount: cloudWalletsCount,
        localTransactionCount: localTransactions.length,
        cloudTransactionCount: cloudTransactionsCount,
        localGoalCount: localGoals.length,
        cloudGoalCount: cloudGoalsCount,
        localBudgetCount: localBudgets.length,
        cloudBudgetCount: cloudBudgetsCount,
      );
    } catch (e, stack) {
      Log.e('Error detecting conflict: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return null;
    }
  }

  /// Replace local data with cloud data
  Future<void> useCloudData() async {
    try {
      Log.i('Using cloud data, clearing local data...', label: _label);

      // Clear all local data EXCEPT system default categories
      // IMPORTANT: Delete in correct order to avoid foreign key constraint violations
      await _localDb.transaction(() async {
        // 1. Delete child tables first (no dependencies)
        await _localDb.delete(_localDb.checklistItems).go();

        // 2. Delete tables that reference wallets
        await _localDb.delete(_localDb.transactions).go();
        await _localDb.delete(_localDb.budgets).go();
        await _localDb.delete(_localDb.goals).go();
        await _localDb.delete(_localDb.recurrings).go();

        // 3. Now safe to delete wallets
        await _localDb.delete(_localDb.wallets).go();

        // 4. Categories - only delete non-system to preserve defaults
        await (_localDb.delete(_localDb.categories)
          ..where((c) => c.isSystemDefault.equals(false)))
          .go();
      });

      Log.i('✅ Local data cleared, ready to pull from cloud', label: _label);

      // Sync service will handle downloading cloud data via performFullSync()
      // Just ensure we have at least one wallet and categories after
    } catch (e, stack) {
      Log.e('❌ Failed to use cloud data: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Keep local data and upload to cloud (overwrite cloud)
  Future<void> useLocalData() async {
    try {
      Log.i('Using local data, will clear cloud and upload...', label: _label);

      // Clear cloud data
      await _clearCloudData();

      Log.i('✅ Cleared cloud data, ready for local upload', label: _label);

      // Sync service will handle uploading local data via performFullSync()
    } catch (e, stack) {
      Log.e('❌ Failed to use local data: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }

  /// Clear all cloud data for the user
  Future<void> _clearCloudData() async {
    try {
      Log.i('🔍 Clearing cloud data...', label: _label);

      // Delete in dependency order (children first)
      await _supabase
          .schema('bexly')
          .from('checklist_items')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('transactions')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('budgets')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('goals')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('recurring_transactions')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('wallets')
          .delete()
          .eq('user_id', _userId);

      await _supabase
          .schema('bexly')
          .from('categories')
          .delete()
          .eq('user_id', _userId);

      Log.i('✅ Cloud data cleared', label: _label);
    } catch (e, stack) {
      Log.e('Error clearing cloud data: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      rethrow;
    }
  }
}
