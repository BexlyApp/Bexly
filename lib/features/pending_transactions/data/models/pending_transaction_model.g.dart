// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingTransactionModel _$PendingTransactionModelFromJson(
  Map<String, dynamic> json,
) => _PendingTransactionModel(
  id: (json['id'] as num?)?.toInt(),
  cloudId: json['cloudId'] as String?,
  source: $enumDecode(_$PendingTxSourceEnumMap, json['source']),
  sourceId: json['sourceId'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'VND',
  transactionType: json['transactionType'] as String,
  title: json['title'] as String,
  merchant: json['merchant'] as String?,
  transactionDate: DateTime.parse(json['transactionDate'] as String),
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
  categoryHint: json['categoryHint'] as String?,
  sourceDisplayName: json['sourceDisplayName'] as String,
  sourceIconUrl: json['sourceIconUrl'] as String?,
  accountIdentifier: json['accountIdentifier'] as String?,
  status:
      $enumDecodeNullable(_$PendingTxStatusEnumMap, json['status']) ??
      PendingTxStatus.pendingReview,
  importedTransactionId: (json['importedTransactionId'] as num?)?.toInt(),
  targetWalletId: (json['targetWalletId'] as num?)?.toInt(),
  selectedCategoryId: (json['selectedCategoryId'] as num?)?.toInt(),
  userNotes: json['userNotes'] as String?,
  rawSourceData: json['rawSourceData'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PendingTransactionModelToJson(
  _PendingTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'cloudId': instance.cloudId,
  'source': _$PendingTxSourceEnumMap[instance.source]!,
  'sourceId': instance.sourceId,
  'amount': instance.amount,
  'currency': instance.currency,
  'transactionType': instance.transactionType,
  'title': instance.title,
  'merchant': instance.merchant,
  'transactionDate': instance.transactionDate.toIso8601String(),
  'confidence': instance.confidence,
  'categoryHint': instance.categoryHint,
  'sourceDisplayName': instance.sourceDisplayName,
  'sourceIconUrl': instance.sourceIconUrl,
  'accountIdentifier': instance.accountIdentifier,
  'status': _$PendingTxStatusEnumMap[instance.status]!,
  'importedTransactionId': instance.importedTransactionId,
  'targetWalletId': instance.targetWalletId,
  'selectedCategoryId': instance.selectedCategoryId,
  'userNotes': instance.userNotes,
  'rawSourceData': instance.rawSourceData,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$PendingTxSourceEnumMap = {
  PendingTxSource.email: 'email',
  PendingTxSource.bank: 'bank',
  PendingTxSource.sms: 'sms',
  PendingTxSource.notification: 'notification',
};

const _$PendingTxStatusEnumMap = {
  PendingTxStatus.pendingReview: 'pending_review',
  PendingTxStatus.approved: 'approved',
  PendingTxStatus.rejected: 'rejected',
  PendingTxStatus.imported: 'imported',
};
