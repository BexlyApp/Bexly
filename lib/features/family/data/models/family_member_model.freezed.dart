// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyMemberModel {

/// Local database ID
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// Local family group ID
 int? get familyId;/// Firebase UID of the member
 String get userId;/// Display name of the member (cached from user profile)
 String? get displayName;/// Email of the member (cached from user profile)
 String? get email;/// Avatar URL of the member (cached from user profile)
 String? get avatarUrl;/// Role in the family
 FamilyRole get role;/// Membership status
 FamilyMemberStatus get status;/// When the member was invited
 DateTime? get invitedAt;/// When the member joined (accepted invitation)
 DateTime? get joinedAt;/// Timestamp when record was created
 DateTime? get createdAt;/// Timestamp when record was last updated
 DateTime? get updatedAt;
/// Create a copy of FamilyMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyMemberModelCopyWith<FamilyMemberModel> get copyWith => _$FamilyMemberModelCopyWithImpl<FamilyMemberModel>(this as FamilyMemberModel, _$identity);

  /// Serializes this FamilyMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,userId,displayName,email,avatarUrl,role,status,invitedAt,joinedAt,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyMemberModel(id: $id, cloudId: $cloudId, familyId: $familyId, userId: $userId, displayName: $displayName, email: $email, avatarUrl: $avatarUrl, role: $role, status: $status, invitedAt: $invitedAt, joinedAt: $joinedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FamilyMemberModelCopyWith<$Res>  {
  factory $FamilyMemberModelCopyWith(FamilyMemberModel value, $Res Function(FamilyMemberModel) _then) = _$FamilyMemberModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, int? familyId, String userId, String? displayName, String? email, String? avatarUrl, FamilyRole role, FamilyMemberStatus status, DateTime? invitedAt, DateTime? joinedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$FamilyMemberModelCopyWithImpl<$Res>
    implements $FamilyMemberModelCopyWith<$Res> {
  _$FamilyMemberModelCopyWithImpl(this._self, this._then);

  final FamilyMemberModel _self;
  final $Res Function(FamilyMemberModel) _then;

/// Create a copy of FamilyMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? userId = null,Object? displayName = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? role = null,Object? status = null,Object? invitedAt = freezed,Object? joinedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as FamilyRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FamilyMemberStatus,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyMemberModel].
extension FamilyMemberModelPatterns on FamilyMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _FamilyMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  String userId,  String? displayName,  String? email,  String? avatarUrl,  FamilyRole role,  FamilyMemberStatus status,  DateTime? invitedAt,  DateTime? joinedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyMemberModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.status,_that.invitedAt,_that.joinedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  String userId,  String? displayName,  String? email,  String? avatarUrl,  FamilyRole role,  FamilyMemberStatus status,  DateTime? invitedAt,  DateTime? joinedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyMemberModel():
return $default(_that.id,_that.cloudId,_that.familyId,_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.status,_that.invitedAt,_that.joinedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  int? familyId,  String userId,  String? displayName,  String? email,  String? avatarUrl,  FamilyRole role,  FamilyMemberStatus status,  DateTime? invitedAt,  DateTime? joinedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyMemberModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.status,_that.invitedAt,_that.joinedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyMemberModel implements FamilyMemberModel {
  const _FamilyMemberModel({this.id, this.cloudId, this.familyId, required this.userId, this.displayName, this.email, this.avatarUrl, this.role = FamilyRole.viewer, this.status = FamilyMemberStatus.pending, this.invitedAt, this.joinedAt, this.createdAt, this.updatedAt});
  factory _FamilyMemberModel.fromJson(Map<String, dynamic> json) => _$FamilyMemberModelFromJson(json);

/// Local database ID
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// Local family group ID
@override final  int? familyId;
/// Firebase UID of the member
@override final  String userId;
/// Display name of the member (cached from user profile)
@override final  String? displayName;
/// Email of the member (cached from user profile)
@override final  String? email;
/// Avatar URL of the member (cached from user profile)
@override final  String? avatarUrl;
/// Role in the family
@override@JsonKey() final  FamilyRole role;
/// Membership status
@override@JsonKey() final  FamilyMemberStatus status;
/// When the member was invited
@override final  DateTime? invitedAt;
/// When the member joined (accepted invitation)
@override final  DateTime? joinedAt;
/// Timestamp when record was created
@override final  DateTime? createdAt;
/// Timestamp when record was last updated
@override final  DateTime? updatedAt;

/// Create a copy of FamilyMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyMemberModelCopyWith<_FamilyMemberModel> get copyWith => __$FamilyMemberModelCopyWithImpl<_FamilyMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,userId,displayName,email,avatarUrl,role,status,invitedAt,joinedAt,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyMemberModel(id: $id, cloudId: $cloudId, familyId: $familyId, userId: $userId, displayName: $displayName, email: $email, avatarUrl: $avatarUrl, role: $role, status: $status, invitedAt: $invitedAt, joinedAt: $joinedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyMemberModelCopyWith<$Res> implements $FamilyMemberModelCopyWith<$Res> {
  factory _$FamilyMemberModelCopyWith(_FamilyMemberModel value, $Res Function(_FamilyMemberModel) _then) = __$FamilyMemberModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, int? familyId, String userId, String? displayName, String? email, String? avatarUrl, FamilyRole role, FamilyMemberStatus status, DateTime? invitedAt, DateTime? joinedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$FamilyMemberModelCopyWithImpl<$Res>
    implements _$FamilyMemberModelCopyWith<$Res> {
  __$FamilyMemberModelCopyWithImpl(this._self, this._then);

  final _FamilyMemberModel _self;
  final $Res Function(_FamilyMemberModel) _then;

/// Create a copy of FamilyMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? userId = null,Object? displayName = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? role = null,Object? status = null,Object? invitedAt = freezed,Object? joinedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FamilyMemberModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as FamilyRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FamilyMemberStatus,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
