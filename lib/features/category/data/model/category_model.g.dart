// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    _CategoryModel(
      id: (json['id'] as num?)?.toInt(),
      cloudId: json['cloudId'] as String?,
      title: json['title'] as String,
      icon: json['icon'] as String? ?? '',
      iconBackground: json['iconBackground'] as String? ?? '',
      iconTypeValue: json['iconTypeValue'] as String? ?? '',
      parentId: (json['parentId'] as num?)?.toInt(),
      description: json['description'] as String? ?? '',
      subCategories: (json['subCategories'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CategoryModelToJson(_CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cloudId': instance.cloudId,
      'title': instance.title,
      'icon': instance.icon,
      'iconBackground': instance.iconBackground,
      'iconTypeValue': instance.iconTypeValue,
      'parentId': instance.parentId,
      'description': instance.description,
      'subCategories': instance.subCategories,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
