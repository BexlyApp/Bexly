// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_invitation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyInvitationModel _$FamilyInvitationModelFromJson(
  Map<String, dynamic> json,
) => _FamilyInvitationModel(
  id: (json['id'] as num?)?.toInt(),
  cloudId: json['cloudId'] as String?,
  familyId: (json['familyId'] as num?)?.toInt(),
  invitedEmail: json['invitedEmail'] as String,
  invitedByUserId: json['invitedByUserId'] as String,
  inviteCode: json['inviteCode'] as String,
  role:
      $enumDecodeNullable(_$FamilyRoleEnumMap, json['role']) ??
      FamilyRole.viewer,
  status:
      $enumDecodeNullable(_$InvitationStatusEnumMap, json['status']) ??
      InvitationStatus.pending,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  respondedAt: json['respondedAt'] == null
      ? null
      : DateTime.parse(json['respondedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FamilyInvitationModelToJson(
  _FamilyInvitationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'cloudId': instance.cloudId,
  'familyId': instance.familyId,
  'invitedEmail': instance.invitedEmail,
  'invitedByUserId': instance.invitedByUserId,
  'inviteCode': instance.inviteCode,
  'role': _$FamilyRoleEnumMap[instance.role]!,
  'status': _$InvitationStatusEnumMap[instance.status]!,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'respondedAt': instance.respondedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$FamilyRoleEnumMap = {
  FamilyRole.owner: 'owner',
  FamilyRole.editor: 'editor',
  FamilyRole.viewer: 'viewer',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.rejected: 'rejected',
  InvitationStatus.expired: 'expired',
  InvitationStatus.cancelled: 'cancelled',
};
