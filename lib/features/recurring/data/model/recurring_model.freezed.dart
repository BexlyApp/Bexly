// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringModel {

/// Unique identifier (null for new recurrings)
 int? get id;/// Cloud sync ID
 String? get cloudId;/// Recurring payment name/title
 String get name;/// Optional description
 String? get description;/// Wallet used for this recurring payment
 WalletModel get wallet;/// Category for expense tracking
 CategoryModel get category;/// Amount charged per billing cycle
 double get amount;/// Currency code (ISO 4217)
 String get currency;/// Start date of recurring payment
 DateTime get startDate;/// Next payment due date
 DateTime get nextDueDate;/// Billing frequency
 RecurringFrequency get frequency;/// Custom interval (for custom frequency)
 int? get customInterval;/// Custom interval unit (for custom frequency)
 String? get customUnit;/// Billing day (day of month or day of week)
 int? get billingDay;/// End date (null = no end date)
 DateTime? get endDate;/// Current status
 RecurringStatus get status;/// Auto-create transactions when due
 bool get autoCreate;/// Enable payment reminders
 bool get enableReminder;/// Days before due date to remind
 int get reminderDaysBefore;/// Additional notes
 String? get notes;/// Vendor/service name
 String? get vendorName;/// Icon for display
 String? get iconName;/// Color for visual identification
 String? get colorHex;/// Last payment date
 DateTime? get lastChargedDate;/// Total number of payments made
 int get totalPayments;/// Creation timestamp
 DateTime? get createdAt;/// Last update timestamp
 DateTime? get updatedAt;
/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringModelCopyWith<RecurringModel> get copyWith => _$RecurringModelCopyWithImpl<RecurringModel>(this as RecurringModel, _$identity);

  /// Serializes this RecurringModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.customInterval, customInterval) || other.customInterval == customInterval)&&(identical(other.customUnit, customUnit) || other.customUnit == customUnit)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.autoCreate, autoCreate) || other.autoCreate == autoCreate)&&(identical(other.enableReminder, enableReminder) || other.enableReminder == enableReminder)&&(identical(other.reminderDaysBefore, reminderDaysBefore) || other.reminderDaysBefore == reminderDaysBefore)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vendorName, vendorName) || other.vendorName == vendorName)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.lastChargedDate, lastChargedDate) || other.lastChargedDate == lastChargedDate)&&(identical(other.totalPayments, totalPayments) || other.totalPayments == totalPayments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,name,description,wallet,category,amount,currency,startDate,nextDueDate,frequency,customInterval,customUnit,billingDay,endDate,status,autoCreate,enableReminder,reminderDaysBefore,notes,vendorName,iconName,colorHex,lastChargedDate,totalPayments,createdAt,updatedAt]);

@override
String toString() {
  return 'RecurringModel(id: $id, cloudId: $cloudId, name: $name, description: $description, wallet: $wallet, category: $category, amount: $amount, currency: $currency, startDate: $startDate, nextDueDate: $nextDueDate, frequency: $frequency, customInterval: $customInterval, customUnit: $customUnit, billingDay: $billingDay, endDate: $endDate, status: $status, autoCreate: $autoCreate, enableReminder: $enableReminder, reminderDaysBefore: $reminderDaysBefore, notes: $notes, vendorName: $vendorName, iconName: $iconName, colorHex: $colorHex, lastChargedDate: $lastChargedDate, totalPayments: $totalPayments, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RecurringModelCopyWith<$Res>  {
  factory $RecurringModelCopyWith(RecurringModel value, $Res Function(RecurringModel) _then) = _$RecurringModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String name, String? description, WalletModel wallet, CategoryModel category, double amount, String currency, DateTime startDate, DateTime nextDueDate, RecurringFrequency frequency, int? customInterval, String? customUnit, int? billingDay, DateTime? endDate, RecurringStatus status, bool autoCreate, bool enableReminder, int reminderDaysBefore, String? notes, String? vendorName, String? iconName, String? colorHex, DateTime? lastChargedDate, int totalPayments, DateTime? createdAt, DateTime? updatedAt
});


