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
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  currency: json['currency'] as String? ?? 'IDR',
  iconName: json['iconName'] as String?,
  colorHex: json['colorHex'] as String?,
  walletType:
      $enumDecodeNullable(_$WalletTypeEnumMap, json['walletType']) ??
      WalletType.cash,
  creditLimit: (json['creditLimit'] as num?)?.toDouble(),
  billingDay: (json['billingDay'] as num?)?.toInt(),
  interestRate: (json['interestRate'] as num?)?.toDouble(),
  ownerUserId: json['ownerUserId'] as String?,
  isShared: json['isShared'] as bool? ?? false,
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
      'initialBalance': instance.initialBalance,
      'currency': instance.currency,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'walletType': _$WalletTypeEnumMap[instance.walletType]!,
      'creditLimit': instance.creditLimit,
      'billingDay': instance.billingDay,
      'interestRate': instance.interestRate,
      'ownerUserId': instance.ownerUserId,
      'isShared': instance.isShared,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$WalletTypeEnumMap = {
  WalletType.cash: 'cash',
  WalletType.bankAccount: 'bankAccount',
  WalletType.creditCard: 'creditCard',
  WalletType.eWallet: 'eWallet',
  WalletType.investment: 'investment',
  WalletType.savings: 'savings',
  WalletType.insurance: 'insurance',
  WalletType.other: 'other',
};
