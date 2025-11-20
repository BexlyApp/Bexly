// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringModel _$RecurringModelFromJson(Map<String, dynamic> json) =>
    _RecurringModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      wallet: WalletModel.fromJson(json['wallet'] as Map<String, dynamic>),
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      frequency: $enumDecode(_$RecurringFrequencyEnumMap, json['frequency']),
      customInterval: (json['customInterval'] as num?)?.toInt(),
      customUnit: json['customUnit'] as String?,
      billingDay: (json['billingDay'] as num?)?.toInt(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      status: $enumDecode(_$RecurringStatusEnumMap, json['status']),
      autoCreate: json['autoCreate'] as bool? ?? false,
      enableReminder: json['enableReminder'] as bool? ?? true,
      reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 3,
      notes: json['notes'] as String?,
      vendorName: json['vendorName'] as String?,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      lastChargedDate: json['lastChargedDate'] == null
          ? null
          : DateTime.parse(json['lastChargedDate'] as String),
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RecurringModelToJson(_RecurringModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'name': instance.name,
      'description': instance.description,
      'wallet': instance.wallet,
      'category': instance.category,
      'amount': instance.amount,
      'currency': instance.currency,
      'startDate': instance.startDate.toIso8601String(),
      'nextDueDate': instance.nextDueDate.toIso8601String(),
      'frequency': _$RecurringFrequencyEnumMap[instance.frequency]!,
      'customInterval': instance.customInterval,
      'customUnit': instance.customUnit,
      'billingDay': instance.billingDay,
      'endDate': instance.endDate?.toIso8601String(),
      'status': _$RecurringStatusEnumMap[instance.status]!,
      'autoCreate': instance.autoCreate,
      'enableReminder': instance.enableReminder,
      'reminderDaysBefore': instance.reminderDaysBefore,
      'notes': instance.notes,
      'vendorName': instance.vendorName,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'lastChargedDate': instance.lastChargedDate?.toIso8601String(),
      'totalPayments': instance.totalPayments,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$RecurringFrequencyEnumMap = {
  RecurringFrequency.daily: 'daily',
  RecurringFrequency.weekly: 'weekly',
  RecurringFrequency.monthly: 'monthly',
  RecurringFrequency.quarterly: 'quarterly',
  RecurringFrequency.yearly: 'yearly',
  RecurringFrequency.custom: 'custom',
};

const _$RecurringStatusEnumMap = {
  RecurringStatus.active: 'active',
  RecurringStatus.paused: 'paused',
  RecurringStatus.cancelled: 'cancelled',
  RecurringStatus.expired: 'expired',
};