$WalletModelCopyWith<$Res> get wallet;$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$RecurringModelCopyWithImpl<$Res>
    implements $RecurringModelCopyWith<$Res> {
  _$RecurringModelCopyWithImpl(this._self, this._then);

  final RecurringModel _self;
  final $Res Function(RecurringModel) _then;

/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? description = freezed,Object? wallet = null,Object? category = null,Object? amount = null,Object? currency = null,Object? startDate = null,Object? nextDueDate = null,Object? frequency = null,Object? customInterval = freezed,Object? customUnit = freezed,Object? billingDay = freezed,Object? endDate = freezed,Object? status = null,Object? autoCreate = null,Object? enableReminder = null,Object? reminderDaysBefore = null,Object? notes = freezed,Object? vendorName = freezed,Object? iconName = freezed,Object? colorHex = freezed,Object? lastChargedDate = freezed,Object? totalPayments = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletModel,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurringFrequency,customInterval: freezed == customInterval ? _self.customInterval : customInterval // ignore: cast_nullable_to_non_nullable
as int?,customUnit: freezed == customUnit ? _self.customUnit : customUnit // ignore: cast_nullable_to_non_nullable
as String?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringStatus,autoCreate: null == autoCreate ? _self.autoCreate : autoCreate // ignore: cast_nullable_to_non_nullable
as bool,enableReminder: null == enableReminder ? _self.enableReminder : enableReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDaysBefore: null == reminderDaysBefore ? _self.reminderDaysBefore : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vendorName: freezed == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,lastChargedDate: freezed == lastChargedDate ? _self.lastChargedDate : lastChargedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalPayments: null == totalPayments ? _self.totalPayments : totalPayments // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletModelCopyWith<$Res> get wallet {
  
  return $WalletModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecurringModel].
