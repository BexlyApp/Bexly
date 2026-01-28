import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  final Ref? _ref;

  GoalDao(super.db, [this._ref]);

  // ─── CRUD for Goals ─────────────────────────────

  /// Inserts a new Goal, returns its auto-incremented ID
  Future<int> addGoal(GoalsCompanion entry) async {
    Log.d('addGoal → ${entry.toString()}', label: 'goal');

    // CRITICAL: Generate UUID v7 for cloud sync BEFORE inserting to database
    // But only if entry doesn't already have cloudId (from cloud sync)
    final GoalsCompanion updatedEntry;
    if (entry.cloudId.present && entry.cloudId.value != null) {
      // Entry already has cloudId from cloud sync - keep it
      Log.d('Using existing cloudId from entry: ${entry.cloudId.value}', label: 'goal');
      updatedEntry = entry;
    } else {
      // Generate new cloudId for local-first creation
      final cloudId = const Uuid().v7();
      Log.d('Generated cloudId for new goal: $cloudId', label: 'goal');
      updatedEntry = entry.copyWith(cloudId: Value(cloudId));
    }

    // 1. Save to local database with cloudId
    final id = await into(goals).insert(updatedEntry);
    Log.d('Goal inserted with id=$id', label: 'goal');

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          final savedGoal = await getGoalById(id);
          if (savedGoal != null) {
            await syncService.uploadGoal(savedGoal.toModel());
            Log.d('✅ [GOAL SYNC] Goal uploaded successfully', label: 'sync');
          }
        } catch (e, stack) {
          Log.e('Failed to upload goal to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local save succeeded
        }
      }
    }

    return id;
  }

  /// Streams all goals (excludes soft-deleted); logs each emission
  Stream<List<Goal>> watchAllGoals() {
    Log.d('Subscribing to watchAllGoals()', label: 'goal');
    return (select(goals)
      ..where((g) => g.isDeleted.equals(false)) // Filter deleted
    ).watch().map((list) {
      Log.d('watchAllGoals emitted ${list.length} rows', label: 'goal');
      return list;
    });
  }

  /// Fetches all goals (excludes soft-deleted).
  Future<List<Goal>> getAllGoals() {
    return (select(goals)
      ..where((g) => g.isDeleted.equals(false)) // Filter deleted
    ).get();
  }

  /// Streams single goal (excludes soft-deleted);
  Stream<Goal?> watchGoalByID(int id) {
    Log.d('Subscribing to watchGoalByID($id)', label: 'goal');
    return (select(goals)
      ..where((g) => g.id.equals(id))
      ..where((g) => g.isDeleted.equals(false)) // Filter deleted
    ).watchSingleOrNull();
  }

  /// Fetches a single goal by its ID (excludes soft-deleted), or null if not found.
  Future<Goal?> getGoalById(int id) {
    Log.d('Fetching getGoalById(id=$id)', label: 'goal');
    return (select(goals)
      ..where((g) => g.id.equals(id))
      ..where((g) => g.isDeleted.equals(false)) // Filter deleted
    ).getSingleOrNull();
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
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.uploadGoal(goal.toModel());
          Log.d('✅ [GOAL SYNC] Goal update uploaded successfully', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to upload goal update to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local update succeeded
        }
      }
    }

    return success;
  }

  /// Deletes a goal by its ID (soft delete using Tombstone pattern)
  Future<int> deleteGoal(int id) async {
    Log.d('🗑️  deleteGoal → id=$id (soft delete)', label: 'goal');

    // 1. Get goal to retrieve cloudId
    final goal = await getGoalById(id);

    // 2. SOFT DELETE - Mark as deleted (Tombstone pattern for instant UX)
    final count = await (update(goals)..where((g) => g.id.equals(id)))
      .write(GoalsCompanion(
        isDeleted: Value(true),
        deletedAt: Value(DateTime.now()),
      ));
    Log.d('✔️  deleteGoal soft deleted $count row(s)', label: 'goal');

    // 3. Delete from cloud AFTER (fire and forget, don't block user)
    if (count > 0 && _ref != null && goal != null && goal.cloudId != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.deleteGoalFromCloud(goal.cloudId!);
          Log.d('✅ [GOAL SYNC] Goal deleted from cloud', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to delete goal from cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local soft delete succeeded
        }
      }
    }

    return count;
  }

  /// Streams only pinned goals (excludes soft-deleted)
  Stream<List<Goal>> watchPinnedGoals() {
    Log.d('Subscribing to watchPinnedGoals()', label: 'goal');
    return (select(goals)
      ..where((g) => g.pinned.equals(true))
      ..where((g) => g.isDeleted.equals(false)) // Filter deleted
    ).watch();
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

  // ─── SOFT DELETE (Tombstone Pattern) ─────────────────

  /// Restores a soft-deleted goal (undo delete)
  Future<int> restoreGoal(int id) async {
    Log.d('♻️  restoreGoal → id=$id', label: 'goal');
    final count = await (update(goals)..where((g) => g.id.equals(id)))
      .write(GoalsCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ));
    Log.d('✔️  restoreGoal restored $count row(s)', label: 'goal');
    return count;
  }

  /// Hard deletes old soft-deleted goals (cleanup old tombstones)
  /// @param daysOld - Delete goals that were soft-deleted this many days ago
  /// @return Number of goals permanently deleted
  Future<int> cleanupDeletedGoals({int daysOld = 30}) async {
    Log.d('🧹  cleanupDeletedGoals → older than $daysOld days', label: 'goal');
    final threshold = DateTime.now().subtract(Duration(days: daysOld));

    final count = await (delete(goals)
      ..where((g) => g.isDeleted.equals(true))
      ..where((g) => g.deletedAt.isSmallerThanValue(threshold))
    ).go();

    Log.d('✔️  cleanupDeletedGoals permanently deleted $count row(s)', label: 'goal');
    return count;
  }

  /// Get all soft-deleted goals (for trash/restore UI)
  Future<List<Goal>> getDeletedGoals() async {
    Log.d('Fetching deleted goals', label: 'goal');
    return (select(goals)..where((g) => g.isDeleted.equals(true))).get();
  }

  /// Stream deleted goals (for trash/restore UI)
  Stream<List<Goal>> watchDeletedGoals() {
    Log.d('Subscribing to watchDeletedGoals()', label: 'goal');
    return (select(goals)..where((g) => g.isDeleted.equals(true))).watch();
  }
}
