// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    _TransactionModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      transactionType: $enumDecode(
        _$TransactionTypeEnumMap,
        json['transactionType'],
      ),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      wallet: WalletModel.fromJson(json['wallet'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      imagePath: json['imagePath'] as String?,
      isRecurring: json['isRecurring'] as bool?,
      recurringId: (json['recurringId'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TransactionModelToJson(_TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'title': instance.title,
      'category': instance.category,
      'wallet': instance.wallet,
      'notes': instance.notes,
      'imagePath': instance.imagePath,
      'isRecurring': instance.isRecurring,
      'recurringId': instance.recurringId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
};