extension RecurringModelPatterns on RecurringModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringModel value)  $default,){
final _that = this;
switch (_that) {
case _RecurringModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  String? description,  WalletModel wallet,  CategoryModel category,  double amount,  String currency,  DateTime startDate,  DateTime nextDueDate,  RecurringFrequency frequency,  int? customInterval,  String? customUnit,  int? billingDay,  DateTime? endDate,  RecurringStatus status,  bool autoCreate,  bool enableReminder,  int reminderDaysBefore,  String? notes,  String? vendorName,  String? iconName,  String? colorHex,  DateTime? lastChargedDate,  int totalPayments,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.description,_that.wallet,_that.category,_that.amount,_that.currency,_that.startDate,_that.nextDueDate,_that.frequency,_that.customInterval,_that.customUnit,_that.billingDay,_that.endDate,_that.status,_that.autoCreate,_that.enableReminder,_that.reminderDaysBefore,_that.notes,_that.vendorName,_that.iconName,_that.colorHex,_that.lastChargedDate,_that.totalPayments,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String name,  String? description,  WalletModel wallet,  CategoryModel category,  double amount,  String currency,  DateTime startDate,  DateTime nextDueDate,  RecurringFrequency frequency,  int? customInterval,  String? customUnit,  int? billingDay,  DateTime? endDate,  RecurringStatus status,  bool autoCreate,  bool enableReminder,  int reminderDaysBefore,  String? notes,  String? vendorName,  String? iconName,  String? colorHex,  DateTime? lastChargedDate,  int totalPayments,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringModel():
return $default(_that.id,_that.cloudId,_that.name,_that.description,_that.wallet,_that.category,_that.amount,_that.currency,_that.startDate,_that.nextDueDate,_that.frequency,_that.customInterval,_that.customUnit,_that.billingDay,_that.endDate,_that.status,_that.autoCreate,_that.enableReminder,_that.reminderDaysBefore,_that.notes,_that.vendorName,_that.iconName,_that.colorHex,_that.lastChargedDate,_that.totalPayments,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String name,  String? description,  WalletModel wallet,  CategoryModel category,  double amount,  String currency,  DateTime startDate,  DateTime nextDueDate,  RecurringFrequency frequency,  int? customInterval,  String? customUnit,  int? billingDay,  DateTime? endDate,  RecurringStatus status,  bool autoCreate,  bool enableReminder,  int reminderDaysBefore,  String? notes,  String? vendorName,  String? iconName,  String? colorHex,  DateTime? lastChargedDate,  int totalPayments,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.name,_that.description,_that.wallet,_that.category,_that.amount,_that.currency,_that.startDate,_that.nextDueDate,_that.frequency,_that.customInterval,_that.customUnit,_that.billingDay,_that.endDate,_that.status,_that.autoCreate,_that.enableReminder,_that.reminderDaysBefore,_that.notes,_that.vendorName,_that.iconName,_that.colorHex,_that.lastChargedDate,_that.totalPayments,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringModel implements RecurringModel {
  const _RecurringModel({this.id, this.cloudId, required this.name, this.description, required this.wallet, required this.category, required this.amount, required this.currency, required this.startDate, required this.nextDueDate, required this.frequency, this.customInterval, this.customUnit, this.billingDay, this.endDate, required this.status, this.autoCreate = false, this.enableReminder = true, this.reminderDaysBefore = 3, this.notes, this.vendorName, this.iconName, this.colorHex, this.lastChargedDate, this.totalPayments = 0, this.createdAt, this.updatedAt});
  factory _RecurringModel.fromJson(Map<String, dynamic> json) => _$RecurringModelFromJson(json);

/// Unique identifier (null for new recurrings)
@override final  int? id;
/// Cloud sync ID
@override final  String? cloudId;
/// Recurring payment name/title
@override final  String name;
/// Optional description
@override final  String? description;
/// Wallet used for this recurring payment
@override final  WalletModel wallet;
/// Category for expense tracking
@override final  CategoryModel category;
/// Amount charged per billing cycle
@override final  double amount;
/// Currency code (ISO 4217)
@override final  String currency;
/// Start date of recurring payment
@override final  DateTime startDate;
/// Next payment due date
@override final  DateTime nextDueDate;
/// Billing frequency
@override final  RecurringFrequency frequency;
/// Custom interval (for custom frequency)
@override final  int? customInterval;
/// Custom interval unit (for custom frequency)
@override final  String? customUnit;
/// Billing day (day of month or day of week)
@override final  int? billingDay;
/// End date (null = no end date)
@override final  DateTime? endDate;
/// Current status
@override final  RecurringStatus status;
/// Auto-create transactions when due
@override@JsonKey() final  bool autoCreate;
/// Enable payment reminders
@override@JsonKey() final  bool enableReminder;
/// Days before due date to remind
@override@JsonKey() final  int reminderDaysBefore;
/// Additional notes
@override final  String? notes;
/// Vendor/service name
@override final  String? vendorName;
/// Icon for display
@override final  String? iconName;
/// Color for visual identification
@override final  String? colorHex;
/// Last payment date
@override final  DateTime? lastChargedDate;
/// Total number of payments made
@override@JsonKey() final  int totalPayments;
/// Creation timestamp
@override final  DateTime? createdAt;
/// Last update timestamp
@override final  DateTime? updatedAt;

/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringModelCopyWith<_RecurringModel> get copyWith => __$RecurringModelCopyWithImpl<_RecurringModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.customInterval, customInterval) || other.customInterval == customInterval)&&(identical(other.customUnit, customUnit) || other.customUnit == customUnit)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.autoCreate, autoCreate) || other.autoCreate == autoCreate)&&(identical(other.enableReminder, enableReminder) || other.enableReminder == enableReminder)&&(identical(other.reminderDaysBefore, reminderDaysBefore) || other.reminderDaysBefore == reminderDaysBefore)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vendorName, vendorName) || other.vendorName == vendorName)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.lastChargedDate, lastChargedDate) || other.lastChargedDate == lastChargedDate)&&(identical(other.totalPayments, totalPayments) || other.totalPayments == totalPayments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,name,description,wallet,category,amount,currency,startDate,nextDueDate,frequency,customInterval,customUnit,billingDay,endDate,status,autoCreate,enableReminder,reminderDaysBefore,notes,vendorName,iconName,colorHex,lastChargedDate,totalPayments,createdAt,updatedAt]);

