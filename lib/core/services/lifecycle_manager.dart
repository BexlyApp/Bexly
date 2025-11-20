import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/data_population_service/category_population_service.dart';

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
    // Also check for due recurring payments on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCategoriesExist();
      _checkRecurringPayments();
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
