// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linked_account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinkedAccount {

 String get id; String get institutionName; String? get displayName; String? get last4; String? get category;// checking, savings, credit_card, etc.
 String? get status; LinkedAccountBalance? get balance;
/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedAccountCopyWith<LinkedAccount> get copyWith => _$LinkedAccountCopyWithImpl<LinkedAccount>(this as LinkedAccount, _$identity);

  /// Serializes this LinkedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,institutionName,displayName,last4,category,status,balance);

@override
String toString() {
  return 'LinkedAccount(id: $id, institutionName: $institutionName, displayName: $displayName, last4: $last4, category: $category, status: $status, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $LinkedAccountCopyWith<$Res>  {
  factory $LinkedAccountCopyWith(LinkedAccount value, $Res Function(LinkedAccount) _then) = _$LinkedAccountCopyWithImpl;
@useResult
$Res call({
 String id, String institutionName, String? displayName, String? last4, String? category, String? status, LinkedAccountBalance? balance
});


$LinkedAccountBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$LinkedAccountCopyWithImpl<$Res>
    implements $LinkedAccountCopyWith<$Res> {
  _$LinkedAccountCopyWithImpl(this._self, this._then);

  final LinkedAccount _self;
  final $Res Function(LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? institutionName = null,Object? displayName = freezed,Object? last4 = freezed,Object? category = freezed,Object? status = freezed,Object? balance = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,institutionName: null == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as LinkedAccountBalance?,
  ));
}
/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedAccountBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $LinkedAccountBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// Adds pattern-matching-related methods to [LinkedAccount].
extension LinkedAccountPatterns on LinkedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedAccount value)  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String institutionName,  String? displayName,  String? last4,  String? category,  String? status,  LinkedAccountBalance? balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.institutionName,_that.displayName,_that.last4,_that.category,_that.status,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String institutionName,  String? displayName,  String? last4,  String? category,  String? status,  LinkedAccountBalance? balance)  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount():
return $default(_that.id,_that.institutionName,_that.displayName,_that.last4,_that.category,_that.status,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String institutionName,  String? displayName,  String? last4,  String? category,  String? status,  LinkedAccountBalance? balance)?  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.institutionName,_that.displayName,_that.last4,_that.category,_that.status,_that.balance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedAccount implements LinkedAccount {
  const _LinkedAccount({required this.id, required this.institutionName, this.displayName, this.last4, this.category, this.status, this.balance});
  factory _LinkedAccount.fromJson(Map<String, dynamic> json) => _$LinkedAccountFromJson(json);

@override final  String id;
@override final  String institutionName;
@override final  String? displayName;
@override final  String? last4;
@override final  String? category;
// checking, savings, credit_card, etc.
@override final  String? status;
@override final  LinkedAccountBalance? balance;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedAccountCopyWith<_LinkedAccount> get copyWith => __$LinkedAccountCopyWithImpl<_LinkedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,institutionName,displayName,last4,category,status,balance);

@override
String toString() {
  return 'LinkedAccount(id: $id, institutionName: $institutionName, displayName: $displayName, last4: $last4, category: $category, status: $status, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$LinkedAccountCopyWith<$Res> implements $LinkedAccountCopyWith<$Res> {
  factory _$LinkedAccountCopyWith(_LinkedAccount value, $Res Function(_LinkedAccount) _then) = __$LinkedAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String institutionName, String? displayName, String? last4, String? category, String? status, LinkedAccountBalance? balance
});


