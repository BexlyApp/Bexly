import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart';
import 'package:bexly/core/utils/logger.dart';

/// A singleton AppDatabase for the whole app
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  Log.d(db.schemaVersion, label: 'database schema version');
  ref.onDispose(() => db.close());
  return db;
});

/// Wallet DAO provider with sync support
/// Use this instead of db.walletDao when you need sync functionality
final walletDaoProvider = Provider<WalletDao>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletDao(db, ref);
});
