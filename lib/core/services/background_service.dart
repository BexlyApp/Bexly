import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/recurring_charge_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

/// Task names for WorkManager
const String recurringChargeTask = 'recurringChargeTask';
const String recurringChargeTaskUnique = 'recurringChargeTaskUnique';

/// Callback dispatcher for WorkManager - MUST be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    Log.d('Background task started: $task', label: 'BackgroundService');

    try {
      switch (task) {
        case recurringChargeTask:
          await _processRecurringCharges();
          break;
        default:
          Log.w('Unknown background task: $task', label: 'BackgroundService');
      }

      Log.d('Background task completed: $task', label: 'BackgroundService');
      return true;
    } catch (e, stack) {
      Log.e('Background task failed: $e', label: 'BackgroundService');
      Log.e('Stack: $stack', label: 'BackgroundService');
      return false;
    }
  });
}

/// Process recurring charges in background
/// Note: This runs outside of normal app context, so we need to create providers manually
Future<void> _processRecurringCharges() async {
  Log.d('Processing recurring charges in background...', label: 'BackgroundService');

  // Create a minimal container for background execution
  final container = ProviderContainer();

  try {
    // Initialize database
    final db = container.read(databaseProvider);

    // Wait for database to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Create charge service with container ref
    final chargeService = RecurringChargeService(container.read as dynamic);

    // Process due transactions
    // Note: We can't use the service directly since it needs Ref
    // Instead, we'll do a simplified version here
    final activeRecurrings = await db.recurringDao.watchActiveRecurrings().first;

    Log.d('Found ${activeRecurrings.length} active recurring payments in background',
          label: 'BackgroundService');

    // For now, just log - actual charging should be done when app opens
    // This is because we need full app context for proper transaction creation
    // Background task mainly serves as a reminder/trigger

  } finally {
    container.dispose();
  }
}

/// Background service manager
class BackgroundService {
  static bool _initialized = false;

  /// Initialize WorkManager for background tasks
  static Future<void> initialize() async {
    if (_initialized) {
      Log.d('BackgroundService already initialized', label: 'BackgroundService');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );

      _initialized = true;
      Log.i('BackgroundService initialized successfully', label: 'BackgroundService');
    } catch (e, stack) {
      Log.e('Failed to initialize BackgroundService: $e', label: 'BackgroundService');
      Log.e('Stack: $stack', label: 'BackgroundService');
    }
  }

  /// Schedule daily recurring charge check
  /// Runs once per day at approximately the same time
  static Future<void> scheduleRecurringChargeTask() async {
    if (!_initialized) {
      Log.w('BackgroundService not initialized, call initialize() first', label: 'BackgroundService');
      return;
    }

    try {
      // Cancel existing task first to avoid duplicates
      await Workmanager().cancelByUniqueName(recurringChargeTaskUnique);

      // Schedule periodic task - runs approximately every 24 hours
      await Workmanager().registerPeriodicTask(
        recurringChargeTaskUnique,
        recurringChargeTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      Log.i('Scheduled recurring charge task (every 24 hours)', label: 'BackgroundService');
    } catch (e, stack) {
      Log.e('Failed to schedule recurring charge task: $e', label: 'BackgroundService');
      Log.e('Stack: $stack', label: 'BackgroundService');
    }
  }

  /// Cancel all scheduled tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      Log.i('Cancelled all background tasks', label: 'BackgroundService');
    } catch (e) {
      Log.e('Failed to cancel background tasks: $e', label: 'BackgroundService');
    }
  }

  /// Run recurring charge task immediately (for testing)
  static Future<void> runRecurringChargeNow() async {
    if (!_initialized) {
      Log.w('BackgroundService not initialized', label: 'BackgroundService');
      return;
    }

    try {
      await Workmanager().registerOneOffTask(
        'recurringChargeImmediate_${DateTime.now().millisecondsSinceEpoch}',
        recurringChargeTask,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );

      Log.i('Triggered immediate recurring charge task', label: 'BackgroundService');
    } catch (e) {
      Log.e('Failed to trigger immediate task: $e', label: 'BackgroundService');
    }
  }
}
