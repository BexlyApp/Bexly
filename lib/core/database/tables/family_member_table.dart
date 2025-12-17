import 'package:drift/drift.dart';
import 'package:bexly/core/database/tables/family_group_table.dart';

/// Family Members table - tracks members of a family group
@DataClassName('FamilyMember')
class FamilyMembers extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  TextColumn get cloudId => text().nullable().unique()();

  /// Local family group ID (foreign key)
  IntColumn get familyId => integer().references(FamilyGroups, #id)();

  /// Firebase UID of the member
  TextColumn get userId => text()();

  /// Display name of the member (cached from user profile)
  TextColumn get displayName => text().nullable()();

  /// Email of the member (cached from user profile)
  TextColumn get email => text().nullable()();

  /// Avatar URL of the member (cached from user profile)
  TextColumn get avatarUrl => text().nullable()();

  /// Role in the family: 'owner', 'editor', 'viewer'
  TextColumn get role => text().withDefault(const Constant('viewer'))();

  /// Membership status: 'pending', 'active', 'left'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// When the member was invited
  DateTimeColumn get invitedAt => dateTime().nullable()();

  /// When the member joined (accepted invitation)
  DateTimeColumn get joinedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
