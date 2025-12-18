// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_email_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParsedEmailTransactionModel _$ParsedEmailTransactionModelFromJson(
  Map<String, dynamic> json,
) => _ParsedEmailTransactionModel(
  id: (json['id'] as num?)?.toInt(),
  cloudId: json['cloudId'] as String?,
  emailId: json['emailId'] as String,
  emailSubject: json['emailSubject'] as String,
  fromEmail: json['fromEmail'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'VND',
  transactionType: json['transactionType'] as String,
  merchant: json['merchant'] as String?,
  accountLast4: json['accountLast4'] as String?,
  balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
  transactionDate: DateTime.parse(json['transactionDate'] as String),
  emailDate: DateTime.parse(json['emailDate'] as String),
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
  rawAmountText: json['rawAmountText'] as String,
  categoryHint: json['categoryHint'] as String?,
  bankName: json['bankName'] as String,
  status:
      $enumDecodeNullable(_$ParsedTransactionStatusEnumMap, json['status']) ??
      ParsedTransactionStatus.pendingReview,
  importedTransactionId: json['importedTransactionId'] as String?,
  targetWalletCloudId: json['targetWalletCloudId'] as String?,
  selectedCategoryCloudId: json['selectedCategoryCloudId'] as String?,
  userNotes: json['userNotes'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ParsedEmailTransactionModelToJson(
  _ParsedEmailTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'cloudId': instance.cloudId,
  'emailId': instance.emailId,
  'emailSubject': instance.emailSubject,
  'fromEmail': instance.fromEmail,
  'amount': instance.amount,
  'currency': instance.currency,
  'transactionType': instance.transactionType,
  'merchant': instance.merchant,
  'accountLast4': instance.accountLast4,
  'balanceAfter': instance.balanceAfter,
  'transactionDate': instance.transactionDate.toIso8601String(),
  'emailDate': instance.emailDate.toIso8601String(),
  'confidence': instance.confidence,
  'rawAmountText': instance.rawAmountText,
  'categoryHint': instance.categoryHint,
  'bankName': instance.bankName,
  'status': _$ParsedTransactionStatusEnumMap[instance.status]!,
  'importedTransactionId': instance.importedTransactionId,
  'targetWalletCloudId': instance.targetWalletCloudId,
  'selectedCategoryCloudId': instance.selectedCategoryCloudId,
  'userNotes': instance.userNotes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$ParsedTransactionStatusEnumMap = {
  ParsedTransactionStatus.pendingReview: 'pendingReview',
  ParsedTransactionStatus.approved: 'approved',
  ParsedTransactionStatus.rejected: 'rejected',
  ParsedTransactionStatus.imported: 'imported',
};
