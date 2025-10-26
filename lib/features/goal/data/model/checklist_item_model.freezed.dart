// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistItemModel {

/// The unique identifier for the checklist item.
/// Null if the item is new and not yet saved to the database.
 int? get id;/// The identifier of the [GoalModel] this checklist item belongs to.
 int get goalId;/// The title or description of the checklist item (e.g., "Save \$50 for concert tickets").
 String get title;/// An optional monetary amount associated with this checklist item.
/// This could represent a target amount to save or spend for this specific item.
 double get amount;/// An optional web link related to the checklist item (e.g., a link to a product page).
 String get link; bool get completed;
/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistItemModelCopyWith<ChecklistItemModel> get copyWith => _$ChecklistItemModelCopyWithImpl<ChecklistItemModel>(this as ChecklistItemModel, _$identity);

  /// Serializes this ChecklistItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.link, link) || other.link == link)&&(identical(other.completed, completed) || other.completed == completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goalId,title,amount,link,completed);

@override
String toString() {
  return 'ChecklistItemModel(id: $id, goalId: $goalId, title: $title, amount: $amount, link: $link, completed: $completed)';
}


}

/// @nodoc
abstract mixin class $ChecklistItemModelCopyWith<$Res>  {
  factory $ChecklistItemModelCopyWith(ChecklistItemModel value, $Res Function(ChecklistItemModel) _then) = _$ChecklistItemModelCopyWithImpl;
@useResult
$Res call({
 int? id, int goalId, String title, double amount, String link, bool completed
});




}
/// @nodoc
class _$ChecklistItemModelCopyWithImpl<$Res>
    implements $ChecklistItemModelCopyWith<$Res> {
  _$ChecklistItemModelCopyWithImpl(this._self, this._then);

  final ChecklistItemModel _self;
  final $Res Function(ChecklistItemModel) _then;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? goalId = null,Object? title = null,Object? amount = null,Object? link = null,Object? completed = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistItemModel].
extension ChecklistItemModelPatterns on ChecklistItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistItemModel value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int goalId,  String title,  double amount,  String link,  bool completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
return $default(_that.id,_that.goalId,_that.title,_that.amount,_that.link,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int goalId,  String title,  double amount,  String link,  bool completed)  $default,) {final _that = this;
switch (_that) {
case _ChecklistItemModel():
return $default(_that.id,_that.goalId,_that.title,_that.amount,_that.link,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int goalId,  String title,  double amount,  String link,  bool completed)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
return $default(_that.id,_that.goalId,_that.title,_that.amount,_that.link,_that.completed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistItemModel extends ChecklistItemModel {
  const _ChecklistItemModel({this.id, required this.goalId, required this.title, this.amount = 0.0, this.link = '', this.completed = false}): super._();
  factory _ChecklistItemModel.fromJson(Map<String, dynamic> json) => _$ChecklistItemModelFromJson(json);

/// The unique identifier for the checklist item.
/// Null if the item is new and not yet saved to the database.
@override final  int? id;
/// The identifier of the [GoalModel] this checklist item belongs to.
@override final  int goalId;
/// The title or description of the checklist item (e.g., "Save \$50 for concert tickets").
@override final  String title;
/// An optional monetary amount associated with this checklist item.
/// This could represent a target amount to save or spend for this specific item.
@override@JsonKey() final  double amount;
/// An optional web link related to the checklist item (e.g., a link to a product page).
@override@JsonKey() final  String link;
@override@JsonKey() final  bool completed;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistItemModelCopyWith<_ChecklistItemModel> get copyWith => __$ChecklistItemModelCopyWithImpl<_ChecklistItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.link, link) || other.link == link)&&(identical(other.completed, completed) || other.completed == completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goalId,title,amount,link,completed);

@override
String toString() {
  return 'ChecklistItemModel(id: $id, goalId: $goalId, title: $title, amount: $amount, link: $link, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$ChecklistItemModelCopyWith<$Res> implements $ChecklistItemModelCopyWith<$Res> {
  factory _$ChecklistItemModelCopyWith(_ChecklistItemModel value, $Res Function(_ChecklistItemModel) _then) = __$ChecklistItemModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, int goalId, String title, double amount, String link, bool completed
});




}
/// @nodoc
class __$ChecklistItemModelCopyWithImpl<$Res>
    implements _$ChecklistItemModelCopyWith<$Res> {
  __$ChecklistItemModelCopyWithImpl(this._self, this._then);

  final _ChecklistItemModel _self;
  final $Res Function(_ChecklistItemModel) _then;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? goalId = null,Object? title = null,Object? amount = null,Object? link = null,Object? completed = null,}) {
  return _then(_ChecklistItemModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
