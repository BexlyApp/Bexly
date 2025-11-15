import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  final Ref? _ref;

  GoalDao(super.db, [this._ref]);

  // ─── CRUD for Goals ─────────────────────────────

  /// Inserts a new Goal, returns its auto-incremented ID
  Future<int> addGoal(GoalsCompanion entry) async {
    Log.d('addGoal → ${entry.toString()}', label: 'goal');

    // 1. Save to local database
    final id = await into(goals).insert(entry);
    Log.d('Goal inserted with id=$id', label: 'goal');

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        final savedGoal = await getGoalById(id);
        if (savedGoal != null) {
          await syncService.uploadGoal(savedGoal.toModel());
        }
      } catch (e, stack) {
        Log.e('Failed to upload goal to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local save succeeded
      }
    }

    return id;
  }

  /// Streams all goals; logs each emission
  Stream<List<Goal>> watchAllGoals() {
    Log.d('Subscribing to watchAllGoals()', label: 'goal');
    return select(goals).watch().map((list) {
      Log.d('watchAllGoals emitted ${list.length} rows', label: 'goal');
      return list;
    });
  }

  /// Fetches all goals.
  Future<List<Goal>> getAllGoals() {
    return select(goals).get();
  }

  /// Streams single goal;
  Stream<Goal> watchGoalByID(int id) {
    Log.d('Subscribing to watchGoalByID($id)', label: 'goal');
    return (select(goals)..where((g) => g.id.equals(id))).watchSingle();
  }

  /// Fetches a single goal by its ID, or null if not found.
  Future<Goal?> getGoalById(int id) {
    Log.d('Fetching getGoalById(id=$id)', label: 'goal');
    return (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  /// Get goal by cloud ID (for sync operations)
  Future<Goal?> getGoalByCloudId(String cloudId) {
    return (select(goals)..where((g) => g.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  /// Updates an existing goal (matching by .id)
  Future<bool> updateGoal(Goal goal) async {
    Log.d('✏️  updateGoal → ${goal.toString()}', label: 'goal');

    // 1. Update local database
    final success = await update(goals).replace(goal);
    Log.d('✔️  updateGoal success=$success', label: 'goal');

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadGoal(goal.toModel());
      } catch (e, stack) {
        Log.e('Failed to upload goal update to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local update succeeded
      }
    }

    return success;
  }

  /// Deletes a goal by its ID
  Future<int> deleteGoal(int id) async {
    Log.d('🗑️  deleteGoal → id=$id', label: 'goal');

    // 1. Get goal to retrieve cloudId
    final goal = await getGoalById(id);

    // 2. Delete from local database
    final count = await (delete(goals)..where((g) => g.id.equals(id))).go();
    Log.d('✔️  deleteGoal deleted $count row(s)', label: 'goal');

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && goal != null && goal.cloudId != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.deleteGoalFromCloud(goal.cloudId!);
      } catch (e, stack) {
        Log.e('Failed to delete goal from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return count;
  }

  /// Streams only pinned goals
  Stream<List<Goal>> watchPinnedGoals() {
    Log.d('Subscribing to watchPinnedGoals()', label: 'goal');
    return (select(goals)..where((g) => g.pinned.equals(true))).watch();
  }

  /// Pin a goal by its ID
  Future<void> pinGoal(int id) async {
    Log.d('📌  pinGoal → id=$id', label: 'goal');
    await (update(goals)..where((g) => g.id.equals(id))).write(
      const GoalsCompanion(pinned: Value(true)),
    );
  }

  /// Unpin a goal by its ID
  Future<void> unpinGoal(int id) async {
    Log.d('📌  unpinGoal → id=$id', label: 'goal');
    await (update(goals)..where((g) => g.id.equals(id))).write(
      const GoalsCompanion(pinned: Value(false)),
    );
  }
}
