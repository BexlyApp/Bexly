// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyGroupModel _$FamilyGroupModelFromJson(Map<String, dynamic> json) =>
    _FamilyGroupModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 5,
      inviteCode: json['inviteCode'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FamilyGroupModelToJson(_FamilyGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'name': instance.name,
      'ownerId': instance.ownerId,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'maxMembers': instance.maxMembers,
      'inviteCode': instance.inviteCode,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
