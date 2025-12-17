// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SharedWalletModel _$SharedWalletModelFromJson(Map<String, dynamic> json) =>
    _SharedWalletModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      familyId: (json['familyId'] as num?)?.toInt(),
      walletId: (json['walletId'] as num?)?.toInt(),
      sharedByUserId: json['sharedByUserId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      sharedAt: json['sharedAt'] == null
          ? null
          : DateTime.parse(json['sharedAt'] as String),
      unsharedAt: json['unsharedAt'] == null
          ? null
          : DateTime.parse(json['unsharedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SharedWalletModelToJson(_SharedWalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'familyId': instance.familyId,
      'walletId': instance.walletId,
      'sharedByUserId': instance.sharedByUserId,
      'isActive': instance.isActive,
      'sharedAt': instance.sharedAt?.toIso8601String(),
      'unsharedAt': instance.unsharedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
