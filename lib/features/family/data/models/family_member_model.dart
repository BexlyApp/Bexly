import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bexly/features/family/domain/enums/family_role.dart';
import 'package:bexly/features/family/domain/enums/family_member_status.dart';

part 'family_member_model.freezed.dart';
part 'family_member_model.g.dart';

/// Model representing a member of a family group
@freezed
abstract class FamilyMemberModel with _$FamilyMemberModel {
  const factory FamilyMemberModel({
    /// Local database ID
    int? id,

    /// Cloud ID (UUID v7) for syncing with Firestore
    String? cloudId,

    /// Local family group ID
    int? familyId,

    /// Firebase UID of the member
    required String userId,

    /// Display name of the member (cached from user profile)
    String? displayName,

    /// Email of the member (cached from user profile)
    String? email,

    /// Avatar URL of the member (cached from user profile)
    String? avatarUrl,

    /// Role in the family
    @Default(FamilyRole.viewer) FamilyRole role,

    /// Membership status
    @Default(FamilyMemberStatus.pending) FamilyMemberStatus status,

    /// When the member was invited
    DateTime? invitedAt,

    /// When the member joined (accepted invitation)
    DateTime? joinedAt,

    /// Timestamp when record was created
    DateTime? createdAt,

    /// Timestamp when record was last updated
    DateTime? updatedAt,
  }) = _FamilyMemberModel;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberModelFromJson(json);
}
