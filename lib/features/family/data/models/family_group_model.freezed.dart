// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_group_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyGroupModel {

/// Local database ID
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// Display name of the family group
 String get name;/// Firebase UID of the family owner
 String get ownerId;/// Icon name for the family group
 String? get iconName;/// Color hex code for the family group
 String? get colorHex;/// Maximum number of members allowed
 int get maxMembers;/// Invite code for deep link (8-char unique code)
 String? get inviteCode;/// Timestamp when family was created
 DateTime? get createdAt;/// Timestamp when family was last updated
 DateTime? get updatedAt;
/// Create a copy of FamilyGroupModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyGroupModelCopyWith<FamilyGroupModel> get copyWith => _$FamilyGroupModelCopyWithImpl<FamilyGroupModel>(this as FamilyGroupModel, _$identity);

  /// Serializes this FamilyGroupModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyGroupModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,name,ownerId,iconName,colorHex,maxMembers,inviteCode,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyGroupModel(id: $id, cloudId: $cloudId, name: $name, ownerId: $ownerId, iconName: $iconName, colorHex: $colorHex, maxMembers: $maxMembers, inviteCode: $inviteCode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FamilyGroupModelCopyWith<$Res>  {
  factory $FamilyGroupModelCopyWith(FamilyGroupModel value, $Res Function(FamilyGroupModel) _then) = _$FamilyGroupModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String name, String ownerId, String? iconName, String? colorHex, int maxMembers, String? inviteCode, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$FamilyGroupModelCopyWithImpl<$Res>
    implements $FamilyGroupModelCopyWith<$Res> {
  _$FamilyGroupModelCopyWithImpl(this._self, this._then);

  final FamilyGroupModel _self;
  final $Res Function(FamilyGroupModel) _then;

/// Create a copy of FamilyGroupModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? ownerId = null,Object? iconName = freezed,Object? colorHex = freezed,Object? maxMembers = null,Object? inviteCode = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyGroupModel].
extension FamilyGroupModelPatterns on FamilyGroupModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyGroupModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyGroupModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyGroupModel value)  $default,){
final _that = this;
switch (_that) {
case _FamilyGroupModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyGroupModel value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyGroupModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  String ownerId,  String? iconName,  String? colorHex,  int maxMembers,  String? inviteCode,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyGroupModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.ownerId,_that.iconName,_that.colorHex,_that.maxMembers,_that.inviteCode,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  String ownerId,  String? iconName,  String? colorHex,  int maxMembers,  String? inviteCode,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyGroupModel():
return $default(_that.id,_that.cloudId,_that.name,_that.ownerId,_that.iconName,_that.colorHex,_that.maxMembers,_that.inviteCode,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String name,  String ownerId,  String? iconName,  String? colorHex,  int maxMembers,  String? inviteCode,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyGroupModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.ownerId,_that.iconName,_that.colorHex,_that.maxMembers,_that.inviteCode,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyGroupModel implements FamilyGroupModel {
  const _FamilyGroupModel({this.id, this.cloudId, required this.name, required this.ownerId, this.iconName, this.colorHex, this.maxMembers = 5, this.inviteCode, this.createdAt, this.updatedAt});
  factory _FamilyGroupModel.fromJson(Map<String, dynamic> json) => _$FamilyGroupModelFromJson(json);

/// Local database ID
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// Display name of the family group
@override final  String name;
/// Firebase UID of the family owner
@override final  String ownerId;
/// Icon name for the family group
@override final  String? iconName;
/// Color hex code for the family group
@override final  String? colorHex;
/// Maximum number of members allowed
@override@JsonKey() final  int maxMembers;
/// Invite code for deep link (8-char unique code)
@override final  String? inviteCode;
/// Timestamp when family was created
@override final  DateTime? createdAt;
/// Timestamp when family was last updated
@override final  DateTime? updatedAt;

/// Create a copy of FamilyGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyGroupModelCopyWith<_FamilyGroupModel> get copyWith => __$FamilyGroupModelCopyWithImpl<_FamilyGroupModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyGroupModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyGroupModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,name,ownerId,iconName,colorHex,maxMembers,inviteCode,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyGroupModel(id: $id, cloudId: $cloudId, name: $name, ownerId: $ownerId, iconName: $iconName, colorHex: $colorHex, maxMembers: $maxMembers, inviteCode: $inviteCode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyGroupModelCopyWith<$Res> implements $FamilyGroupModelCopyWith<$Res> {
  factory _$FamilyGroupModelCopyWith(_FamilyGroupModel value, $Res Function(_FamilyGroupModel) _then) = __$FamilyGroupModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String name, String ownerId, String? iconName, String? colorHex, int maxMembers, String? inviteCode, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$FamilyGroupModelCopyWithImpl<$Res>
    implements _$FamilyGroupModelCopyWith<$Res> {
  __$FamilyGroupModelCopyWithImpl(this._self, this._then);

  final _FamilyGroupModel _self;
  final $Res Function(_FamilyGroupModel) _then;

/// Create a copy of FamilyGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? ownerId = null,Object? iconName = freezed,Object? colorHex = freezed,Object? maxMembers = null,Object? inviteCode = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FamilyGroupModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
