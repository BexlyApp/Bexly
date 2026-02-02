// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingTransactionModel {

 int? get id; String? get cloudId; PendingTxSource get source; String get sourceId; double get amount; String get currency; String get transactionType;// 'income' or 'expense'
 String get title; String? get merchant; DateTime get transactionDate; double get confidence; String? get categoryHint; String get sourceDisplayName; String? get sourceIconUrl; String? get accountIdentifier; PendingTxStatus get status; int? get importedTransactionId; int? get targetWalletId; int? get selectedCategoryId; String? get userNotes; String? get rawSourceData; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PendingTransactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingTransactionModelCopyWith<PendingTransactionModel> get copyWith => _$PendingTransactionModelCopyWithImpl<PendingTransactionModel>(this as PendingTransactionModel, _$identity);

  /// Serializes this PendingTransactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.title, title) || other.title == title)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.categoryHint, categoryHint) || other.categoryHint == categoryHint)&&(identical(other.sourceDisplayName, sourceDisplayName) || other.sourceDisplayName == sourceDisplayName)&&(identical(other.sourceIconUrl, sourceIconUrl) || other.sourceIconUrl == sourceIconUrl)&&(identical(other.accountIdentifier, accountIdentifier) || other.accountIdentifier == accountIdentifier)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedTransactionId, importedTransactionId) || other.importedTransactionId == importedTransactionId)&&(identical(other.targetWalletId, targetWalletId) || other.targetWalletId == targetWalletId)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.userNotes, userNotes) || other.userNotes == userNotes)&&(identical(other.rawSourceData, rawSourceData) || other.rawSourceData == rawSourceData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,source,sourceId,amount,currency,transactionType,title,merchant,transactionDate,confidence,categoryHint,sourceDisplayName,sourceIconUrl,accountIdentifier,status,importedTransactionId,targetWalletId,selectedCategoryId,userNotes,rawSourceData,createdAt,updatedAt]);

