// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => _WalletModel(
  id: (json['id'] as num?)?.toInt(),
  cloudId: json['cloudId'] as String?,
  name: json['name'] as String? ?? 'My Wallet',
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
  currency: json['currency'] as String? ?? 'IDR',
  iconName: json['iconName'] as String?,
  colorHex: json['colorHex'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WalletModelToJson(_WalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'name': instance.name,
      'balance': instance.balance,
      'currency': instance.currency,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