@override
String toString() {
  return 'RecurringModel(id: $id, cloudId: $cloudId, name: $name, description: $description, wallet: $wallet, category: $category, amount: $amount, currency: $currency, startDate: $startDate, nextDueDate: $nextDueDate, frequency: $frequency, customInterval: $customInterval, customUnit: $customUnit, billingDay: $billingDay, endDate: $endDate, status: $status, autoCreate: $autoCreate, enableReminder: $enableReminder, reminderDaysBefore: $reminderDaysBefore, notes: $notes, vendorName: $vendorName, iconName: $iconName, colorHex: $colorHex, lastChargedDate: $lastChargedDate, totalPayments: $totalPayments, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringModelCopyWith<$Res> implements $RecurringModelCopyWith<$Res> {
  factory _$RecurringModelCopyWith(_RecurringModel value, $Res Function(_RecurringModel) _then) = __$RecurringModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String name, String? description, WalletModel wallet, CategoryModel category, double amount, String currency, DateTime startDate, DateTime nextDueDate, RecurringFrequency frequency, int? customInterval, String? customUnit, int? billingDay, DateTime? endDate, RecurringStatus status, bool autoCreate, bool enableReminder, int reminderDaysBefore, String? notes, String? vendorName, String? iconName, String? colorHex, DateTime? lastChargedDate, int totalPayments, DateTime? createdAt, DateTime? updatedAt
});


@override $WalletModelCopyWith<$Res> get wallet;@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$RecurringModelCopyWithImpl<$Res>
    implements _$RecurringModelCopyWith<$Res> {
  __$RecurringModelCopyWithImpl(this._self, this._then);

  final _RecurringModel _self;
  final $Res Function(_RecurringModel) _then;

/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? name = null,Object? description = freezed,Object? wallet = null,Object? category = null,Object? amount = null,Object? currency = null,Object? startDate = null,Object? nextDueDate = null,Object? frequency = null,Object? customInterval = freezed,Object? customUnit = freezed,Object? billingDay = freezed,Object? endDate = freezed,Object? status = null,Object? autoCreate = null,Object? enableReminder = null,Object? reminderDaysBefore = null,Object? notes = freezed,Object? vendorName = freezed,Object? iconName = freezed,Object? colorHex = freezed,Object? lastChargedDate = freezed,Object? totalPayments = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RecurringModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletModel,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurringFrequency,customInterval: freezed == customInterval ? _self.customInterval : customInterval // ignore: cast_nullable_to_non_nullable
as int?,customUnit: freezed == customUnit ? _self.customUnit : customUnit // ignore: cast_nullable_to_non_nullable
as String?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringStatus,autoCreate: null == autoCreate ? _self.autoCreate : autoCreate // ignore: cast_nullable_to_non_nullable
as bool,enableReminder: null == enableReminder ? _self.enableReminder : enableReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDaysBefore: null == reminderDaysBefore ? _self.reminderDaysBefore : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vendorName: freezed == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,lastChargedDate: freezed == lastChargedDate ? _self.lastChargedDate : lastChargedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalPayments: null == totalPayments ? _self.totalPayments : totalPayments // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletModelCopyWith<$Res> get wallet {
  
  return $WalletModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}/// Create a copy of RecurringModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
