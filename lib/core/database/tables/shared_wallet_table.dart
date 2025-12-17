import 'package:drift/drift.dart';
import 'package:bexly/core/database/tables/family_group_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';

/// Shared Wallets table - tracks which wallets are shared with a family
@DataClassName('SharedWallet')
class SharedWallets extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  TextColumn get cloudId => text().nullable().unique()();

  /// Local family group ID (foreign key)
  IntColumn get familyId => integer().references(FamilyGroups, #id)();

  /// Local wallet ID (foreign key)
  IntColumn get walletId => integer().references(Wallets, #id)();

  /// Firebase UID of the user who shared the wallet
  TextColumn get sharedByUserId => text()();

  /// Whether the wallet is currently being shared (false = unshared but history preserved)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// When the wallet was shared
  DateTimeColumn get sharedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the wallet was unshared (if isActive = false)
  DateTimeColumn get unsharedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
