// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoalModel {

/// The unique identifier for the goal. Null if the goal is new and not yet saved.
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// The name or title of the financial goal (e.g., "New Laptop", "Vacation Fund").
 String get title;/// The target monetary amount for the goal.
 double get targetAmount;/// The current amount saved towards the goal. Defaults to 0.0.
 double get currentAmount;/// The optional deadline date by which the goal should be achieved.
 DateTime? get startDate; DateTime get endDate;/// The identifier or name of the icon associated with this goal.
 String? get iconName;/// An optional description for the goal.
 String? get description;/// The date when the goal was created.
 DateTime? get createdAt;/// Timestamp when goal was last updated
 DateTime? get updatedAt;/// Optional ID of an associated account or fund source for this goal.
 int? get associatedAccountId;/// Indicates if the goal is pinned for priority viewing.
 bool get pinned;
/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalModelCopyWith<GoalModel> get copyWith => _$GoalModelCopyWithImpl<GoalModel>(this as GoalModel, _$identity);

  /// Serializes this GoalModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.title, title) || other.title == title)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.associatedAccountId, associatedAccountId) || other.associatedAccountId == associatedAccountId)&&(identical(other.pinned, pinned) || other.pinned == pinned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,title,targetAmount,currentAmount,startDate,endDate,iconName,description,createdAt,updatedAt,associatedAccountId,pinned);

@override
String toString() {
  return 'GoalModel(id: $id, cloudId: $cloudId, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, endDate: $endDate, iconName: $iconName, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, associatedAccountId: $associatedAccountId, pinned: $pinned)';
}


}

/// @nodoc
abstract mixin class $GoalModelCopyWith<$Res>  {
  factory $GoalModelCopyWith(GoalModel value, $Res Function(GoalModel) _then) = _$GoalModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String title, double targetAmount, double currentAmount, DateTime? startDate, DateTime endDate, String? iconName, String? description, DateTime? createdAt, DateTime? updatedAt, int? associatedAccountId, bool pinned
});




}
/// @nodoc
class _$GoalModelCopyWithImpl<$Res>
    implements $GoalModelCopyWith<$Res> {
  _$GoalModelCopyWithImpl(this._self, this._then);

  final GoalModel _self;
  final $Res Function(GoalModel) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? title = null,Object? targetAmount = null,Object? currentAmount = null,Object? startDate = freezed,Object? endDate = null,Object? iconName = freezed,Object? description = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? associatedAccountId = freezed,Object? pinned = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,associatedAccountId: freezed == associatedAccountId ? _self.associatedAccountId : associatedAccountId // ignore: cast_nullable_to_non_nullable
as int?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalModel].
extension GoalModelPatterns on GoalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalModel value)  $default,){
final _that = this;
switch (_that) {
case _GoalModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalModel value)?  $default,){
final _that = this;
switch (_that) {
case _GoalModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String title,  double targetAmount,  double currentAmount,  DateTime? startDate,  DateTime endDate,  String? iconName,  String? description,  DateTime? createdAt,  DateTime? updatedAt,  int? associatedAccountId,  bool pinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.title,_that.targetAmount,_that.currentAmount,_that.startDate,_that.endDate,_that.iconName,_that.description,_that.createdAt,_that.updatedAt,_that.associatedAccountId,_that.pinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String title,  double targetAmount,  double currentAmount,  DateTime? startDate,  DateTime endDate,  String? iconName,  String? description,  DateTime? createdAt,  DateTime? updatedAt,  int? associatedAccountId,  bool pinned)  $default,) {final _that = this;
switch (_that) {
case _GoalModel():
return $default(_that.id,_that.cloudId,_that.title,_that.targetAmount,_that.currentAmount,_that.startDate,_that.endDate,_that.iconName,_that.description,_that.createdAt,_that.updatedAt,_that.associatedAccountId,_that.pinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String title,  double targetAmount,  double currentAmount,  DateTime? startDate,  DateTime endDate,  String? iconName,  String? description,  DateTime? createdAt,  DateTime? updatedAt,  int? associatedAccountId,  bool pinned)?  $default,) {final _that = this;
switch (_that) {
case _GoalModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.title,_that.targetAmount,_that.currentAmount,_that.startDate,_that.endDate,_that.iconName,_that.description,_that.createdAt,_that.updatedAt,_that.associatedAccountId,_that.pinned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalModel implements GoalModel {
  const _GoalModel({this.id, this.cloudId, required this.title, required this.targetAmount, this.currentAmount = 0.0, this.startDate, required this.endDate, this.iconName, this.description, this.createdAt, this.updatedAt, this.associatedAccountId, this.pinned = false});
  factory _GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);

/// The unique identifier for the goal. Null if the goal is new and not yet saved.
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// The name or title of the financial goal (e.g., "New Laptop", "Vacation Fund").
@override final  String title;
/// The target monetary amount for the goal.
@override final  double targetAmount;
/// The current amount saved towards the goal. Defaults to 0.0.
@override@JsonKey() final  double currentAmount;
/// The optional deadline date by which the goal should be achieved.
@override final  DateTime? startDate;
@override final  DateTime endDate;
/// The identifier or name of the icon associated with this goal.
@override final  String? iconName;
/// An optional description for the goal.
@override final  String? description;
/// The date when the goal was created.
@override final  DateTime? createdAt;
/// Timestamp when goal was last updated
@override final  DateTime? updatedAt;
/// Optional ID of an associated account or fund source for this goal.
@override final  int? associatedAccountId;
/// Indicates if the goal is pinned for priority viewing.
@override@JsonKey() final  bool pinned;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalModelCopyWith<_GoalModel> get copyWith => __$GoalModelCopyWithImpl<_GoalModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.title, title) || other.title == title)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.associatedAccountId, associatedAccountId) || other.associatedAccountId == associatedAccountId)&&(identical(other.pinned, pinned) || other.pinned == pinned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,title,targetAmount,currentAmount,startDate,endDate,iconName,description,createdAt,updatedAt,associatedAccountId,pinned);

@override
String toString() {
  return 'GoalModel(id: $id, cloudId: $cloudId, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, endDate: $endDate, iconName: $iconName, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, associatedAccountId: $associatedAccountId, pinned: $pinned)';
}


}

/// @nodoc
abstract mixin class _$GoalModelCopyWith<$Res> implements $GoalModelCopyWith<$Res> {
  factory _$GoalModelCopyWith(_GoalModel value, $Res Function(_GoalModel) _then) = __$GoalModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String title, double targetAmount, double currentAmount, DateTime? startDate, DateTime endDate, String? iconName, String? description, DateTime? createdAt, DateTime? updatedAt, int? associatedAccountId, bool pinned
});




}
/// @nodoc
class __$GoalModelCopyWithImpl<$Res>
    implements _$GoalModelCopyWith<$Res> {
  __$GoalModelCopyWithImpl(this._self, this._then);

  final _GoalModel _self;
  final $Res Function(_GoalModel) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? title = null,Object? targetAmount = null,Object? currentAmount = null,Object? startDate = freezed,Object? endDate = null,Object? iconName = freezed,Object? description = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? associatedAccountId = freezed,Object? pinned = null,}) {
  return _then(_GoalModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,associatedAccountId: freezed == associatedAccountId ? _self.associatedAccountId : associatedAccountId // ignore: cast_nullable_to_non_nullable
as int?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
