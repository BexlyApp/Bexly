import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/goal_table.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';

/// Emits a new list of all Goal rows whenever the table changes
final goalsListProvider = StreamProvider.autoDispose<List<GoalModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.goalDao.watchAllGoals().map(
    (event) => event.map((e) => e.toModel()).toList(),
  );
});

final pinnedGoalsProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  return db.goalDao.watchPinnedGoals().map(
    (list) => list.map((e) => e.toModel()).toList(),
  );
});
