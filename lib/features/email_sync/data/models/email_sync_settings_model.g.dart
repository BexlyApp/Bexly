// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_sync_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailSyncSettingsModel _$EmailSyncSettingsModelFromJson(
  Map<String, dynamic> json,
) => _EmailSyncSettingsModel(
  id: (json['id'] as num?)?.toInt(),
  gmailEmail: json['gmailEmail'] as String?,
  isEnabled: json['isEnabled'] as bool? ?? false,
  lastSyncTime: json['lastSyncTime'] == null
      ? null
      : DateTime.parse(json['lastSyncTime'] as String),
  enabledBanks:
      (json['enabledBanks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  totalImported: (json['totalImported'] as num?)?.toInt() ?? 0,
  pendingReview: (json['pendingReview'] as num?)?.toInt() ?? 0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$EmailSyncSettingsModelToJson(
  _EmailSyncSettingsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'gmailEmail': instance.gmailEmail,
  'isEnabled': instance.isEnabled,
  'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
  'enabledBanks': instance.enabledBanks,
  'totalImported': instance.totalImported,
  'pendingReview': instance.pendingReview,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
