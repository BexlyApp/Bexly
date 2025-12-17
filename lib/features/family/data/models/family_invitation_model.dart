import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bexly/features/family/domain/enums/family_role.dart';
import 'package:bexly/features/family/domain/enums/invitation_status.dart';

part 'family_invitation_model.freezed.dart';
part 'family_invitation_model.g.dart';

/// Model representing an invitation to join a family group
@freezed
abstract class FamilyInvitationModel with _$FamilyInvitationModel {
  const factory FamilyInvitationModel({
    /// Local database ID
    int? id,

    /// Cloud ID (UUID v7) for syncing with Firestore
    String? cloudId,

    /// Local family group ID
    int? familyId,

    /// Email address the invitation was sent to
    required String invitedEmail,

    /// Firebase UID of the user who sent the invitation
    required String invitedByUserId,

    /// Unique invite code for deep link (8-char code)
    required String inviteCode,

    /// Role assigned to the invitee
    @Default(FamilyRole.viewer) FamilyRole role,

    /// Invitation status
    @Default(InvitationStatus.pending) InvitationStatus status,

    /// When the invitation expires
    required DateTime expiresAt,

    /// When the invitee responded (accepted/rejected)
    DateTime? respondedAt,

    /// Timestamp when record was created
    DateTime? createdAt,

    /// Timestamp when record was last updated
    DateTime? updatedAt,
  }) = _FamilyInvitationModel;

  factory FamilyInvitationModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyInvitationModelFromJson(json);
}

extension FamilyInvitationModelExtension on FamilyInvitationModel {
  /// Check if the invitation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the invitation can be responded to
  bool get canRespond => status.canRespond && !isExpired;

  /// Get the deep link URL for this invitation
  String get deepLinkUrl => 'https://join.bexly.app/f/$inviteCode';
}
