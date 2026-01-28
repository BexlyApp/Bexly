// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoalModel _$GoalModelFromJson(Map<String, dynamic> json) => _GoalModel(
  id: (json['id'] as num?)?.toInt(),
  cloudId: json['cloudId'] as String?,
  title: json['title'] as String,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  iconName: json['iconName'] as String?,
  description: json['description'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  associatedAccountId: (json['associatedAccountId'] as num?)?.toInt(),
  pinned: json['pinned'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
);

Map<String, dynamic> _$GoalModelToJson(_GoalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'title': instance.title,
      'targetAmount': instance.targetAmount,
      'currentAmount': instance.currentAmount,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'iconName': instance.iconName,
      'description': instance.description,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'associatedAccountId': instance.associatedAccountId,
      'pinned': instance.pinned,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };
