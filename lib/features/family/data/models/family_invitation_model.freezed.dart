// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_invitation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyInvitationModel {

/// Local database ID
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// Local family group ID
 int? get familyId;/// Email address the invitation was sent to
 String get invitedEmail;/// Firebase UID of the user who sent the invitation
 String get invitedByUserId;/// Unique invite code for deep link (8-char code)
 String get inviteCode;/// Role assigned to the invitee
 FamilyRole get role;/// Invitation status
 InvitationStatus get status;/// When the invitation expires
 DateTime get expiresAt;/// When the invitee responded (accepted/rejected)
 DateTime? get respondedAt;/// Timestamp when record was created
 DateTime? get createdAt;/// Timestamp when record was last updated
 DateTime? get updatedAt;
/// Create a copy of FamilyInvitationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyInvitationModelCopyWith<FamilyInvitationModel> get copyWith => _$FamilyInvitationModelCopyWithImpl<FamilyInvitationModel>(this as FamilyInvitationModel, _$identity);

  /// Serializes this FamilyInvitationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyInvitationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.invitedByUserId, invitedByUserId) || other.invitedByUserId == invitedByUserId)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,invitedEmail,invitedByUserId,inviteCode,role,status,expiresAt,respondedAt,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyInvitationModel(id: $id, cloudId: $cloudId, familyId: $familyId, invitedEmail: $invitedEmail, invitedByUserId: $invitedByUserId, inviteCode: $inviteCode, role: $role, status: $status, expiresAt: $expiresAt, respondedAt: $respondedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FamilyInvitationModelCopyWith<$Res>  {
  factory $FamilyInvitationModelCopyWith(FamilyInvitationModel value, $Res Function(FamilyInvitationModel) _then) = _$FamilyInvitationModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, int? familyId, String invitedEmail, String invitedByUserId, String inviteCode, FamilyRole role, InvitationStatus status, DateTime expiresAt, DateTime? respondedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$FamilyInvitationModelCopyWithImpl<$Res>
    implements $FamilyInvitationModelCopyWith<$Res> {
  _$FamilyInvitationModelCopyWithImpl(this._self, this._then);

  final FamilyInvitationModel _self;
  final $Res Function(FamilyInvitationModel) _then;

/// Create a copy of FamilyInvitationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? invitedEmail = null,Object? invitedByUserId = null,Object? inviteCode = null,Object? role = null,Object? status = null,Object? expiresAt = null,Object? respondedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,invitedEmail: null == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String,invitedByUserId: null == invitedByUserId ? _self.invitedByUserId : invitedByUserId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as FamilyRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyInvitationModel].
extension FamilyInvitationModelPatterns on FamilyInvitationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyInvitationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyInvitationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyInvitationModel value)  $default,){
final _that = this;
switch (_that) {
case _FamilyInvitationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyInvitationModel value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyInvitationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  String invitedEmail,  String invitedByUserId,  String inviteCode,  FamilyRole role,  InvitationStatus status,  DateTime expiresAt,  DateTime? respondedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyInvitationModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.invitedEmail,_that.invitedByUserId,_that.inviteCode,_that.role,_that.status,_that.expiresAt,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  String invitedEmail,  String invitedByUserId,  String inviteCode,  FamilyRole role,  InvitationStatus status,  DateTime expiresAt,  DateTime? respondedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyInvitationModel():
return $default(_that.id,_that.cloudId,_that.familyId,_that.invitedEmail,_that.invitedByUserId,_that.inviteCode,_that.role,_that.status,_that.expiresAt,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  int? familyId,  String invitedEmail,  String invitedByUserId,  String inviteCode,  FamilyRole role,  InvitationStatus status,  DateTime expiresAt,  DateTime? respondedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyInvitationModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.invitedEmail,_that.invitedByUserId,_that.inviteCode,_that.role,_that.status,_that.expiresAt,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyInvitationModel implements FamilyInvitationModel {
  const _FamilyInvitationModel({this.id, this.cloudId, this.familyId, required this.invitedEmail, required this.invitedByUserId, required this.inviteCode, this.role = FamilyRole.viewer, this.status = InvitationStatus.pending, required this.expiresAt, this.respondedAt, this.createdAt, this.updatedAt});
  factory _FamilyInvitationModel.fromJson(Map<String, dynamic> json) => _$FamilyInvitationModelFromJson(json);

/// Local database ID
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// Local family group ID
@override final  int? familyId;
/// Email address the invitation was sent to
@override final  String invitedEmail;
/// Firebase UID of the user who sent the invitation
@override final  String invitedByUserId;
/// Unique invite code for deep link (8-char code)
@override final  String inviteCode;
/// Role assigned to the invitee
@override@JsonKey() final  FamilyRole role;
/// Invitation status
@override@JsonKey() final  InvitationStatus status;
/// When the invitation expires
@override final  DateTime expiresAt;
/// When the invitee responded (accepted/rejected)
@override final  DateTime? respondedAt;
/// Timestamp when record was created
@override final  DateTime? createdAt;
/// Timestamp when record was last updated
@override final  DateTime? updatedAt;

/// Create a copy of FamilyInvitationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyInvitationModelCopyWith<_FamilyInvitationModel> get copyWith => __$FamilyInvitationModelCopyWithImpl<_FamilyInvitationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyInvitationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyInvitationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.invitedByUserId, invitedByUserId) || other.invitedByUserId == invitedByUserId)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,invitedEmail,invitedByUserId,inviteCode,role,status,expiresAt,respondedAt,createdAt,updatedAt);

@override
String toString() {
  return 'FamilyInvitationModel(id: $id, cloudId: $cloudId, familyId: $familyId, invitedEmail: $invitedEmail, invitedByUserId: $invitedByUserId, inviteCode: $inviteCode, role: $role, status: $status, expiresAt: $expiresAt, respondedAt: $respondedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyInvitationModelCopyWith<$Res> implements $FamilyInvitationModelCopyWith<$Res> {
  factory _$FamilyInvitationModelCopyWith(_FamilyInvitationModel value, $Res Function(_FamilyInvitationModel) _then) = __$FamilyInvitationModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, int? familyId, String invitedEmail, String invitedByUserId, String inviteCode, FamilyRole role, InvitationStatus status, DateTime expiresAt, DateTime? respondedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$FamilyInvitationModelCopyWithImpl<$Res>
    implements _$FamilyInvitationModelCopyWith<$Res> {
  __$FamilyInvitationModelCopyWithImpl(this._self, this._then);

  final _FamilyInvitationModel _self;
  final $Res Function(_FamilyInvitationModel) _then;

/// Create a copy of FamilyInvitationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? invitedEmail = null,Object? invitedByUserId = null,Object? inviteCode = null,Object? role = null,Object? status = null,Object? expiresAt = null,Object? respondedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FamilyInvitationModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,invitedEmail: null == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String,invitedByUserId: null == invitedByUserId ? _self.invitedByUserId : invitedByUserId // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as FamilyRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