@override $LinkedAccountBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class __$LinkedAccountCopyWithImpl<$Res>
    implements _$LinkedAccountCopyWith<$Res> {
  __$LinkedAccountCopyWithImpl(this._self, this._then);

  final _LinkedAccount _self;
  final $Res Function(_LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? institutionName = null,Object? displayName = freezed,Object? last4 = freezed,Object? category = freezed,Object? status = freezed,Object? balance = freezed,}) {
  return _then(_LinkedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,institutionName: null == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as LinkedAccountBalance?,
  ));
}

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedAccountBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $LinkedAccountBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// @nodoc
mixin _$LinkedAccountBalance {

 int? get current; int? get available; String? get asOf;
/// Create a copy of LinkedAccountBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedAccountBalanceCopyWith<LinkedAccountBalance> get copyWith => _$LinkedAccountBalanceCopyWithImpl<LinkedAccountBalance>(this as LinkedAccountBalance, _$identity);

  /// Serializes this LinkedAccountBalance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedAccountBalance&&(identical(other.current, current) || other.current == current)&&(identical(other.available, available) || other.available == available)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,available,asOf);

@override
String toString() {
  return 'LinkedAccountBalance(current: $current, available: $available, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $LinkedAccountBalanceCopyWith<$Res>  {
  factory $LinkedAccountBalanceCopyWith(LinkedAccountBalance value, $Res Function(LinkedAccountBalance) _then) = _$LinkedAccountBalanceCopyWithImpl;
@useResult
$Res call({
 int? current, int? available, String? asOf
});




}
/// @nodoc
class _$LinkedAccountBalanceCopyWithImpl<$Res>
    implements $LinkedAccountBalanceCopyWith<$Res> {
  _$LinkedAccountBalanceCopyWithImpl(this._self, this._then);

  final LinkedAccountBalance _self;
  final $Res Function(LinkedAccountBalance) _then;

/// Create a copy of LinkedAccountBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? current = freezed,Object? available = freezed,Object? asOf = freezed,}) {
  return _then(_self.copyWith(
current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int?,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int?,asOf: freezed == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedAccountBalance].
extension LinkedAccountBalancePatterns on LinkedAccountBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedAccountBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedAccountBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedAccountBalance value)  $default,){
final _that = this;
switch (_that) {
case _LinkedAccountBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedAccountBalance value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedAccountBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? current,  int? available,  String? asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedAccountBalance() when $default != null:
return $default(_that.current,_that.available,_that.asOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? current,  int? available,  String? asOf)  $default,) {final _that = this;
switch (_that) {
case _LinkedAccountBalance():
return $default(_that.current,_that.available,_that.asOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? current,  int? available,  String? asOf)?  $default,) {final _that = this;
switch (_that) {
case _LinkedAccountBalance() when $default != null:
return $default(_that.current,_that.available,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedAccountBalance implements LinkedAccountBalance {
  const _LinkedAccountBalance({this.current, this.available, this.asOf});
  factory _LinkedAccountBalance.fromJson(Map<String, dynamic> json) => _$LinkedAccountBalanceFromJson(json);

@override final  int? current;
@override final  int? available;
@override final  String? asOf;

/// Create a copy of LinkedAccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedAccountBalanceCopyWith<_LinkedAccountBalance> get copyWith => __$LinkedAccountBalanceCopyWithImpl<_LinkedAccountBalance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedAccountBalanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedAccountBalance&&(identical(other.current, current) || other.current == current)&&(identical(other.available, available) || other.available == available)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,available,asOf);

@override
String toString() {
  return 'LinkedAccountBalance(current: $current, available: $available, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$LinkedAccountBalanceCopyWith<$Res> implements $LinkedAccountBalanceCopyWith<$Res> {
  factory _$LinkedAccountBalanceCopyWith(_LinkedAccountBalance value, $Res Function(_LinkedAccountBalance) _then) = __$LinkedAccountBalanceCopyWithImpl;
@override @useResult
$Res call({
 int? current, int? available, String? asOf
});




}
/// @nodoc
class __$LinkedAccountBalanceCopyWithImpl<$Res>
    implements _$LinkedAccountBalanceCopyWith<$Res> {
  __$LinkedAccountBalanceCopyWithImpl(this._self, this._then);

  final _LinkedAccountBalance _self;
  final $Res Function(_LinkedAccountBalance) _then;

/// Create a copy of LinkedAccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? current = freezed,Object? available = freezed,Object? asOf = freezed,}) {
  return _then(_LinkedAccountBalance(
current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int?,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int?,asOf: freezed == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
