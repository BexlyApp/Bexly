// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryModel {

/// The unique identifier for the category. Null if the category is new and not yet saved.
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// The display name of the category (e.g., "Groceries", "Salary").
 String get title;/// The identifier or name of the icon associated with this category.
/// This could be a key to lookup an icon from a predefined set (e.g., "HugeIcons.strokeRoundedShoppingBag01").
 String get icon;/// Icon background in hex e.g. "#cd34ff" or "cd34ff"
 String get iconBackground;/// The type of icon being used (emoji, initial, or asset)
 String get iconTypeValue;/// The identifier of the parent category, if this is a sub-category.
/// Null if this is a top-level category.
 int? get parentId;/// An optional description for the category.
 String? get description;/// A list of sub-categories. Null or empty if this category has no sub-categories.
 List<CategoryModel>? get subCategories;/// System default categories cannot be deleted by cloud sync
/// These are the initial categories created on first app launch
 bool get isSystemDefault;/// Timestamp when category was created
 DateTime? get createdAt;/// Timestamp when category was last updated
 DateTime? get updatedAt;
/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<CategoryModel> get copyWith => _$CategoryModelCopyWithImpl<CategoryModel>(this as CategoryModel, _$identity);

  /// Serializes this CategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.title, title) || other.title == title)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconBackground, iconBackground) || other.iconBackground == iconBackground)&&(identical(other.iconTypeValue, iconTypeValue) || other.iconTypeValue == iconTypeValue)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.subCategories, subCategories)&&(identical(other.isSystemDefault, isSystemDefault) || other.isSystemDefault == isSystemDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,title,icon,iconBackground,iconTypeValue,parentId,description,const DeepCollectionEquality().hash(subCategories),isSystemDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CategoryModel(id: $id, cloudId: $cloudId, title: $title, icon: $icon, iconBackground: $iconBackground, iconTypeValue: $iconTypeValue, parentId: $parentId, description: $description, subCategories: $subCategories, isSystemDefault: $isSystemDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CategoryModelCopyWith<$Res>  {
  factory $CategoryModelCopyWith(CategoryModel value, $Res Function(CategoryModel) _then) = _$CategoryModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String title, String icon, String iconBackground, String iconTypeValue, int? parentId, String? description, List<CategoryModel>? subCategories, bool isSystemDefault, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$CategoryModelCopyWithImpl<$Res>
    implements $CategoryModelCopyWith<$Res> {
  _$CategoryModelCopyWithImpl(this._self, this._then);

  final CategoryModel _self;
  final $Res Function(CategoryModel) _then;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? title = null,Object? icon = null,Object? iconBackground = null,Object? iconTypeValue = null,Object? parentId = freezed,Object? description = freezed,Object? subCategories = freezed,Object? isSystemDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,iconBackground: null == iconBackground ? _self.iconBackground : iconBackground // ignore: cast_nullable_to_non_nullable
as String,iconTypeValue: null == iconTypeValue ? _self.iconTypeValue : iconTypeValue // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subCategories: freezed == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<CategoryModel>?,isSystemDefault: null == isSystemDefault ? _self.isSystemDefault : isSystemDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryModel].
extension CategoryModelPatterns on CategoryModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String title,  String icon,  String iconBackground,  String iconTypeValue,  int? parentId,  String? description,  List<CategoryModel>? subCategories,  bool isSystemDefault,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.title,_that.icon,_that.iconBackground,_that.iconTypeValue,_that.parentId,_that.description,_that.subCategories,_that.isSystemDefault,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String title,  String icon,  String iconBackground,  String iconTypeValue,  int? parentId,  String? description,  List<CategoryModel>? subCategories,  bool isSystemDefault,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CategoryModel():
return $default(_that.id,_that.cloudId,_that.title,_that.icon,_that.iconBackground,_that.iconTypeValue,_that.parentId,_that.description,_that.subCategories,_that.isSystemDefault,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String title,  String icon,  String iconBackground,  String iconTypeValue,  int? parentId,  String? description,  List<CategoryModel>? subCategories,  bool isSystemDefault,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CategoryModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.title,_that.icon,_that.iconBackground,_that.iconTypeValue,_that.parentId,_that.description,_that.subCategories,_that.isSystemDefault,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryModel implements CategoryModel {
  const _CategoryModel({this.id, this.cloudId, required this.title, this.icon = '', this.iconBackground = '', this.iconTypeValue = '', this.parentId, this.description = '', final  List<CategoryModel>? subCategories, this.isSystemDefault = false, this.createdAt, this.updatedAt}): _subCategories = subCategories;
  factory _CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

/// The unique identifier for the category. Null if the category is new and not yet saved.
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// The display name of the category (e.g., "Groceries", "Salary").
@override final  String title;
/// The identifier or name of the icon associated with this category.
/// This could be a key to lookup an icon from a predefined set (e.g., "HugeIcons.strokeRoundedShoppingBag01").
@override@JsonKey() final  String icon;
/// Icon background in hex e.g. "#cd34ff" or "cd34ff"
@override@JsonKey() final  String iconBackground;
/// The type of icon being used (emoji, initial, or asset)
@override@JsonKey() final  String iconTypeValue;
/// The identifier of the parent category, if this is a sub-category.
/// Null if this is a top-level category.
@override final  int? parentId;
/// An optional description for the category.
@override@JsonKey() final  String? description;
/// A list of sub-categories. Null or empty if this category has no sub-categories.
 final  List<CategoryModel>? _subCategories;
/// A list of sub-categories. Null or empty if this category has no sub-categories.
@override List<CategoryModel>? get subCategories {
  final value = _subCategories;
  if (value == null) return null;
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// System default categories cannot be deleted by cloud sync
/// These are the initial categories created on first app launch
@override@JsonKey() final  bool isSystemDefault;
/// Timestamp when category was created
@override final  DateTime? createdAt;
/// Timestamp when category was last updated
@override final  DateTime? updatedAt;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryModelCopyWith<_CategoryModel> get copyWith => __$CategoryModelCopyWithImpl<_CategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.title, title) || other.title == title)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconBackground, iconBackground) || other.iconBackground == iconBackground)&&(identical(other.iconTypeValue, iconTypeValue) || other.iconTypeValue == iconTypeValue)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories)&&(identical(other.isSystemDefault, isSystemDefault) || other.isSystemDefault == isSystemDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,title,icon,iconBackground,iconTypeValue,parentId,description,const DeepCollectionEquality().hash(_subCategories),isSystemDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CategoryModel(id: $id, cloudId: $cloudId, title: $title, icon: $icon, iconBackground: $iconBackground, iconTypeValue: $iconTypeValue, parentId: $parentId, description: $description, subCategories: $subCategories, isSystemDefault: $isSystemDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CategoryModelCopyWith<$Res> implements $CategoryModelCopyWith<$Res> {
  factory _$CategoryModelCopyWith(_CategoryModel value, $Res Function(_CategoryModel) _then) = __$CategoryModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String title, String icon, String iconBackground, String iconTypeValue, int? parentId, String? description, List<CategoryModel>? subCategories, bool isSystemDefault, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$CategoryModelCopyWithImpl<$Res>
    implements _$CategoryModelCopyWith<$Res> {
  __$CategoryModelCopyWithImpl(this._self, this._then);

  final _CategoryModel _self;
  final $Res Function(_CategoryModel) _then;

/// Create a copy of CategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? title = null,Object? icon = null,Object? iconBackground = null,Object? iconTypeValue = null,Object? parentId = freezed,Object? description = freezed,Object? subCategories = freezed,Object? isSystemDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CategoryModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,iconBackground: null == iconBackground ? _self.iconBackground : iconBackground // ignore: cast_nullable_to_non_nullable
as String,iconTypeValue: null == iconTypeValue ? _self.iconTypeValue : iconTypeValue // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subCategories: freezed == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<CategoryModel>?,isSystemDefault: null == isSystemDefault ? _self.isSystemDefault : isSystemDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
