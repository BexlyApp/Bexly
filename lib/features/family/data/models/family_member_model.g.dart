// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyMemberModel _$FamilyMemberModelFromJson(Map<String, dynamic> json) =>
    _FamilyMemberModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      familyId: (json['familyId'] as num?)?.toInt(),
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role:
          $enumDecodeNullable(_$FamilyRoleEnumMap, json['role']) ??
          FamilyRole.viewer,
      status:
          $enumDecodeNullable(_$FamilyMemberStatusEnumMap, json['status']) ??
          FamilyMemberStatus.pending,
      invitedAt: json['invitedAt'] == null
          ? null
          : DateTime.parse(json['invitedAt'] as String),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FamilyMemberModelToJson(_FamilyMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'familyId': instance.familyId,
      'userId': instance.userId,
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'role': _$FamilyRoleEnumMap[instance.role]!,
      'status': _$FamilyMemberStatusEnumMap[instance.status]!,
      'invitedAt': instance.invitedAt?.toIso8601String(),
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$FamilyRoleEnumMap = {
  FamilyRole.owner: 'owner',
  FamilyRole.editor: 'editor',
  FamilyRole.viewer: 'viewer',
};

const _$FamilyMemberStatusEnumMap = {
  FamilyMemberStatus.pending: 'pending',
  FamilyMemberStatus.active: 'active',
  FamilyMemberStatus.left: 'left',
};
