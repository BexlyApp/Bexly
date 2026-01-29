import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/checklist_item_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

part 'checklist_item_dao.g.dart';

@DriftAccessor(tables: [ChecklistItems])
class ChecklistItemDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistItemDaoMixin {
  final Ref? _ref;

  ChecklistItemDao(super.db, [this._ref]);

  /// Inserts a new checklist item, returns its new ID
  Future<int> addChecklistItem(ChecklistItemsCompanion entry) async {
    Log.d('addChecklistItem → ${entry.toString()}', label: 'checklist item');

    // CRITICAL: Generate UUID v7 for cloud sync BEFORE inserting to database
    // But only if entry doesn't already have cloudId (from cloud sync)
    final ChecklistItemsCompanion updatedEntry;
    if (entry.cloudId.present && entry.cloudId.value != null) {
      // Entry already has cloudId from cloud sync - keep it
      Log.d('Using existing cloudId from entry: ${entry.cloudId.value}', label: 'checklist item');
      updatedEntry = entry;
    } else {
      // Generate new cloudId for local-first creation
      final cloudId = const Uuid().v7();
      Log.d('Generated cloudId for new checklist item: $cloudId', label: 'checklist item');
      updatedEntry = entry.copyWith(cloudId: Value(cloudId));
    }

    // 1. Save to local database with cloudId
    final id = await into(checklistItems).insert(updatedEntry);
    Log.d('ChecklistItem inserted with id=$id', label: 'checklist item');

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          // Get saved checklist item
          final savedItem = await (select(checklistItems)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();

          if (savedItem != null) {
            // CRITICAL: Get goal's cloudId for foreign key
            final goal = await db.goalDao.getGoalById(savedItem.goalId);
            if (goal != null && goal.cloudId != null) {
              await syncService.uploadChecklistItem(
                savedItem.toModel(),
                goal.cloudId!,
              );
              Log.d('✅ [CHECKLIST SYNC] Checklist item uploaded successfully', label: 'sync');
            } else {
              Log.w('⚠️ Goal has no cloudId, skipping checklist item sync', label: 'sync');
            }
          }
        } catch (e, stack) {
          Log.e('Failed to upload checklist item to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local save succeeded
        }
      }
    }

    return id;
  }

  /// Fetches all checklist items.
  Future<List<ChecklistItem>> getAllChecklistItems() {
    return select(checklistItems).get();
  }

  /// Fetches all items for a specific goal (non-stream version)
  Future<List<ChecklistItem>> getChecklistItemsForGoal(int goalId) {
    return (select(checklistItems)
      ..where((tbl) => tbl.goalId.equals(goalId))).get();
  }

  /// Streams all items for a specific goal
  Stream<List<ChecklistItem>> watchChecklistItemsForGoal(int goalId) {
    Log.d(
      'watchChecklistItemsForGoal(goalId=$goalId)',
      label: 'checklist item',
    );
    return (select(
      checklistItems,
    )..where((tbl) => tbl.goalId.equals(goalId))).watch();
  }

  /// Updates an existing checklist item
  Future<bool> updateChecklistItem(ChecklistItem item) async {
    Log.d('updateChecklistItem → ${item.toString()}', label: 'checklist item');

    // 1. Update local database
    final success = await update(checklistItems).replace(item);
    Log.d('updateChecklistItem success=$success', label: 'checklist item');

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          // CRITICAL: Get goal's cloudId for foreign key
          final goal = await db.goalDao.getGoalById(item.goalId);
          if (goal != null && goal.cloudId != null) {
            await syncService.uploadChecklistItem(
              item.toModel(),
              goal.cloudId!,
            );
            Log.d('✅ [CHECKLIST SYNC] Checklist item update uploaded successfully', label: 'sync');
          } else {
            Log.w('⚠️ Goal has no cloudId, skipping checklist item sync', label: 'sync');
          }
        } catch (e, stack) {
          Log.e('Failed to upload checklist item update to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local update succeeded
        }
      }
    }

    return success;
  }

  /// Deletes a checklist item by ID
  Future<int> deleteChecklistItem(int id) async {
    Log.d('deleteChecklistItem → id=$id', label: 'checklist item');

    // 1. Get checklist item to retrieve cloudId
    final item = await (select(checklistItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    // 2. Delete from local database
    final count = await (delete(
      checklistItems,
    )..where((t) => t.id.equals(id))).go();
    Log.d('deleteChecklistItem deleted $count row(s)', label: 'checklist item');

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && item != null && item.cloudId != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.deleteChecklistItemFromCloud(item.cloudId!);
          Log.d('✅ [CHECKLIST SYNC] Checklist item deleted from cloud', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to delete checklist item from cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local delete succeeded
        }
      }
    }

    return count;
  }
}
