import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/pockaw_database.dart';
import 'package:bexly/core/utils/logger.dart';

/// A singleton AppDatabase for the whole app
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  Log.d(db.schemaVersion, label: 'database schema version');
  ref.onDispose(() => db.close());
  return db;
});
