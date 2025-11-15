// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionFilter _$TransactionFilterFromJson(Map<String, dynamic> json) =>
    _TransactionFilter(
      keyword: json['keyword'] as String?,
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      category: json['category'] == null
          ? null
          : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      transactionType: $enumDecodeNullable(
        _$TransactionTypeEnumMap,
        json['transactionType'],
      ),
      dateStart: json['dateStart'] == null
          ? null
          : DateTime.parse(json['dateStart'] as String),
      dateEnd: json['dateEnd'] == null
          ? null
          : DateTime.parse(json['dateEnd'] as String),
      wallet: json['wallet'] == null
          ? null
          : WalletModel.fromJson(json['wallet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TransactionFilterToJson(_TransactionFilter instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'minAmount': instance.minAmount,
      'maxAmount': instance.maxAmount,
      'notes': instance.notes,
      'category': instance.category,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType],
      'dateStart': instance.dateStart?.toIso8601String(),
      'dateEnd': instance.dateEnd?.toIso8601String(),
      'wallet': instance.wallet,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
};
