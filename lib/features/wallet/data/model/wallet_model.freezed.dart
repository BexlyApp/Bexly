// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletModel {

/// The unique identifier for the wallet.
 int? get id;/// Cloud ID (UUID v7) for syncing with Firestore
 String? get cloudId;/// The name of the wallet (e.g., "Primary Checking", "Savings").
 String get name;/// The current balance of the wallet.
 double get balance;/// The currency code for the wallet's balance (e.g., "USD", "EUR", "NGN").
 String get currency;/// Optional: The identifier or name of the icon associated with this wallet.
 String? get iconName;/// Optional: The color associated with this wallet, stored as a hex string or int.
 String? get colorHex;// Or int colorValue
/// The type of wallet (cash, bank_account, credit_card, etc.)
 WalletType get walletType;/// Credit limit for credit cards
 double? get creditLimit;/// Billing day of month (1-31) for credit cards
 int? get billingDay;/// Annual interest rate in percentage for credit cards/loans
 double? get interestRate;/// Timestamp when wallet was created
 DateTime? get createdAt;/// Timestamp when wallet was last updated
 DateTime? get updatedAt;
/// Create a copy of WalletModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletModelCopyWith<WalletModel> get copyWith => _$WalletModelCopyWithImpl<WalletModel>(this as WalletModel, _$identity);

  /// Serializes this WalletModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.walletType, walletType) || other.walletType == walletType)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,name,balance,currency,iconName,colorHex,walletType,creditLimit,billingDay,interestRate,createdAt,updatedAt);

@override
String toString() {
  return 'WalletModel(id: $id, cloudId: $cloudId, name: $name, balance: $balance, currency: $currency, iconName: $iconName, colorHex: $colorHex, walletType: $walletType, creditLimit: $creditLimit, billingDay: $billingDay, interestRate: $interestRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WalletModelCopyWith<$Res>  {
  factory $WalletModelCopyWith(WalletModel value, $Res Function(WalletModel) _then) = _$WalletModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String name, double balance, String currency, String? iconName, String? colorHex, WalletType walletType, double? creditLimit, int? billingDay, double? interestRate, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WalletModelCopyWithImpl<$Res>
    implements $WalletModelCopyWith<$Res> {
  _$WalletModelCopyWithImpl(this._self, this._then);

  final WalletModel _self;
  final $Res Function(WalletModel) _then;

/// Create a copy of WalletModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? balance = null,Object? currency = null,Object? iconName = freezed,Object? colorHex = freezed,Object? walletType = null,Object? creditLimit = freezed,Object? billingDay = freezed,Object? interestRate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,walletType: null == walletType ? _self.walletType : walletType // ignore: cast_nullable_to_non_nullable
as WalletType,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as double?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletModel].
extension WalletModelPatterns on WalletModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletModel value)  $default,){
final _that = this;
switch (_that) {
case _WalletModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletModel value)?  $default,){
final _that = this;
switch (_that) {
case _WalletModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  double balance,  String currency,  String? iconName,  String? colorHex,  WalletType walletType,  double? creditLimit,  int? billingDay,  double? interestRate,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.balance,_that.currency,_that.iconName,_that.colorHex,_that.walletType,_that.creditLimit,_that.billingDay,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  double balance,  String currency,  String? iconName,  String? colorHex,  WalletType walletType,  double? creditLimit,  int? billingDay,  double? interestRate,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WalletModel():
return $default(_that.id,_that.cloudId,_that.name,_that.balance,_that.currency,_that.iconName,_that.colorHex,_that.walletType,_that.creditLimit,_that.billingDay,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String name,  double balance,  String currency,  String? iconName,  String? colorHex,  WalletType walletType,  double? creditLimit,  int? billingDay,  double? interestRate,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.balance,_that.currency,_that.iconName,_that.colorHex,_that.walletType,_that.creditLimit,_that.billingDay,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletModel implements WalletModel {
  const _WalletModel({this.id, this.cloudId, this.name = 'My Wallet', this.balance = 0.0, this.currency = 'IDR', this.iconName, this.colorHex, this.walletType = WalletType.cash, this.creditLimit, this.billingDay, this.interestRate, this.createdAt, this.updatedAt});
  factory _WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);

/// The unique identifier for the wallet.
@override final  int? id;
/// Cloud ID (UUID v7) for syncing with Firestore
@override final  String? cloudId;
/// The name of the wallet (e.g., "Primary Checking", "Savings").
@override@JsonKey() final  String name;
/// The current balance of the wallet.
@override@JsonKey() final  double balance;
/// The currency code for the wallet's balance (e.g., "USD", "EUR", "NGN").
@override@JsonKey() final  String currency;
/// Optional: The identifier or name of the icon associated with this wallet.
@override final  String? iconName;
/// Optional: The color associated with this wallet, stored as a hex string or int.
@override final  String? colorHex;
// Or int colorValue
/// The type of wallet (cash, bank_account, credit_card, etc.)
@override@JsonKey() final  WalletType walletType;
/// Credit limit for credit cards
@override final  double? creditLimit;
/// Billing day of month (1-31) for credit cards
@override final  int? billingDay;
/// Annual interest rate in percentage for credit cards/loans
@override final  double? interestRate;
/// Timestamp when wallet was created
@override final  DateTime? createdAt;
/// Timestamp when wallet was last updated
@override final  DateTime? updatedAt;

/// Create a copy of WalletModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletModelCopyWith<_WalletModel> get copyWith => __$WalletModelCopyWithImpl<_WalletModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.walletType, walletType) || other.walletType == walletType)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cloudId,name,balance,currency,iconName,colorHex,walletType,creditLimit,billingDay,interestRate,createdAt,updatedAt);

@override
String toString() {
  return 'WalletModel(id: $id, cloudId: $cloudId, name: $name, balance: $balance, currency: $currency, iconName: $iconName, colorHex: $colorHex, walletType: $walletType, creditLimit: $creditLimit, billingDay: $billingDay, interestRate: $interestRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WalletModelCopyWith<$Res> implements $WalletModelCopyWith<$Res> {
  factory _$WalletModelCopyWith(_WalletModel value, $Res Function(_WalletModel) _then) = __$WalletModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String name, double balance, String currency, String? iconName, String? colorHex, WalletType walletType, double? creditLimit, int? billingDay, double? interestRate, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WalletModelCopyWithImpl<$Res>
    implements _$WalletModelCopyWith<$Res> {
  __$WalletModelCopyWithImpl(this._self, this._then);

  final _WalletModel _self;
  final $Res Function(_WalletModel) _then;

/// Create a copy of WalletModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? balance = null,Object? currency = null,Object? iconName = freezed,Object? colorHex = freezed,Object? walletType = null,Object? creditLimit = freezed,Object? billingDay = freezed,Object? interestRate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WalletModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,walletType: null == walletType ? _self.walletType : walletType // ignore: cast_nullable_to_non_nullable
as WalletType,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as double?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
