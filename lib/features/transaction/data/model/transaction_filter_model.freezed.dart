// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_filter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionFilter {

 String? get keyword; double? get minAmount; double? get maxAmount; String? get notes; CategoryModel? get category; TransactionType? get transactionType; DateTime? get dateStart; DateTime? get dateEnd;
/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<TransactionFilter> get copyWith => _$TransactionFilterCopyWithImpl<TransactionFilter>(this as TransactionFilter, _$identity);

  /// Serializes this TransactionFilter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFilter&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.dateStart, dateStart) || other.dateStart == dateStart)&&(identical(other.dateEnd, dateEnd) || other.dateEnd == dateEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyword,minAmount,maxAmount,notes,category,transactionType,dateStart,dateEnd);

@override
String toString() {
  return 'TransactionFilter(keyword: $keyword, minAmount: $minAmount, maxAmount: $maxAmount, notes: $notes, category: $category, transactionType: $transactionType, dateStart: $dateStart, dateEnd: $dateEnd)';
}


}

/// @nodoc
abstract mixin class $TransactionFilterCopyWith<$Res>  {
  factory $TransactionFilterCopyWith(TransactionFilter value, $Res Function(TransactionFilter) _then) = _$TransactionFilterCopyWithImpl;
@useResult
$Res call({
 String? keyword, double? minAmount, double? maxAmount, String? notes, CategoryModel? category, TransactionType? transactionType, DateTime? dateStart, DateTime? dateEnd
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$TransactionFilterCopyWithImpl<$Res>
    implements $TransactionFilterCopyWith<$Res> {
  _$TransactionFilterCopyWithImpl(this._self, this._then);

  final TransactionFilter _self;
  final $Res Function(TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyword = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? notes = freezed,Object? category = freezed,Object? transactionType = freezed,Object? dateStart = freezed,Object? dateEnd = freezed,}) {
  return _then(_self.copyWith(
keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,transactionType: freezed == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as TransactionType?,dateStart: freezed == dateStart ? _self.dateStart : dateStart // ignore: cast_nullable_to_non_nullable
as DateTime?,dateEnd: freezed == dateEnd ? _self.dateEnd : dateEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionFilter].
extension TransactionFilterPatterns on TransactionFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFilter value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFilter value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? keyword,  double? minAmount,  double? maxAmount,  String? notes,  CategoryModel? category,  TransactionType? transactionType,  DateTime? dateStart,  DateTime? dateEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.keyword,_that.minAmount,_that.maxAmount,_that.notes,_that.category,_that.transactionType,_that.dateStart,_that.dateEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? keyword,  double? minAmount,  double? maxAmount,  String? notes,  CategoryModel? category,  TransactionType? transactionType,  DateTime? dateStart,  DateTime? dateEnd)  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter():
return $default(_that.keyword,_that.minAmount,_that.maxAmount,_that.notes,_that.category,_that.transactionType,_that.dateStart,_that.dateEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? keyword,  double? minAmount,  double? maxAmount,  String? notes,  CategoryModel? category,  TransactionType? transactionType,  DateTime? dateStart,  DateTime? dateEnd)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.keyword,_that.minAmount,_that.maxAmount,_that.notes,_that.category,_that.transactionType,_that.dateStart,_that.dateEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionFilter implements TransactionFilter {
  const _TransactionFilter({this.keyword, this.minAmount, this.maxAmount, this.notes, this.category, this.transactionType, this.dateStart, this.dateEnd});
  factory _TransactionFilter.fromJson(Map<String, dynamic> json) => _$TransactionFilterFromJson(json);

@override final  String? keyword;
@override final  double? minAmount;
@override final  double? maxAmount;
@override final  String? notes;
@override final  CategoryModel? category;
@override final  TransactionType? transactionType;
@override final  DateTime? dateStart;
@override final  DateTime? dateEnd;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFilterCopyWith<_TransactionFilter> get copyWith => __$TransactionFilterCopyWithImpl<_TransactionFilter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionFilterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFilter&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.dateStart, dateStart) || other.dateStart == dateStart)&&(identical(other.dateEnd, dateEnd) || other.dateEnd == dateEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyword,minAmount,maxAmount,notes,category,transactionType,dateStart,dateEnd);

@override
String toString() {
  return 'TransactionFilter(keyword: $keyword, minAmount: $minAmount, maxAmount: $maxAmount, notes: $notes, category: $category, transactionType: $transactionType, dateStart: $dateStart, dateEnd: $dateEnd)';
}


}

/// @nodoc
abstract mixin class _$TransactionFilterCopyWith<$Res> implements $TransactionFilterCopyWith<$Res> {
  factory _$TransactionFilterCopyWith(_TransactionFilter value, $Res Function(_TransactionFilter) _then) = __$TransactionFilterCopyWithImpl;
@override @useResult
$Res call({
 String? keyword, double? minAmount, double? maxAmount, String? notes, CategoryModel? category, TransactionType? transactionType, DateTime? dateStart, DateTime? dateEnd
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$TransactionFilterCopyWithImpl<$Res>
    implements _$TransactionFilterCopyWith<$Res> {
  __$TransactionFilterCopyWithImpl(this._self, this._then);

  final _TransactionFilter _self;
  final $Res Function(_TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyword = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? notes = freezed,Object? category = freezed,Object? transactionType = freezed,Object? dateStart = freezed,Object? dateEnd = freezed,}) {
  return _then(_TransactionFilter(
keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,transactionType: freezed == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as TransactionType?,dateStart: freezed == dateStart ? _self.dateStart : dateStart // ignore: cast_nullable_to_non_nullable
as DateTime?,dateEnd: freezed == dateEnd ? _self.dateEnd : dateEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
