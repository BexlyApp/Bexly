// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Currency {

 String get symbol; String get name;@JsonKey(name: 'decimal_digits') int get decimalDigits; double get rounding;@JsonKey(name: 'iso_code') String get isoCode;@JsonKey(name: 'name_plural') String get namePlural; String get country;@JsonKey(name: 'country_code') String get countryCode;
/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyCopyWith<Currency> get copyWith => _$CurrencyCopyWithImpl<Currency>(this as Currency, _$identity);

  /// Serializes this Currency to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Currency&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.decimalDigits, decimalDigits) || other.decimalDigits == decimalDigits)&&(identical(other.rounding, rounding) || other.rounding == rounding)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.namePlural, namePlural) || other.namePlural == namePlural)&&(identical(other.country, country) || other.country == country)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,decimalDigits,rounding,isoCode,namePlural,country,countryCode);

@override
String toString() {
  return 'Currency(symbol: $symbol, name: $name, decimalDigits: $decimalDigits, rounding: $rounding, isoCode: $isoCode, namePlural: $namePlural, country: $country, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class $CurrencyCopyWith<$Res>  {
  factory $CurrencyCopyWith(Currency value, $Res Function(Currency) _then) = _$CurrencyCopyWithImpl;
@useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'decimal_digits') int decimalDigits, double rounding,@JsonKey(name: 'iso_code') String isoCode,@JsonKey(name: 'name_plural') String namePlural, String country,@JsonKey(name: 'country_code') String countryCode
});




}
/// @nodoc
class _$CurrencyCopyWithImpl<$Res>
    implements $CurrencyCopyWith<$Res> {
  _$CurrencyCopyWithImpl(this._self, this._then);

  final Currency _self;
  final $Res Function(Currency) _then;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? decimalDigits = null,Object? rounding = null,Object? isoCode = null,Object? namePlural = null,Object? country = null,Object? countryCode = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,decimalDigits: null == decimalDigits ? _self.decimalDigits : decimalDigits // ignore: cast_nullable_to_non_nullable
as int,rounding: null == rounding ? _self.rounding : rounding // ignore: cast_nullable_to_non_nullable
as double,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,namePlural: null == namePlural ? _self.namePlural : namePlural // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Currency].
extension CurrencyPatterns on Currency {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Currency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Currency() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Currency value)  $default,){
final _that = this;
switch (_that) {
case _Currency():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Currency value)?  $default,){
final _that = this;
switch (_that) {
case _Currency() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'decimal_digits')  int decimalDigits,  double rounding, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'name_plural')  String namePlural,  String country, @JsonKey(name: 'country_code')  String countryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that.symbol,_that.name,_that.decimalDigits,_that.rounding,_that.isoCode,_that.namePlural,_that.country,_that.countryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'decimal_digits')  int decimalDigits,  double rounding, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'name_plural')  String namePlural,  String country, @JsonKey(name: 'country_code')  String countryCode)  $default,) {final _that = this;
switch (_that) {
case _Currency():
return $default(_that.symbol,_that.name,_that.decimalDigits,_that.rounding,_that.isoCode,_that.namePlural,_that.country,_that.countryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name, @JsonKey(name: 'decimal_digits')  int decimalDigits,  double rounding, @JsonKey(name: 'iso_code')  String isoCode, @JsonKey(name: 'name_plural')  String namePlural,  String country, @JsonKey(name: 'country_code')  String countryCode)?  $default,) {final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that.symbol,_that.name,_that.decimalDigits,_that.rounding,_that.isoCode,_that.namePlural,_that.country,_that.countryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Currency implements Currency {
  const _Currency({required this.symbol, required this.name, @JsonKey(name: 'decimal_digits') required this.decimalDigits, required this.rounding, @JsonKey(name: 'iso_code') required this.isoCode, @JsonKey(name: 'name_plural') required this.namePlural, required this.country, @JsonKey(name: 'country_code') required this.countryCode});
  factory _Currency.fromJson(Map<String, dynamic> json) => _$CurrencyFromJson(json);

@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'decimal_digits') final  int decimalDigits;
@override final  double rounding;
@override@JsonKey(name: 'iso_code') final  String isoCode;
@override@JsonKey(name: 'name_plural') final  String namePlural;
@override final  String country;
@override@JsonKey(name: 'country_code') final  String countryCode;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencyCopyWith<_Currency> get copyWith => __$CurrencyCopyWithImpl<_Currency>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurrencyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Currency&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.decimalDigits, decimalDigits) || other.decimalDigits == decimalDigits)&&(identical(other.rounding, rounding) || other.rounding == rounding)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.namePlural, namePlural) || other.namePlural == namePlural)&&(identical(other.country, country) || other.country == country)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,decimalDigits,rounding,isoCode,namePlural,country,countryCode);

@override
String toString() {
  return 'Currency(symbol: $symbol, name: $name, decimalDigits: $decimalDigits, rounding: $rounding, isoCode: $isoCode, namePlural: $namePlural, country: $country, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class _$CurrencyCopyWith<$Res> implements $CurrencyCopyWith<$Res> {
  factory _$CurrencyCopyWith(_Currency value, $Res Function(_Currency) _then) = __$CurrencyCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'decimal_digits') int decimalDigits, double rounding,@JsonKey(name: 'iso_code') String isoCode,@JsonKey(name: 'name_plural') String namePlural, String country,@JsonKey(name: 'country_code') String countryCode
});




}
/// @nodoc
class __$CurrencyCopyWithImpl<$Res>
    implements _$CurrencyCopyWith<$Res> {
  __$CurrencyCopyWithImpl(this._self, this._then);

  final _Currency _self;
  final $Res Function(_Currency) _then;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? decimalDigits = null,Object? rounding = null,Object? isoCode = null,Object? namePlural = null,Object? country = null,Object? countryCode = null,}) {
  return _then(_Currency(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,decimalDigits: null == decimalDigits ? _self.decimalDigits : decimalDigits // ignore: cast_nullable_to_non_nullable
as int,rounding: null == rounding ? _self.rounding : rounding // ignore: cast_nullable_to_non_nullable
as double,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,namePlural: null == namePlural ? _self.namePlural : namePlural // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