@override
String toString() {
  return 'PendingTransactionModel(id: $id, cloudId: $cloudId, source: $source, sourceId: $sourceId, amount: $amount, currency: $currency, transactionType: $transactionType, title: $title, merchant: $merchant, transactionDate: $transactionDate, confidence: $confidence, categoryHint: $categoryHint, sourceDisplayName: $sourceDisplayName, sourceIconUrl: $sourceIconUrl, accountIdentifier: $accountIdentifier, status: $status, importedTransactionId: $importedTransactionId, targetWalletId: $targetWalletId, selectedCategoryId: $selectedCategoryId, userNotes: $userNotes, rawSourceData: $rawSourceData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PendingTransactionModelCopyWith<$Res>  {
  factory $PendingTransactionModelCopyWith(PendingTransactionModel value, $Res Function(PendingTransactionModel) _then) = _$PendingTransactionModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, PendingTxSource source, String sourceId, double amount, String currency, String transactionType, String title, String? merchant, DateTime transactionDate, double confidence, String? categoryHint, String sourceDisplayName, String? sourceIconUrl, String? accountIdentifier, PendingTxStatus status, int? importedTransactionId, int? targetWalletId, int? selectedCategoryId, String? userNotes, String? rawSourceData, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PendingTransactionModelCopyWithImpl<$Res>
    implements $PendingTransactionModelCopyWith<$Res> {
  _$PendingTransactionModelCopyWithImpl(this._self, this._then);

  final PendingTransactionModel _self;
  final $Res Function(PendingTransactionModel) _then;

/// Create a copy of PendingTransactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? source = null,Object? sourceId = null,Object? amount = null,Object? currency = null,Object? transactionType = null,Object? title = null,Object? merchant = freezed,Object? transactionDate = null,Object? confidence = null,Object? categoryHint = freezed,Object? sourceDisplayName = null,Object? sourceIconUrl = freezed,Object? accountIdentifier = freezed,Object? status = null,Object? importedTransactionId = freezed,Object? targetWalletId = freezed,Object? selectedCategoryId = freezed,Object? userNotes = freezed,Object? rawSourceData = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PendingTxSource,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,categoryHint: freezed == categoryHint ? _self.categoryHint : categoryHint // ignore: cast_nullable_to_non_nullable
as String?,sourceDisplayName: null == sourceDisplayName ? _self.sourceDisplayName : sourceDisplayName // ignore: cast_nullable_to_non_nullable
as String,sourceIconUrl: freezed == sourceIconUrl ? _self.sourceIconUrl : sourceIconUrl // ignore: cast_nullable_to_non_nullable
as String?,accountIdentifier: freezed == accountIdentifier ? _self.accountIdentifier : accountIdentifier // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PendingTxStatus,importedTransactionId: freezed == importedTransactionId ? _self.importedTransactionId : importedTransactionId // ignore: cast_nullable_to_non_nullable
as int?,targetWalletId: freezed == targetWalletId ? _self.targetWalletId : targetWalletId // ignore: cast_nullable_to_non_nullable
as int?,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,userNotes: freezed == userNotes ? _self.userNotes : userNotes // ignore: cast_nullable_to_non_nullable
as String?,rawSourceData: freezed == rawSourceData ? _self.rawSourceData : rawSourceData // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingTransactionModel].
extension PendingTransactionModelPatterns on PendingTransactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingTransactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingTransactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingTransactionModel value)  $default,){
final _that = this;
switch (_that) {
case _PendingTransactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingTransactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _PendingTransactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  PendingTxSource source,  String sourceId,  double amount,  String currency,  String transactionType,  String title,  String? merchant,  DateTime transactionDate,  double confidence,  String? categoryHint,  String sourceDisplayName,  String? sourceIconUrl,  String? accountIdentifier,  PendingTxStatus status,  int? importedTransactionId,  int? targetWalletId,  int? selectedCategoryId,  String? userNotes,  String? rawSourceData,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingTransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.source,_that.sourceId,_that.amount,_that.currency,_that.transactionType,_that.title,_that.merchant,_that.transactionDate,_that.confidence,_that.categoryHint,_that.sourceDisplayName,_that.sourceIconUrl,_that.accountIdentifier,_that.status,_that.importedTransactionId,_that.targetWalletId,_that.selectedCategoryId,_that.userNotes,_that.rawSourceData,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  PendingTxSource source,  String sourceId,  double amount,  String currency,  String transactionType,  String title,  String? merchant,  DateTime transactionDate,  double confidence,  String? categoryHint,  String sourceDisplayName,  String? sourceIconUrl,  String? accountIdentifier,  PendingTxStatus status,  int? importedTransactionId,  int? targetWalletId,  int? selectedCategoryId,  String? userNotes,  String? rawSourceData,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PendingTransactionModel():
return $default(_that.id,_that.cloudId,_that.source,_that.sourceId,_that.amount,_that.currency,_that.transactionType,_that.title,_that.merchant,_that.transactionDate,_that.confidence,_that.categoryHint,_that.sourceDisplayName,_that.sourceIconUrl,_that.accountIdentifier,_that.status,_that.importedTransactionId,_that.targetWalletId,_that.selectedCategoryId,_that.userNotes,_that.rawSourceData,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  PendingTxSource source,  String sourceId,  double amount,  String currency,  String transactionType,  String title,  String? merchant,  DateTime transactionDate,  double confidence,  String? categoryHint,  String sourceDisplayName,  String? sourceIconUrl,  String? accountIdentifier,  PendingTxStatus status,  int? importedTransactionId,  int? targetWalletId,  int? selectedCategoryId,  String? userNotes,  String? rawSourceData,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingTransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.source,_that.sourceId,_that.amount,_that.currency,_that.transactionType,_that.title,_that.merchant,_that.transactionDate,_that.confidence,_that.categoryHint,_that.sourceDisplayName,_that.sourceIconUrl,_that.accountIdentifier,_that.status,_that.importedTransactionId,_that.targetWalletId,_that.selectedCategoryId,_that.userNotes,_that.rawSourceData,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingTransactionModel extends PendingTransactionModel {
  const _PendingTransactionModel({this.id, this.cloudId, required this.source, required this.sourceId, required this.amount, this.currency = 'VND', required this.transactionType, required this.title, this.merchant, required this.transactionDate, this.confidence = 0.8, this.categoryHint, required this.sourceDisplayName, this.sourceIconUrl, this.accountIdentifier, this.status = PendingTxStatus.pendingReview, this.importedTransactionId, this.targetWalletId, this.selectedCategoryId, this.userNotes, this.rawSourceData, this.createdAt, this.updatedAt}): super._();
  factory _PendingTransactionModel.fromJson(Map<String, dynamic> json) => _$PendingTransactionModelFromJson(json);

@override final  int? id;
@override final  String? cloudId;
@override final  PendingTxSource source;
@override final  String sourceId;
@override final  double amount;
@override@JsonKey() final  String currency;
@override final  String transactionType;
// 'income' or 'expense'
@override final  String title;
@override final  String? merchant;
@override final  DateTime transactionDate;
@override@JsonKey() final  double confidence;
@override final  String? categoryHint;
@override final  String sourceDisplayName;
@override final  String? sourceIconUrl;
@override final  String? accountIdentifier;
@override@JsonKey() final  PendingTxStatus status;
@override final  int? importedTransactionId;
@override final  int? targetWalletId;
@override final  int? selectedCategoryId;
@override final  String? userNotes;
@override final  String? rawSourceData;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PendingTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingTransactionModelCopyWith<_PendingTransactionModel> get copyWith => __$PendingTransactionModelCopyWithImpl<_PendingTransactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingTransactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.title, title) || other.title == title)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.categoryHint, categoryHint) || other.categoryHint == categoryHint)&&(identical(other.sourceDisplayName, sourceDisplayName) || other.sourceDisplayName == sourceDisplayName)&&(identical(other.sourceIconUrl, sourceIconUrl) || other.sourceIconUrl == sourceIconUrl)&&(identical(other.accountIdentifier, accountIdentifier) || other.accountIdentifier == accountIdentifier)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedTransactionId, importedTransactionId) || other.importedTransactionId == importedTransactionId)&&(identical(other.targetWalletId, targetWalletId) || other.targetWalletId == targetWalletId)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.userNotes, userNotes) || other.userNotes == userNotes)&&(identical(other.rawSourceData, rawSourceData) || other.rawSourceData == rawSourceData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,source,sourceId,amount,currency,transactionType,title,merchant,transactionDate,confidence,categoryHint,sourceDisplayName,sourceIconUrl,accountIdentifier,status,importedTransactionId,targetWalletId,selectedCategoryId,userNotes,rawSourceData,createdAt,updatedAt]);

