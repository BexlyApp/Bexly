import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/services/budget_renewal_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';
import 'package:bexly/core/database/migrations/migrate_existing_goals_to_cloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/subscription/ai_usage_service.dart';
import 'package:bexly/core/services/churn_prevention_service.dart';

/// Widget that manages app lifecycle and triggers recurring charge checks
/// when app resumes from background
class LifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleManager({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends ConsumerState<LifecycleManager>
    with WidgetsBindingObserver {
  DateTime? _lastChargeCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't set _lastChargeCheck here - let first check happen on app start
    // _lastChargeCheck = DateTime.now();

    // CRITICAL: Ensure categories exist on app startup
    // This fixes the bug where categories are lost after pm clear
    // Also run auto-migration, pull cloud data, and check for due recurring payments on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureCategoriesExist();
      await _ensureInitialCategorySync();
      await _runAutoMigration();
      await _pullCloudData();
      _checkRecurringPayments();
      _checkRoutineBudgets();
      _recordAppOpenAndScheduleReengagement();
    });
  }

  /// Ensure categories exist on app startup
  /// This is critical because database onCreate only runs on FIRST creation
  /// When user does pm clear, database file persists so onCreate doesn't run
  Future<void> _ensureCategoriesExist() async {
    try {
      Log.d('🔍 Checking if categories exist...', label: 'LifecycleManager');
      print('🔍 [LifecycleManager] Checking if categories exist...');

      final db = ref.read(databaseProvider);
      final categories = await db.categoryDao.getAllCategories();

      if (categories.isEmpty) {
        Log.i('⚠️ No categories found! Creating default categories...', label: 'LifecycleManager');
        print('⚠️ [LifecycleManager] No categories found! Creating default categories...');
        await CategoryPopulationService.populate(db);

        final newCategories = await db.categoryDao.getAllCategories();
        Log.i('✅ Created ${newCategories.length} default categories', label: 'LifecycleManager');
        print('✅ [LifecycleManager] Created ${newCategories.length} default categories');
      } else {
        Log.d('✅ Categories already exist: ${categories.length}', label: 'LifecycleManager');
        print('✅ [LifecycleManager] Categories already exist: ${categories.length}');
      }
    } catch (e, stackTrace) {
      Log.e('❌ Error ensuring categories exist: $e', label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
      print('❌ [LifecycleManager] Error ensuring categories exist: $e');
    }
  }

  /// Ensure initial category sync on first login
  /// This syncs ALL categories to cloud once, then uses Modified Hybrid Sync
  /// for incremental updates (only modified/custom categories)
  Future<void> _ensureInitialCategorySync() async {
    try {
      Log.d('🔍 Checking if initial category sync needed...', label: 'LifecycleManager');
      print('🔍 [LifecycleManager] Checking if initial category sync needed...');

      final syncService = ref.read(supabaseSyncServiceProvider);

      // Only sync if user is authenticated
      if (!syncService.isAuthenticated) {
        Log.d('⏭️ User not authenticated, skipping initial category sync', label: 'LifecycleManager');
        print('⏭️ [LifecycleManager] User not authenticated, skipping initial category sync');
        return;
      }

      // Trigger initial category sync (will check cloud and sync if needed)
      Log.d('🚀 Triggering initial category sync...', label: 'LifecycleManager');
      print('🚀 [LifecycleManager] Triggering initial category sync...');

      await syncService.syncCategoriesToCloud();

      Log.i('✅ Initial category sync completed', label: 'LifecycleManager');
      print('✅ [LifecycleManager] Initial category sync completed');
    } catch (e, stackTrace) {
      Log.e('❌ Error during initial category sync: $e', label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
      print('❌ [LifecycleManager] Error during initial category sync: $e');
      // Don't throw - app should continue even if sync fails
    }
  }

  /// Pull cloud data to local database on app startup/login
  /// This downloads chat messages and other data from Supabase to local DB
  Future<void> _pullCloudData() async {
    try {
      Log.d('🔍 Checking if cloud data pull needed...', label: 'LifecycleManager');
      print('🔍 [LifecycleManager] Checking if cloud data pull needed...');

      final syncService = ref.read(supabaseSyncServiceProvider);

      // Only pull if user is authenticated
      if (!syncService.isAuthenticated) {
        Log.d('⏭️ User not authenticated, skipping cloud data pull', label: 'LifecycleManager');
        print('⏭️ [LifecycleManager] User not authenticated, skipping cloud data pull');
        return;
      }

      // Pull chat messages from cloud
      Log.d('📥 Pulling chat messages from cloud...', label: 'LifecycleManager');
      print('📥 [LifecycleManager] Pulling chat messages from cloud...');

      final db = ref.read(databaseProvider);
      await syncService.pullChatMessagesFromCloud(db.chatMessageDao);

      Log.i('✅ Cloud data pull completed', label: 'LifecycleManager');
      print('✅ [LifecycleManager] Cloud data pull completed');
    } catch (e, stackTrace) {
      Log.e('❌ Error pulling cloud data: $e', label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
      print('❌ [LifecycleManager] Error pulling cloud data: $e');
      // Don't throw - app should continue even if pull fails
    }
  }

  /// Run automatic migration on app startup/login (once per device)
  /// This uploads existing local data (created before sync feature) to cloud
  Future<void> _runAutoMigration() async {
    const migrationKey = 'auto_migration_completed_v1';

    try {
      Log.d('🔍 Checking if auto-migration needed...', label: 'LifecycleManager');
      print('🔍 [LifecycleManager] Checking if auto-migration needed...');

      final prefs = ref.read(sharedPreferencesProvider);
      final syncService = ref.read(supabaseSyncServiceProvider);

      // Only migrate if user is authenticated
      if (!syncService.isAuthenticated) {
        Log.d('⏭️ User not authenticated, skipping auto-migration', label: 'LifecycleManager');
        print('⏭️ [LifecycleManager] User not authenticated, skipping auto-migration');
        return;
      }

      // Check if migration already completed
      final migrationCompleted = prefs.getBool(migrationKey) ?? false;
      if (migrationCompleted) {
        Log.d('⏭️ Auto-migration already completed, skipping', label: 'LifecycleManager');
        print('⏭️ [LifecycleManager] Auto-migration already completed, skipping');
        return;
      }

      // Run migration
      Log.d('🚀 Starting automatic migration of existing data...', label: 'LifecycleManager');
      print('🚀 [LifecycleManager] Starting automatic migration of existing data...');

      final db = ref.read(databaseProvider);
      await MigrateExistingGoalsToCloud.runMigration(db, syncService);

      // Mark migration as completed
      await prefs.setBool(migrationKey, true);

      Log.i('✅ Auto-migration completed successfully', label: 'LifecycleManager');
      print('✅ [LifecycleManager] Auto-migration completed successfully');
    } catch (e, stackTrace) {
      Log.e('❌ Error during auto-migration: $e', label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
      print('❌ [LifecycleManager] Error during auto-migration: $e');
      // Don't throw - app should continue even if migration fails
      // User can still manually trigger migration from Developer Portal
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes, check for due recurring payments
    if (state == AppLifecycleState.resumed) {
      _checkRecurringPayments();
    }
  }

  Future<void> _checkRecurringPayments() async {
    try {
      Log.d('🔍 Starting recurring payment check...', label: 'LifecycleManager');
      print('🔍 [LifecycleManager] Starting recurring payment check...');

      // Debounce: Don't check more than once per hour
      if (_lastChargeCheck != null) {
        final hoursSinceLastCheck =
            DateTime.now().difference(_lastChargeCheck!).inHours;
        if (hoursSinceLastCheck < 1) {
          Log.d(
              '⏭️ Skipping recurring check - last check was $hoursSinceLastCheck hours ago',
              label: 'LifecycleManager');
          print('⏭️ [LifecycleManager] Skipping recurring check - last check was $hoursSinceLastCheck hours ago');
          return;
        }
      }

      Log.d('✅ Passed debounce check - proceeding with recurring check',
          label: 'LifecycleManager');
      print('✅ [LifecycleManager] Passed debounce check - proceeding with recurring check');

      final recurringService = ref.read(recurringChargeServiceProvider);
      Log.d('📦 Got recurring service, calling createDueTransactions()',
          label: 'LifecycleManager');
      print('📦 [LifecycleManager] Got recurring service, calling createDueTransactions()');

      await recurringService.createDueTransactions();

      _lastChargeCheck = DateTime.now();

      Log.d('✅ Recurring payment check completed', label: 'LifecycleManager');
      print('✅ [LifecycleManager] Recurring payment check completed');
    } catch (e, stackTrace) {
      Log.e('❌ Error checking recurring payments on app resume: $e',
          label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
      print('❌ [LifecycleManager] Error checking recurring payments: $e');
      print('❌ [LifecycleManager] Stack trace: $stackTrace');
    }
  }

  Future<void> _checkRoutineBudgets() async {
    try {
      Log.d('Checking routine budgets for renewal...', label: 'LifecycleManager');
      final budgetDao = ref.read(budgetDaoProvider);
      final renewalService = BudgetRenewalService(budgetDao);
      await renewalService.createDueRoutineBudgets();
    } catch (e, stackTrace) {
      Log.e('Error checking routine budgets: $e', label: 'LifecycleManager');
      Log.e('Stack trace: $stackTrace', label: 'LifecycleManager');
    }
  }

  /// Record app open and reschedule re-engagement notifications
  Future<void> _recordAppOpenAndScheduleReengagement() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await ChurnPreventionService.recordAppOpen(prefs);
      await ChurnPreventionService.scheduleReengagement();
    } catch (e) {
      Log.e('Error in churn prevention: $e', label: 'LifecycleManager');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
