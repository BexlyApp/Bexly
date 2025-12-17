import 'package:drift/drift.dart';

/// Family Groups table - represents a family/household group that can share wallets
@DataClassName('FamilyGroup')
class FamilyGroups extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  TextColumn get cloudId => text().nullable().unique()();

  /// Display name of the family group
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Firebase UID of the family owner (creator)
  TextColumn get ownerId => text()();

  /// Icon name for the family group
  TextColumn get iconName => text().nullable()();

  /// Color hex code for the family group
  TextColumn get colorHex => text().nullable()();

  /// Maximum number of members allowed (default: 5 for Family tier)
  IntColumn get maxMembers => integer().withDefault(const Constant(5))();

  /// Invite code for deep link (8-char unique code)
  TextColumn get inviteCode => text().nullable().unique()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