@override
String toString() {
  return 'PendingTransactionModel(id: $id, cloudId: $cloudId, source: $source, sourceId: $sourceId, amount: $amount, currency: $currency, transactionType: $transactionType, title: $title, merchant: $merchant, transactionDate: $transactionDate, confidence: $confidence, categoryHint: $categoryHint, sourceDisplayName: $sourceDisplayName, sourceIconUrl: $sourceIconUrl, accountIdentifier: $accountIdentifier, status: $status, importedTransactionId: $importedTransactionId, targetWalletId: $targetWalletId, selectedCategoryId: $selectedCategoryId, userNotes: $userNotes, rawSourceData: $rawSourceData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PendingTransactionModelCopyWith<$Res> implements $PendingTransactionModelCopyWith<$Res> {
  factory _$PendingTransactionModelCopyWith(_PendingTransactionModel value, $Res Function(_PendingTransactionModel) _then) = __$PendingTransactionModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, PendingTxSource source, String sourceId, double amount, String currency, String transactionType, String title, String? merchant, DateTime transactionDate, double confidence, String? categoryHint, String sourceDisplayName, String? sourceIconUrl, String? accountIdentifier, PendingTxStatus status, int? importedTransactionId, int? targetWalletId, int? selectedCategoryId, String? userNotes, String? rawSourceData, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PendingTransactionModelCopyWithImpl<$Res>
    implements _$PendingTransactionModelCopyWith<$Res> {
  __$PendingTransactionModelCopyWithImpl(this._self, this._then);

  final _PendingTransactionModel _self;
  final $Res Function(_PendingTransactionModel) _then;

/// Create a copy of PendingTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? source = null,Object? sourceId = null,Object? amount = null,Object? currency = null,Object? transactionType = null,Object? title = null,Object? merchant = freezed,Object? transactionDate = null,Object? confidence = null,Object? categoryHint = freezed,Object? sourceDisplayName = null,Object? sourceIconUrl = freezed,Object? accountIdentifier = freezed,Object? status = null,Object? importedTransactionId = freezed,Object? targetWalletId = freezed,Object? selectedCategoryId = freezed,Object? userNotes = freezed,Object? rawSourceData = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PendingTransactionModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PendingTxSource,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,categoryHint: freezed == categoryHint ? _self.categoryHint : categoryHint // ignore: cast_nullable_to_non_nullable
as String?,sourceDisplayName: null == sourceDisplayName ? _self.sourceDisplayName : sourceDisplayName // ignore: cast_nullable_to_non_nullable
as String,sourceIconUrl: freezed == sourceIconUrl ? _self.sourceIconUrl : sourceIconUrl // ignore: cast_nullable_to_non_nullable
as String?,accountIdentifier: freezed == accountIdentifier ? _self.accountIdentifier : accountIdentifier // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PendingTxStatus,importedTransactionId: freezed == importedTransactionId ? _self.importedTransactionId : importedTransactionId // ignore: cast_nullable_to_non_nullable
as int?,targetWalletId: freezed == targetWalletId ? _self.targetWalletId : targetWalletId // ignore: cast_nullable_to_non_nullable
as int?,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,userNotes: freezed == userNotes ? _self.userNotes : userNotes // ignore: cast_nullable_to_non_nullable
as String?,rawSourceData: freezed == rawSourceData ? _self.rawSourceData : rawSourceData // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
