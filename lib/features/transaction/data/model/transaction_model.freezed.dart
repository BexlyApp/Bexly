// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionModel {

 int? get id; String? get cloudId; TransactionType get transactionType; double get amount; DateTime get date; String get title; CategoryModel get category; WalletModel get wallet; String? get notes; String? get imagePath; bool? get isRecurring; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionModelCopyWith<TransactionModel> get copyWith => _$TransactionModelCopyWithImpl<TransactionModel>(this as TransactionModel, _$identity);

  /// Serializes this TransactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,transactionType,amount,date,title,category,wallet,notes,imagePath,isRecurring,createdAt,updatedAt);

@override
String toString() {
  return 'TransactionModel(id: $id, cloudId: $cloudId, transactionType: $transactionType, amount: $amount, date: $date, title: $title, category: $category, wallet: $wallet, notes: $notes, imagePath: $imagePath, isRecurring: $isRecurring, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TransactionModelCopyWith<$Res>  {
  factory $TransactionModelCopyWith(TransactionModel value, $Res Function(TransactionModel) _then) = _$TransactionModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, TransactionType transactionType, double amount, DateTime date, String title, CategoryModel category, WalletModel wallet, String? notes, String? imagePath, bool? isRecurring, DateTime? createdAt, DateTime? updatedAt
});


$CategoryModelCopyWith<$Res> get category;$WalletModelCopyWith<$Res> get wallet;

}
/// @nodoc
class _$TransactionModelCopyWithImpl<$Res>
    implements $TransactionModelCopyWith<$Res> {
  _$TransactionModelCopyWithImpl(this._self, this._then);

  final TransactionModel _self;
  final $Res Function(TransactionModel) _then;

/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? transactionType = null,Object? amount = null,Object? date = null,Object? title = null,Object? category = null,Object? wallet = null,Object? notes = freezed,Object? imagePath = freezed,Object? isRecurring = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as TransactionType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletModel,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: freezed == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletModelCopyWith<$Res> get wallet {
  
  return $WalletModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionModel].
extension TransactionModelPatterns on TransactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionModel value)  $default,){
final _that = this;
switch (_that) {
case _TransactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  TransactionType transactionType,  double amount,  DateTime date,  String title,  CategoryModel category,  WalletModel wallet,  String? notes,  String? imagePath,  bool? isRecurring,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.transactionType,_that.amount,_that.date,_that.title,_that.category,_that.wallet,_that.notes,_that.imagePath,_that.isRecurring,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  TransactionType transactionType,  double amount,  DateTime date,  String title,  CategoryModel category,  WalletModel wallet,  String? notes,  String? imagePath,  bool? isRecurring,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TransactionModel():
return $default(_that.id,_that.cloudId,_that.transactionType,_that.amount,_that.date,_that.title,_that.category,_that.wallet,_that.notes,_that.imagePath,_that.isRecurring,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  TransactionType transactionType,  double amount,  DateTime date,  String title,  CategoryModel category,  WalletModel wallet,  String? notes,  String? imagePath,  bool? isRecurring,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.transactionType,_that.amount,_that.date,_that.title,_that.category,_that.wallet,_that.notes,_that.imagePath,_that.isRecurring,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionModel implements TransactionModel {
  const _TransactionModel({this.id, this.cloudId, required this.transactionType, required this.amount, required this.date, required this.title, required this.category, required this.wallet, this.notes, this.imagePath, this.isRecurring, this.createdAt, this.updatedAt});
  factory _TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

@override final  int? id;
@override final  String? cloudId;
@override final  TransactionType transactionType;
@override final  double amount;
@override final  DateTime date;
@override final  String title;
@override final  CategoryModel category;
@override final  WalletModel wallet;
@override final  String? notes;
@override final  String? imagePath;
@override final  bool? isRecurring;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionModelCopyWith<_TransactionModel> get copyWith => __$TransactionModelCopyWithImpl<_TransactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,transactionType,amount,date,title,category,wallet,notes,imagePath,isRecurring,createdAt,updatedAt);

@override
String toString() {
  return 'TransactionModel(id: $id, cloudId: $cloudId, transactionType: $transactionType, amount: $amount, date: $date, title: $title, category: $category, wallet: $wallet, notes: $notes, imagePath: $imagePath, isRecurring: $isRecurring, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionModelCopyWith<$Res> implements $TransactionModelCopyWith<$Res> {
  factory _$TransactionModelCopyWith(_TransactionModel value, $Res Function(_TransactionModel) _then) = __$TransactionModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, TransactionType transactionType, double amount, DateTime date, String title, CategoryModel category, WalletModel wallet, String? notes, String? imagePath, bool? isRecurring, DateTime? createdAt, DateTime? updatedAt
});


@override $CategoryModelCopyWith<$Res> get category;@override $WalletModelCopyWith<$Res> get wallet;

}
/// @nodoc
class __$TransactionModelCopyWithImpl<$Res>
    implements _$TransactionModelCopyWith<$Res> {
  __$TransactionModelCopyWithImpl(this._self, this._then);

  final _TransactionModel _self;
  final $Res Function(_TransactionModel) _then;

/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? transactionType = null,Object? amount = null,Object? date = null,Object? title = null,Object? category = null,Object? wallet = null,Object? notes = freezed,Object? imagePath = freezed,Object? isRecurring = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TransactionModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as TransactionType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletModel,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: freezed == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of TransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletModelCopyWith<$Res> get wallet {
  
  return $WalletModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}

// dart format on
