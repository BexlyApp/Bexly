// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_sync_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailSyncSettingsModel {

/// Local database ID
 int? get id;/// Connected Gmail email address
 String? get gmailEmail;/// Whether email sync is enabled
 bool get isEnabled;/// Timestamp of last successful sync
 DateTime? get lastSyncTime;/// List of enabled bank domains to scan
/// Stored as JSON array string in database
 List<String> get enabledBanks;/// Total number of transactions imported from email
 int get totalImported;/// Number of transactions pending review
 int get pendingReview;/// Auto-sync frequency (default: every 24 hours)
 SyncFrequency get syncFrequency;/// Timestamp when settings were created
 DateTime? get createdAt;/// Timestamp when settings were last updated
 DateTime? get updatedAt;
/// Create a copy of EmailSyncSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailSyncSettingsModelCopyWith<EmailSyncSettingsModel> get copyWith => _$EmailSyncSettingsModelCopyWithImpl<EmailSyncSettingsModel>(this as EmailSyncSettingsModel, _$identity);

  /// Serializes this EmailSyncSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailSyncSettingsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.gmailEmail, gmailEmail) || other.gmailEmail == gmailEmail)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime)&&const DeepCollectionEquality().equals(other.enabledBanks, enabledBanks)&&(identical(other.totalImported, totalImported) || other.totalImported == totalImported)&&(identical(other.pendingReview, pendingReview) || other.pendingReview == pendingReview)&&(identical(other.syncFrequency, syncFrequency) || other.syncFrequency == syncFrequency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gmailEmail,isEnabled,lastSyncTime,const DeepCollectionEquality().hash(enabledBanks),totalImported,pendingReview,syncFrequency,createdAt,updatedAt);

