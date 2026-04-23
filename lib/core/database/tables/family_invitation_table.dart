import 'package:drift/drift.dart';
import 'package:bexly/core/database/tables/family_group_table.dart';

/// Family Invitations table - tracks pending invitations to join a family
@DataClassName('FamilyInvitation')
class FamilyInvitations extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  TextColumn get cloudId => text().nullable().unique()();

  /// Local family group ID (foreign key)
  IntColumn get familyId => integer().references(FamilyGroups, #id)();

  /// Email address the invitation was sent to
  TextColumn get invitedEmail => text()();

  /// Firebase UID of the user who sent the invitation
  TextColumn get invitedByUserId => text()();

  /// Unique invite code for deep link (8-char code)
  TextColumn get inviteCode => text().unique()();

  /// Role assigned to the invitee: 'editor', 'viewer'
  TextColumn get role => text().withDefault(const Constant('viewer'))();

  /// Invitation status: 'pending', 'accepted', 'rejected', 'expired', 'cancelled'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// When the invitation expires
  DateTimeColumn get expiresAt => dateTime()();

  /// When the invitee responded (accepted/rejected)
  DateTimeColumn get respondedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
