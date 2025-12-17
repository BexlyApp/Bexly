// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_wallet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharedWalletModel {

/// Local database ID
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// Local family group ID
 int? get familyId;/// Local wallet ID
 int? get walletId;/// Firebase UID of the user who shared the wallet
 String get sharedByUserId;/// Whether the wallet is currently being shared
 bool get isActive;/// When the wallet was shared
 DateTime? get sharedAt;/// When the wallet was unshared (if isActive = false)
 DateTime? get unsharedAt;/// Timestamp when record was created
 DateTime? get createdAt;/// Timestamp when record was last updated
 DateTime? get updatedAt;
/// Create a copy of SharedWalletModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedWalletModelCopyWith<SharedWalletModel> get copyWith => _$SharedWalletModelCopyWithImpl<SharedWalletModel>(this as SharedWalletModel, _$identity);

  /// Serializes this SharedWalletModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedWalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.sharedByUserId, sharedByUserId) || other.sharedByUserId == sharedByUserId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sharedAt, sharedAt) || other.sharedAt == sharedAt)&&(identical(other.unsharedAt, unsharedAt) || other.unsharedAt == unsharedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,walletId,sharedByUserId,isActive,sharedAt,unsharedAt,createdAt,updatedAt);

@override
String toString() {
  return 'SharedWalletModel(id: $id, cloudId: $cloudId, familyId: $familyId, walletId: $walletId, sharedByUserId: $sharedByUserId, isActive: $isActive, sharedAt: $sharedAt, unsharedAt: $unsharedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SharedWalletModelCopyWith<$Res>  {
  factory $SharedWalletModelCopyWith(SharedWalletModel value, $Res Function(SharedWalletModel) _then) = _$SharedWalletModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, int? familyId, int? walletId, String sharedByUserId, bool isActive, DateTime? sharedAt, DateTime? unsharedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$SharedWalletModelCopyWithImpl<$Res>
    implements $SharedWalletModelCopyWith<$Res> {
  _$SharedWalletModelCopyWithImpl(this._self, this._then);

  final SharedWalletModel _self;
  final $Res Function(SharedWalletModel) _then;

/// Create a copy of SharedWalletModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? walletId = freezed,Object? sharedByUserId = null,Object? isActive = null,Object? sharedAt = freezed,Object? unsharedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,walletId: freezed == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as int?,sharedByUserId: null == sharedByUserId ? _self.sharedByUserId : sharedByUserId // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sharedAt: freezed == sharedAt ? _self.sharedAt : sharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unsharedAt: freezed == unsharedAt ? _self.unsharedAt : unsharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedWalletModel].
extension SharedWalletModelPatterns on SharedWalletModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedWalletModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedWalletModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedWalletModel value)  $default,){
final _that = this;
switch (_that) {
case _SharedWalletModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedWalletModel value)?  $default,){
final _that = this;
switch (_that) {
case _SharedWalletModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  int? walletId,  String sharedByUserId,  bool isActive,  DateTime? sharedAt,  DateTime? unsharedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedWalletModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.walletId,_that.sharedByUserId,_that.isActive,_that.sharedAt,_that.unsharedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  int? familyId,  int? walletId,  String sharedByUserId,  bool isActive,  DateTime? sharedAt,  DateTime? unsharedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SharedWalletModel():
return $default(_that.id,_that.cloudId,_that.familyId,_that.walletId,_that.sharedByUserId,_that.isActive,_that.sharedAt,_that.unsharedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  int? familyId,  int? walletId,  String sharedByUserId,  bool isActive,  DateTime? sharedAt,  DateTime? unsharedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SharedWalletModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.familyId,_that.walletId,_that.sharedByUserId,_that.isActive,_that.sharedAt,_that.unsharedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedWalletModel implements SharedWalletModel {
  const _SharedWalletModel({this.id, this.cloudId, this.familyId, this.walletId, required this.sharedByUserId, this.isActive = true, this.sharedAt, this.unsharedAt, this.createdAt, this.updatedAt});
  factory _SharedWalletModel.fromJson(Map<String, dynamic> json) => _$SharedWalletModelFromJson(json);

/// Local database ID
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// Local family group ID
@override final  int? familyId;
/// Local wallet ID
@override final  int? walletId;
/// Firebase UID of the user who shared the wallet
@override final  String sharedByUserId;
/// Whether the wallet is currently being shared
@override@JsonKey() final  bool isActive;
/// When the wallet was shared
@override final  DateTime? sharedAt;
/// When the wallet was unshared (if isActive = false)
@override final  DateTime? unsharedAt;
/// Timestamp when record was created
@override final  DateTime? createdAt;
/// Timestamp when record was last updated
@override final  DateTime? updatedAt;

/// Create a copy of SharedWalletModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedWalletModelCopyWith<_SharedWalletModel> get copyWith => __$SharedWalletModelCopyWithImpl<_SharedWalletModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedWalletModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedWalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.sharedByUserId, sharedByUserId) || other.sharedByUserId == sharedByUserId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sharedAt, sharedAt) || other.sharedAt == sharedAt)&&(identical(other.unsharedAt, unsharedAt) || other.unsharedAt == unsharedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,familyId,walletId,sharedByUserId,isActive,sharedAt,unsharedAt,createdAt,updatedAt);

@override
String toString() {
  return 'SharedWalletModel(id: $id, cloudId: $cloudId, familyId: $familyId, walletId: $walletId, sharedByUserId: $sharedByUserId, isActive: $isActive, sharedAt: $sharedAt, unsharedAt: $unsharedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SharedWalletModelCopyWith<$Res> implements $SharedWalletModelCopyWith<$Res> {
  factory _$SharedWalletModelCopyWith(_SharedWalletModel value, $Res Function(_SharedWalletModel) _then) = __$SharedWalletModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, int? familyId, int? walletId, String sharedByUserId, bool isActive, DateTime? sharedAt, DateTime? unsharedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$SharedWalletModelCopyWithImpl<$Res>
    implements _$SharedWalletModelCopyWith<$Res> {
  __$SharedWalletModelCopyWithImpl(this._self, this._then);

  final _SharedWalletModel _self;
  final $Res Function(_SharedWalletModel) _then;

/// Create a copy of SharedWalletModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? familyId = freezed,Object? walletId = freezed,Object? sharedByUserId = null,Object? isActive = null,Object? sharedAt = freezed,Object? unsharedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SharedWalletModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,familyId: freezed == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as int?,walletId: freezed == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as int?,sharedByUserId: null == sharedByUserId ? _self.sharedByUserId : sharedByUserId // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sharedAt: freezed == sharedAt ? _self.sharedAt : sharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unsharedAt: freezed == unsharedAt ? _self.unsharedAt : unsharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