@override
String toString() {
  return 'EmailSyncSettingsModel(id: $id, gmailEmail: $gmailEmail, isEnabled: $isEnabled, lastSyncTime: $lastSyncTime, enabledBanks: $enabledBanks, totalImported: $totalImported, pendingReview: $pendingReview, syncFrequency: $syncFrequency, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EmailSyncSettingsModelCopyWith<$Res>  {
  factory $EmailSyncSettingsModelCopyWith(EmailSyncSettingsModel value, $Res Function(EmailSyncSettingsModel) _then) = _$EmailSyncSettingsModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? gmailEmail, bool isEnabled, DateTime? lastSyncTime, List<String> enabledBanks, int totalImported, int pendingReview, SyncFrequency syncFrequency, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$EmailSyncSettingsModelCopyWithImpl<$Res>
    implements $EmailSyncSettingsModelCopyWith<$Res> {
  _$EmailSyncSettingsModelCopyWithImpl(this._self, this._then);

  final EmailSyncSettingsModel _self;
  final $Res Function(EmailSyncSettingsModel) _then;

/// Create a copy of EmailSyncSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? gmailEmail = freezed,Object? isEnabled = null,Object? lastSyncTime = freezed,Object? enabledBanks = null,Object? totalImported = null,Object? pendingReview = null,Object? syncFrequency = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,gmailEmail: freezed == gmailEmail ? _self.gmailEmail : gmailEmail // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,enabledBanks: null == enabledBanks ? _self.enabledBanks : enabledBanks // ignore: cast_nullable_to_non_nullable
as List<String>,totalImported: null == totalImported ? _self.totalImported : totalImported // ignore: cast_nullable_to_non_nullable
as int,pendingReview: null == pendingReview ? _self.pendingReview : pendingReview // ignore: cast_nullable_to_non_nullable
as int,syncFrequency: null == syncFrequency ? _self.syncFrequency : syncFrequency // ignore: cast_nullable_to_non_nullable
as SyncFrequency,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailSyncSettingsModel].
extension EmailSyncSettingsModelPatterns on EmailSyncSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailSyncSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailSyncSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailSyncSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _EmailSyncSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailSyncSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _EmailSyncSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? gmailEmail,  bool isEnabled,  DateTime? lastSyncTime,  List<String> enabledBanks,  int totalImported,  int pendingReview,  SyncFrequency syncFrequency,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailSyncSettingsModel() when $default != null:
return $default(_that.id,_that.gmailEmail,_that.isEnabled,_that.lastSyncTime,_that.enabledBanks,_that.totalImported,_that.pendingReview,_that.syncFrequency,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? gmailEmail,  bool isEnabled,  DateTime? lastSyncTime,  List<String> enabledBanks,  int totalImported,  int pendingReview,  SyncFrequency syncFrequency,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EmailSyncSettingsModel():
return $default(_that.id,_that.gmailEmail,_that.isEnabled,_that.lastSyncTime,_that.enabledBanks,_that.totalImported,_that.pendingReview,_that.syncFrequency,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? gmailEmail,  bool isEnabled,  DateTime? lastSyncTime,  List<String> enabledBanks,  int totalImported,  int pendingReview,  SyncFrequency syncFrequency,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EmailSyncSettingsModel() when $default != null:
return $default(_that.id,_that.gmailEmail,_that.isEnabled,_that.lastSyncTime,_that.enabledBanks,_that.totalImported,_that.pendingReview,_that.syncFrequency,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmailSyncSettingsModel implements EmailSyncSettingsModel {
  const _EmailSyncSettingsModel({this.id, this.gmailEmail, this.isEnabled = false, this.lastSyncTime, final  List<String> enabledBanks = const [], this.totalImported = 0, this.pendingReview = 0, this.syncFrequency = SyncFrequency.every24Hours, this.createdAt, this.updatedAt}): _enabledBanks = enabledBanks;
  factory _EmailSyncSettingsModel.fromJson(Map<String, dynamic> json) => _$EmailSyncSettingsModelFromJson(json);

/// Local database ID
@override final  int? id;
/// Connected Gmail email address
@override final  String? gmailEmail;
/// Whether email sync is enabled
@override@JsonKey() final  bool isEnabled;
/// Timestamp of last successful sync
@override final  DateTime? lastSyncTime;
/// List of enabled bank domains to scan
/// Stored as JSON array string in database
 final  List<String> _enabledBanks;
/// List of enabled bank domains to scan
/// Stored as JSON array string in database
@override@JsonKey() List<String> get enabledBanks {
  if (_enabledBanks is EqualUnmodifiableListView) return _enabledBanks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enabledBanks);
}

/// Total number of transactions imported from email
@override@JsonKey() final  int totalImported;
/// Number of transactions pending review
@override@JsonKey() final  int pendingReview;
/// Auto-sync frequency (default: every 24 hours)
@override@JsonKey() final  SyncFrequency syncFrequency;
/// Timestamp when settings were created
@override final  DateTime? createdAt;
/// Timestamp when settings were last updated
@override final  DateTime? updatedAt;

/// Create a copy of EmailSyncSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailSyncSettingsModelCopyWith<_EmailSyncSettingsModel> get copyWith => __$EmailSyncSettingsModelCopyWithImpl<_EmailSyncSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmailSyncSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailSyncSettingsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.gmailEmail, gmailEmail) || other.gmailEmail == gmailEmail)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime)&&const DeepCollectionEquality().equals(other._enabledBanks, _enabledBanks)&&(identical(other.totalImported, totalImported) || other.totalImported == totalImported)&&(identical(other.pendingReview, pendingReview) || other.pendingReview == pendingReview)&&(identical(other.syncFrequency, syncFrequency) || other.syncFrequency == syncFrequency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gmailEmail,isEnabled,lastSyncTime,const DeepCollectionEquality().hash(_enabledBanks),totalImported,pendingReview,syncFrequency,createdAt,updatedAt);

@override
String toString() {
  return 'EmailSyncSettingsModel(id: $id, gmailEmail: $gmailEmail, isEnabled: $isEnabled, lastSyncTime: $lastSyncTime, enabledBanks: $enabledBanks, totalImported: $totalImported, pendingReview: $pendingReview, syncFrequency: $syncFrequency, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EmailSyncSettingsModelCopyWith<$Res> implements $EmailSyncSettingsModelCopyWith<$Res> {
  factory _$EmailSyncSettingsModelCopyWith(_EmailSyncSettingsModel value, $Res Function(_EmailSyncSettingsModel) _then) = __$EmailSyncSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? gmailEmail, bool isEnabled, DateTime? lastSyncTime, List<String> enabledBanks, int totalImported, int pendingReview, SyncFrequency syncFrequency, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$EmailSyncSettingsModelCopyWithImpl<$Res>
    implements _$EmailSyncSettingsModelCopyWith<$Res> {
  __$EmailSyncSettingsModelCopyWithImpl(this._self, this._then);

  final _EmailSyncSettingsModel _self;
  final $Res Function(_EmailSyncSettingsModel) _then;

/// Create a copy of EmailSyncSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? gmailEmail = freezed,Object? isEnabled = null,Object? lastSyncTime = freezed,Object? enabledBanks = null,Object? totalImported = null,Object? pendingReview = null,Object? syncFrequency = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EmailSyncSettingsModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,gmailEmail: freezed == gmailEmail ? _self.gmailEmail : gmailEmail // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,enabledBanks: null == enabledBanks ? _self._enabledBanks : enabledBanks // ignore: cast_nullable_to_non_nullable
as List<String>,totalImported: null == totalImported ? _self.totalImported : totalImported // ignore: cast_nullable_to_non_nullable
as int,pendingReview: null == pendingReview ? _self.pendingReview : pendingReview // ignore: cast_nullable_to_non_nullable
as int,syncFrequency: null == syncFrequency ? _self.syncFrequency : syncFrequency // ignore: cast_nullable_to_non_nullable
as SyncFrequency,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
