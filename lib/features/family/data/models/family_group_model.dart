import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_group_model.freezed.dart';
part 'family_group_model.g.dart';

/// Model representing a family group
@freezed
abstract class FamilyGroupModel with _$FamilyGroupModel {
  const factory FamilyGroupModel({
    /// Local database ID
    int? id,

    /// Cloud ID (UUID v7) for syncing with Firestore
    String? cloudId,

    /// Display name of the family group
    required String name,

    /// Firebase UID of the family owner
    required String ownerId,

    /// Icon name for the family group
    String? iconName,

    /// Color hex code for the family group
    String? colorHex,

    /// Maximum number of members allowed
    @Default(5) int maxMembers,

    /// Invite code for deep link (8-char unique code)
    String? inviteCode,

    /// Timestamp when family was created
    DateTime? createdAt,

    /// Timestamp when family was last updated
    DateTime? updatedAt,
  }) = _FamilyGroupModel;

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyGroupModelFromJson(json);
}
