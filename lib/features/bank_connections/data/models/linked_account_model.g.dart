// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linked_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinkedAccount _$LinkedAccountFromJson(Map<String, dynamic> json) =>
    _LinkedAccount(
      id: json['id'] as String,
      institutionName: json['institutionName'] as String,
      displayName: json['displayName'] as String?,
      last4: json['last4'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      balance: json['balance'] == null
          ? null
          : LinkedAccountBalance.fromJson(
              json['balance'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LinkedAccountToJson(_LinkedAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'institutionName': instance.institutionName,
      'displayName': instance.displayName,
      'last4': instance.last4,
      'category': instance.category,
      'status': instance.status,
      'balance': instance.balance,
    };

_LinkedAccountBalance _$LinkedAccountBalanceFromJson(
  Map<String, dynamic> json,
) => _LinkedAccountBalance(
  current: (json['current'] as num?)?.toInt(),
  available: (json['available'] as num?)?.toInt(),
  asOf: json['asOf'] as String?,
);

Map<String, dynamic> _$LinkedAccountBalanceToJson(
  _LinkedAccountBalance instance,
) => <String, dynamic>{
  'current': instance.current,
  'available': instance.available,
  'asOf': instance.asOf,
};
