// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistItemModel _$ChecklistItemModelFromJson(Map<String, dynamic> json) =>
    _ChecklistItemModel(
      id: (json['id'] as num?)?.toInt(),
      goalId: (json['goalId'] as num).toInt(),
      title: json['title'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      link: json['link'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$ChecklistItemModelToJson(_ChecklistItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goalId': instance.goalId,
      'title': instance.title,
      'amount': instance.amount,
      'link': instance.link,
      'completed': instance.completed,
    };
