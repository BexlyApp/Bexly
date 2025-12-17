import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/family_group_table.dart';
import 'package:bexly/core/database/tables/family_member_table.dart';
import 'package:bexly/core/database/tables/family_invitation_table.dart';
import 'package:bexly/core/database/tables/shared_wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/family/data/models/family_group_model.dart';
import 'package:bexly/features/family/data/models/family_member_model.dart';
import 'package:bexly/features/family/data/models/family_invitation_model.dart';
import 'package:bexly/features/family/data/models/shared_wallet_model.dart';
import 'package:bexly/features/family/domain/enums/family_role.dart';
import 'package:bexly/features/family/domain/enums/family_member_status.dart';
import 'package:bexly/features/family/domain/enums/invitation_status.dart';

part 'family_dao.g.dart';

@DriftAccessor(tables: [FamilyGroups, FamilyMembers, FamilyInvitations, SharedWallets])
class FamilyDao extends DatabaseAccessor<AppDatabase> with _$FamilyDaoMixin {
  FamilyDao(super.db);

  // ============== Family Groups ==============

  /// Watch all family groups the user belongs to
  Stream<List<FamilyGroupModel>> watchFamilyGroups() {
    return select(familyGroups).watch().map(
      (rows) => rows.map(_mapToFamilyGroupModel).toList(),
    );
  }

  /// Get family group by ID
  Future<FamilyGroupModel?> getFamilyGroupById(int id) async {
    final row = await (select(familyGroups)..where((f) => f.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapToFamilyGroupModel(row);
  }

  /// Get family group by cloud ID
  Future<FamilyGroupModel?> getFamilyGroupByCloudId(String cloudId) async {
    final row = await (select(familyGroups)..where((f) => f.cloudId.equals(cloudId)))
        .getSingleOrNull();
    return row == null ? null : _mapToFamilyGroupModel(row);
  }

  /// Get family group by invite code
  Future<FamilyGroupModel?> getFamilyGroupByInviteCode(String inviteCode) async {
    final row = await (select(familyGroups)..where((f) => f.inviteCode.equals(inviteCode)))
        .getSingleOrNull();
    return row == null ? null : _mapToFamilyGroupModel(row);
  }

  /// Create a new family group
  Future<int> createFamilyGroup(FamilyGroupModel model) async {
    Log.d('Creating family group: ${model.name}', label: 'family');
    final companion = FamilyGroupsCompanion(
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      name: Value(model.name),
      ownerId: Value(model.ownerId),
      iconName: Value(model.iconName),
      colorHex: Value(model.colorHex),
      maxMembers: Value(model.maxMembers),
      inviteCode: Value(model.inviteCode),
      createdAt: Value(model.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await into(familyGroups).insert(companion);
  }

  /// Update family group
  Future<bool> updateFamilyGroup(FamilyGroupModel model) async {
    if (model.id == null) return false;
    Log.d('Updating family group: ${model.name}', label: 'family');
    final companion = FamilyGroupsCompanion(
      id: Value(model.id!),
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      name: Value(model.name),
      ownerId: Value(model.ownerId),
      iconName: Value(model.iconName),
      colorHex: Value(model.colorHex),
      maxMembers: Value(model.maxMembers),
      inviteCode: Value(model.inviteCode),
      updatedAt: Value(DateTime.now()),
    );
    return await update(familyGroups).replace(companion);
  }

  /// Delete family group
  Future<int> deleteFamilyGroup(int id) async {
    Log.d('Deleting family group: $id', label: 'family');
    // Also delete related members, invitations, shared wallets
    await (delete(familyMembers)..where((m) => m.familyId.equals(id))).go();
    await (delete(familyInvitations)..where((i) => i.familyId.equals(id))).go();
    await (delete(sharedWallets)..where((s) => s.familyId.equals(id))).go();
    return await (delete(familyGroups)..where((f) => f.id.equals(id))).go();
  }

  FamilyGroupModel _mapToFamilyGroupModel(FamilyGroup row) {
    return FamilyGroupModel(
      id: row.id,
      cloudId: row.cloudId,
      name: row.name,
      ownerId: row.ownerId,
      iconName: row.iconName,
      colorHex: row.colorHex,
      maxMembers: row.maxMembers,
      inviteCode: row.inviteCode,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ============== Family Members ==============

  /// Watch members of a family group
  Stream<List<FamilyMemberModel>> watchFamilyMembers(int familyId) {
    return (select(familyMembers)..where((m) => m.familyId.equals(familyId)))
        .watch()
        .map((rows) => rows.map(_mapToFamilyMemberModel).toList());
  }

  /// Watch active members of a family group
  Stream<List<FamilyMemberModel>> watchActiveFamilyMembers(int familyId) {
    return (select(familyMembers)
          ..where((m) => m.familyId.equals(familyId) & m.status.equals('active')))
        .watch()
        .map((rows) => rows.map(_mapToFamilyMemberModel).toList());
  }

  /// Get member by user ID and family ID
  Future<FamilyMemberModel?> getMemberByUserId(int familyId, String userId) async {
    final row = await (select(familyMembers)
          ..where((m) => m.familyId.equals(familyId) & m.userId.equals(userId)))
        .getSingleOrNull();
    return row == null ? null : _mapToFamilyMemberModel(row);
  }

  /// Add member to family
  Future<int> addFamilyMember(FamilyMemberModel model) async {
    Log.d('Adding member ${model.userId} to family ${model.familyId}', label: 'family');
    final companion = FamilyMembersCompanion(
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      familyId: Value(model.familyId!),
      userId: Value(model.userId),
      displayName: Value(model.displayName),
      email: Value(model.email),
      avatarUrl: Value(model.avatarUrl),
      role: Value(model.role.toDbString()),
      status: Value(model.status.toDbString()),
      invitedAt: Value(model.invitedAt),
      joinedAt: Value(model.joinedAt),
      createdAt: Value(model.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await into(familyMembers).insert(companion);
  }

  /// Update member
  Future<bool> updateFamilyMember(FamilyMemberModel model) async {
    if (model.id == null) return false;
    final companion = FamilyMembersCompanion(
      id: Value(model.id!),
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      familyId: Value(model.familyId!),
      userId: Value(model.userId),
      displayName: Value(model.displayName),
      email: Value(model.email),
      avatarUrl: Value(model.avatarUrl),
      role: Value(model.role.toDbString()),
      status: Value(model.status.toDbString()),
      invitedAt: Value(model.invitedAt),
      joinedAt: Value(model.joinedAt),
      updatedAt: Value(DateTime.now()),
    );
    return await update(familyMembers).replace(companion);
  }

  /// Remove member from family (mark as left)
  Future<bool> removeFamilyMember(int memberId) async {
    Log.d('Removing member: $memberId', label: 'family');
    return await (update(familyMembers)..where((m) => m.id.equals(memberId)))
        .write(FamilyMembersCompanion(
          status: const Value('left'),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }

  FamilyMemberModel _mapToFamilyMemberModel(FamilyMember row) {
    return FamilyMemberModel(
      id: row.id,
      cloudId: row.cloudId,
      familyId: row.familyId,
      userId: row.userId,
      displayName: row.displayName,
      email: row.email,
      avatarUrl: row.avatarUrl,
      role: FamilyRoleExtension.fromDbString(row.role),
      status: FamilyMemberStatusExtension.fromDbString(row.status),
      invitedAt: row.invitedAt,
      joinedAt: row.joinedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ============== Family Invitations ==============

  /// Watch pending invitations for a family
  Stream<List<FamilyInvitationModel>> watchPendingInvitations(int familyId) {
    return (select(familyInvitations)
          ..where((i) => i.familyId.equals(familyId) & i.status.equals('pending')))
        .watch()
        .map((rows) => rows.map(_mapToFamilyInvitationModel).toList());
  }

  /// Watch invitations received by email
  Stream<List<FamilyInvitationModel>> watchInvitationsForEmail(String email) {
    return (select(familyInvitations)
          ..where((i) => i.invitedEmail.equals(email) & i.status.equals('pending')))
        .watch()
        .map((rows) => rows.map(_mapToFamilyInvitationModel).toList());
  }

  /// Get invitation by code
  Future<FamilyInvitationModel?> getInvitationByCode(String inviteCode) async {
    final row = await (select(familyInvitations)
          ..where((i) => i.inviteCode.equals(inviteCode)))
        .getSingleOrNull();
    return row == null ? null : _mapToFamilyInvitationModel(row);
  }

  /// Create invitation
  Future<int> createInvitation(FamilyInvitationModel model) async {
    Log.d('Creating invitation for ${model.invitedEmail}', label: 'family');
    final companion = FamilyInvitationsCompanion(
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      familyId: Value(model.familyId!),
      invitedEmail: Value(model.invitedEmail),
      invitedByUserId: Value(model.invitedByUserId),
      inviteCode: Value(model.inviteCode),
      role: Value(model.role.toDbString()),
      status: Value(model.status.toDbString()),
      expiresAt: Value(model.expiresAt),
      respondedAt: Value(model.respondedAt),
      createdAt: Value(model.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await into(familyInvitations).insert(companion);
  }

  /// Update invitation status
  Future<bool> updateInvitationStatus(int id, InvitationStatus status) async {
    Log.d('Updating invitation $id status to ${status.name}', label: 'family');
    return await (update(familyInvitations)..where((i) => i.id.equals(id)))
        .write(FamilyInvitationsCompanion(
          status: Value(status.toDbString()),
          respondedAt: status.isFinal ? Value(DateTime.now()) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }

  FamilyInvitationModel _mapToFamilyInvitationModel(FamilyInvitation row) {
    return FamilyInvitationModel(
      id: row.id,
      cloudId: row.cloudId,
      familyId: row.familyId,
      invitedEmail: row.invitedEmail,
      invitedByUserId: row.invitedByUserId,
      inviteCode: row.inviteCode,
      role: FamilyRoleExtension.fromDbString(row.role),
      status: InvitationStatusExtension.fromDbString(row.status),
      expiresAt: row.expiresAt,
      respondedAt: row.respondedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ============== Shared Wallets ==============

  /// Watch shared wallets for a family
  Stream<List<SharedWalletModel>> watchSharedWallets(int familyId) {
    return (select(sharedWallets)
          ..where((s) => s.familyId.equals(familyId) & s.isActive.equals(true)))
        .watch()
        .map((rows) => rows.map(_mapToSharedWalletModel).toList());
  }

  /// Check if a wallet is shared with any family
  Future<bool> isWalletShared(int walletId) async {
    final row = await (select(sharedWallets)
          ..where((s) => s.walletId.equals(walletId) & s.isActive.equals(true)))
        .getSingleOrNull();
    return row != null;
  }

  /// Share a wallet with a family
  Future<int> shareWallet(SharedWalletModel model) async {
    Log.d('Sharing wallet ${model.walletId} with family ${model.familyId}', label: 'family');
    final companion = SharedWalletsCompanion(
      cloudId: model.cloudId == null ? const Value.absent() : Value(model.cloudId),
      familyId: Value(model.familyId!),
      walletId: Value(model.walletId!),
      sharedByUserId: Value(model.sharedByUserId),
      isActive: const Value(true),
      sharedAt: Value(model.sharedAt ?? DateTime.now()),
      createdAt: Value(model.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return await into(sharedWallets).insert(companion);
  }

  /// Unshare a wallet (mark as inactive)
  Future<bool> unshareWallet(int sharedWalletId) async {
    Log.d('Unsharing wallet: $sharedWalletId', label: 'family');
    return await (update(sharedWallets)..where((s) => s.id.equals(sharedWalletId)))
        .write(SharedWalletsCompanion(
          isActive: const Value(false),
          unsharedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }

  SharedWalletModel _mapToSharedWalletModel(SharedWallet row) {
    return SharedWalletModel(
      id: row.id,
      cloudId: row.cloudId,
      familyId: row.familyId,
      walletId: row.walletId,
      sharedByUserId: row.sharedByUserId,
      isActive: row.isActive,
      sharedAt: row.sharedAt,
      unsharedAt: row.unsharedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
