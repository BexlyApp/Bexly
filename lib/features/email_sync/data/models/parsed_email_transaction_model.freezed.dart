// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_email_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParsedEmailTransactionModel {

/// Unique ID (local)
 int? get id;/// Cloud ID (for sync)
 String? get cloudId;/// Gmail message ID (for deduplication)
 String get emailId;/// Email subject
 String get emailSubject;/// Sender email address
 String get fromEmail;/// Transaction amount (always positive)
 double get amount;/// Currency code (VND, USD, etc.)
 String get currency;/// Transaction type: 'income' or 'expense'
 String get transactionType;/// Merchant or payee name
 String? get merchant;/// Last 4 digits of account number
 String? get accountLast4;/// Balance after transaction
 double? get balanceAfter;/// Date of the transaction
 DateTime get transactionDate;/// Date the email was received
 DateTime get emailDate;/// Confidence score (0-1)
 double get confidence;/// Raw amount text from email
 String get rawAmountText;/// Suggested category
 String? get categoryHint;/// Bank or e-wallet name
 String get bankName;/// Status of the parsed transaction
 ParsedTransactionStatus get status;/// ID of the imported transaction (if imported)
 String? get importedTransactionId;/// User's wallet ID to import to
 String? get targetWalletCloudId;/// User's selected category ID
 String? get selectedCategoryCloudId;/// User's notes/edits
 String? get userNotes;/// Created timestamp
 DateTime? get createdAt;/// Updated timestamp
 DateTime? get updatedAt;
/// Create a copy of ParsedEmailTransactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedEmailTransactionModelCopyWith<ParsedEmailTransactionModel> get copyWith => _$ParsedEmailTransactionModelCopyWithImpl<ParsedEmailTransactionModel>(this as ParsedEmailTransactionModel, _$identity);

  /// Serializes this ParsedEmailTransactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedEmailTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.emailId, emailId) || other.emailId == emailId)&&(identical(other.emailSubject, emailSubject) || other.emailSubject == emailSubject)&&(identical(other.fromEmail, fromEmail) || other.fromEmail == fromEmail)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.emailDate, emailDate) || other.emailDate == emailDate)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rawAmountText, rawAmountText) || other.rawAmountText == rawAmountText)&&(identical(other.categoryHint, categoryHint) || other.categoryHint == categoryHint)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedTransactionId, importedTransactionId) || other.importedTransactionId == importedTransactionId)&&(identical(other.targetWalletCloudId, targetWalletCloudId) || other.targetWalletCloudId == targetWalletCloudId)&&(identical(other.selectedCategoryCloudId, selectedCategoryCloudId) || other.selectedCategoryCloudId == selectedCategoryCloudId)&&(identical(other.userNotes, userNotes) || other.userNotes == userNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,emailId,emailSubject,fromEmail,amount,currency,transactionType,merchant,accountLast4,balanceAfter,transactionDate,emailDate,confidence,rawAmountText,categoryHint,bankName,status,importedTransactionId,targetWalletCloudId,selectedCategoryCloudId,userNotes,createdAt,updatedAt]);

@override
String toString() {
  return 'ParsedEmailTransactionModel(id: $id, cloudId: $cloudId, emailId: $emailId, emailSubject: $emailSubject, fromEmail: $fromEmail, amount: $amount, currency: $currency, transactionType: $transactionType, merchant: $merchant, accountLast4: $accountLast4, balanceAfter: $balanceAfter, transactionDate: $transactionDate, emailDate: $emailDate, confidence: $confidence, rawAmountText: $rawAmountText, categoryHint: $categoryHint, bankName: $bankName, status: $status, importedTransactionId: $importedTransactionId, targetWalletCloudId: $targetWalletCloudId, selectedCategoryCloudId: $selectedCategoryCloudId, userNotes: $userNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ParsedEmailTransactionModelCopyWith<$Res>  {
  factory $ParsedEmailTransactionModelCopyWith(ParsedEmailTransactionModel value, $Res Function(ParsedEmailTransactionModel) _then) = _$ParsedEmailTransactionModelCopyWithImpl;
@useResult
$Res call({
 int? id, String? cloudId, String emailId, String emailSubject, String fromEmail, double amount, String currency, String transactionType, String? merchant, String? accountLast4, double? balanceAfter, DateTime transactionDate, DateTime emailDate, double confidence, String rawAmountText, String? categoryHint, String bankName, ParsedTransactionStatus status, String? importedTransactionId, String? targetWalletCloudId, String? selectedCategoryCloudId, String? userNotes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ParsedEmailTransactionModelCopyWithImpl<$Res>
    implements $ParsedEmailTransactionModelCopyWith<$Res> {
  _$ParsedEmailTransactionModelCopyWithImpl(this._self, this._then);

  final ParsedEmailTransactionModel _self;
  final $Res Function(ParsedEmailTransactionModel) _then;

/// Create a copy of ParsedEmailTransactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? cloudId = freezed,Object? emailId = null,Object? emailSubject = null,Object? fromEmail = null,Object? amount = null,Object? currency = null,Object? transactionType = null,Object? merchant = freezed,Object? accountLast4 = freezed,Object? balanceAfter = freezed,Object? transactionDate = null,Object? emailDate = null,Object? confidence = null,Object? rawAmountText = null,Object? categoryHint = freezed,Object? bankName = null,Object? status = null,Object? importedTransactionId = freezed,Object? targetWalletCloudId = freezed,Object? selectedCategoryCloudId = freezed,Object? userNotes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,emailId: null == emailId ? _self.emailId : emailId // ignore: cast_nullable_to_non_nullable
as String,emailSubject: null == emailSubject ? _self.emailSubject : emailSubject // ignore: cast_nullable_to_non_nullable
as String,fromEmail: null == fromEmail ? _self.fromEmail : fromEmail // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,balanceAfter: freezed == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,emailDate: null == emailDate ? _self.emailDate : emailDate // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rawAmountText: null == rawAmountText ? _self.rawAmountText : rawAmountText // ignore: cast_nullable_to_non_nullable
as String,categoryHint: freezed == categoryHint ? _self.categoryHint : categoryHint // ignore: cast_nullable_to_non_nullable
as String?,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParsedTransactionStatus,importedTransactionId: freezed == importedTransactionId ? _self.importedTransactionId : importedTransactionId // ignore: cast_nullable_to_non_nullable
as String?,targetWalletCloudId: freezed == targetWalletCloudId ? _self.targetWalletCloudId : targetWalletCloudId // ignore: cast_nullable_to_non_nullable
as String?,selectedCategoryCloudId: freezed == selectedCategoryCloudId ? _self.selectedCategoryCloudId : selectedCategoryCloudId // ignore: cast_nullable_to_non_nullable
as String?,userNotes: freezed == userNotes ? _self.userNotes : userNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedEmailTransactionModel].
extension ParsedEmailTransactionModelPatterns on ParsedEmailTransactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedEmailTransactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedEmailTransactionModel value)  $default,){
final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedEmailTransactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String emailId,  String emailSubject,  String fromEmail,  double amount,  String currency,  String transactionType,  String? merchant,  String? accountLast4,  double? balanceAfter,  DateTime transactionDate,  DateTime emailDate,  double confidence,  String rawAmountText,  String? categoryHint,  String bankName,  ParsedTransactionStatus status,  String? importedTransactionId,  String? targetWalletCloudId,  String? selectedCategoryCloudId,  String? userNotes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.emailId,_that.emailSubject,_that.fromEmail,_that.amount,_that.currency,_that.transactionType,_that.merchant,_that.accountLast4,_that.balanceAfter,_that.transactionDate,_that.emailDate,_that.confidence,_that.rawAmountText,_that.categoryHint,_that.bankName,_that.status,_that.importedTransactionId,_that.targetWalletCloudId,_that.selectedCategoryCloudId,_that.userNotes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? cloudId,  String emailId,  String emailSubject,  String fromEmail,  double amount,  String currency,  String transactionType,  String? merchant,  String? accountLast4,  double? balanceAfter,  DateTime transactionDate,  DateTime emailDate,  double confidence,  String rawAmountText,  String? categoryHint,  String bankName,  ParsedTransactionStatus status,  String? importedTransactionId,  String? targetWalletCloudId,  String? selectedCategoryCloudId,  String? userNotes,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel():
return $default(_that.id,_that.cloudId,_that.emailId,_that.emailSubject,_that.fromEmail,_that.amount,_that.currency,_that.transactionType,_that.merchant,_that.accountLast4,_that.balanceAfter,_that.transactionDate,_that.emailDate,_that.confidence,_that.rawAmountText,_that.categoryHint,_that.bankName,_that.status,_that.importedTransactionId,_that.targetWalletCloudId,_that.selectedCategoryCloudId,_that.userNotes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? cloudId,  String emailId,  String emailSubject,  String fromEmail,  double amount,  String currency,  String transactionType,  String? merchant,  String? accountLast4,  double? balanceAfter,  DateTime transactionDate,  DateTime emailDate,  double confidence,  String rawAmountText,  String? categoryHint,  String bankName,  ParsedTransactionStatus status,  String? importedTransactionId,  String? targetWalletCloudId,  String? selectedCategoryCloudId,  String? userNotes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ParsedEmailTransactionModel() when $default != null:
return $default(_that.id,_that.cloudId,_that.emailId,_that.emailSubject,_that.fromEmail,_that.amount,_that.currency,_that.transactionType,_that.merchant,_that.accountLast4,_that.balanceAfter,_that.transactionDate,_that.emailDate,_that.confidence,_that.rawAmountText,_that.categoryHint,_that.bankName,_that.status,_that.importedTransactionId,_that.targetWalletCloudId,_that.selectedCategoryCloudId,_that.userNotes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedEmailTransactionModel implements ParsedEmailTransactionModel {
  const _ParsedEmailTransactionModel({this.id, this.cloudId, required this.emailId, required this.emailSubject, required this.fromEmail, required this.amount, this.currency = 'VND', required this.transactionType, this.merchant, this.accountLast4, this.balanceAfter, required this.transactionDate, required this.emailDate, this.confidence = 0.8, required this.rawAmountText, this.categoryHint, required this.bankName, this.status = ParsedTransactionStatus.pendingReview, this.importedTransactionId, this.targetWalletCloudId, this.selectedCategoryCloudId, this.userNotes, this.createdAt, this.updatedAt});
  factory _ParsedEmailTransactionModel.fromJson(Map<String, dynamic> json) => _$ParsedEmailTransactionModelFromJson(json);

/// Unique ID (local)
@override final  int? id;
/// Cloud ID (for sync)
@override final  String? cloudId;
/// Gmail message ID (for deduplication)
@override final  String emailId;
/// Email subject
@override final  String emailSubject;
/// Sender email address
@override final  String fromEmail;
/// Transaction amount (always positive)
@override final  double amount;
/// Currency code (VND, USD, etc.)
@override@JsonKey() final  String currency;
/// Transaction type: 'income' or 'expense'
@override final  String transactionType;
/// Merchant or payee name
@override final  String? merchant;
/// Last 4 digits of account number
@override final  String? accountLast4;
/// Balance after transaction
@override final  double? balanceAfter;
/// Date of the transaction
@override final  DateTime transactionDate;
/// Date the email was received
@override final  DateTime emailDate;
/// Confidence score (0-1)
@override@JsonKey() final  double confidence;
/// Raw amount text from email
@override final  String rawAmountText;
/// Suggested category
@override final  String? categoryHint;
/// Bank or e-wallet name
@override final  String bankName;
/// Status of the parsed transaction
@override@JsonKey() final  ParsedTransactionStatus status;
/// ID of the imported transaction (if imported)
@override final  String? importedTransactionId;
/// User's wallet ID to import to
@override final  String? targetWalletCloudId;
/// User's selected category ID
@override final  String? selectedCategoryCloudId;
/// User's notes/edits
@override final  String? userNotes;
/// Created timestamp
@override final  DateTime? createdAt;
/// Updated timestamp
@override final  DateTime? updatedAt;

/// Create a copy of ParsedEmailTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedEmailTransactionModelCopyWith<_ParsedEmailTransactionModel> get copyWith => __$ParsedEmailTransactionModelCopyWithImpl<_ParsedEmailTransactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedEmailTransactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedEmailTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.emailId, emailId) || other.emailId == emailId)&&(identical(other.emailSubject, emailSubject) || other.emailSubject == emailSubject)&&(identical(other.fromEmail, fromEmail) || other.fromEmail == fromEmail)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.emailDate, emailDate) || other.emailDate == emailDate)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rawAmountText, rawAmountText) || other.rawAmountText == rawAmountText)&&(identical(other.categoryHint, categoryHint) || other.categoryHint == categoryHint)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedTransactionId, importedTransactionId) || other.importedTransactionId == importedTransactionId)&&(identical(other.targetWalletCloudId, targetWalletCloudId) || other.targetWalletCloudId == targetWalletCloudId)&&(identical(other.selectedCategoryCloudId, selectedCategoryCloudId) || other.selectedCategoryCloudId == selectedCategoryCloudId)&&(identical(other.userNotes, userNotes) || other.userNotes == userNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,cloudId,emailId,emailSubject,fromEmail,amount,currency,transactionType,merchant,accountLast4,balanceAfter,transactionDate,emailDate,confidence,rawAmountText,categoryHint,bankName,status,importedTransactionId,targetWalletCloudId,selectedCategoryCloudId,userNotes,createdAt,updatedAt]);

@override
String toString() {
  return 'ParsedEmailTransactionModel(id: $id, cloudId: $cloudId, emailId: $emailId, emailSubject: $emailSubject, fromEmail: $fromEmail, amount: $amount, currency: $currency, transactionType: $transactionType, merchant: $merchant, accountLast4: $accountLast4, balanceAfter: $balanceAfter, transactionDate: $transactionDate, emailDate: $emailDate, confidence: $confidence, rawAmountText: $rawAmountText, categoryHint: $categoryHint, bankName: $bankName, status: $status, importedTransactionId: $importedTransactionId, targetWalletCloudId: $targetWalletCloudId, selectedCategoryCloudId: $selectedCategoryCloudId, userNotes: $userNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ParsedEmailTransactionModelCopyWith<$Res> implements $ParsedEmailTransactionModelCopyWith<$Res> {
  factory _$ParsedEmailTransactionModelCopyWith(_ParsedEmailTransactionModel value, $Res Function(_ParsedEmailTransactionModel) _then) = __$ParsedEmailTransactionModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? cloudId, String emailId, String emailSubject, String fromEmail, double amount, String currency, String transactionType, String? merchant, String? accountLast4, double? balanceAfter, DateTime transactionDate, DateTime emailDate, double confidence, String rawAmountText, String? categoryHint, String bankName, ParsedTransactionStatus status, String? importedTransactionId, String? targetWalletCloudId, String? selectedCategoryCloudId, String? userNotes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ParsedEmailTransactionModelCopyWithImpl<$Res>
    implements _$ParsedEmailTransactionModelCopyWith<$Res> {
  __$ParsedEmailTransactionModelCopyWithImpl(this._self, this._then);

  final _ParsedEmailTransactionModel _self;
  final $Res Function(_ParsedEmailTransactionModel) _then;

/// Create a copy of ParsedEmailTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? cloudId = freezed,Object? emailId = null,Object? emailSubject = null,Object? fromEmail = null,Object? amount = null,Object? currency = null,Object? transactionType = null,Object? merchant = freezed,Object? accountLast4 = freezed,Object? balanceAfter = freezed,Object? transactionDate = null,Object? emailDate = null,Object? confidence = null,Object? rawAmountText = null,Object? categoryHint = freezed,Object? bankName = null,Object? status = null,Object? importedTransactionId = freezed,Object? targetWalletCloudId = freezed,Object? selectedCategoryCloudId = freezed,Object? userNotes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ParsedEmailTransactionModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,emailId: null == emailId ? _self.emailId : emailId // ignore: cast_nullable_to_non_nullable
as String,emailSubject: null == emailSubject ? _self.emailSubject : emailSubject // ignore: cast_nullable_to_non_nullable
as String,fromEmail: null == fromEmail ? _self.fromEmail : fromEmail // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,balanceAfter: freezed == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,emailDate: null == emailDate ? _self.emailDate : emailDate // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rawAmountText: null == rawAmountText ? _self.rawAmountText : rawAmountText // ignore: cast_nullable_to_non_nullable
as String,categoryHint: freezed == categoryHint ? _self.categoryHint : categoryHint // ignore: cast_nullable_to_non_nullable
as String?,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParsedTransactionStatus,importedTransactionId: freezed == importedTransactionId ? _self.importedTransactionId : importedTransactionId // ignore: cast_nullable_to_non_nullable
as String?,targetWalletCloudId: freezed == targetWalletCloudId ? _self.targetWalletCloudId : targetWalletCloudId // ignore: cast_nullable_to_non_nullable
as String?,selectedCategoryCloudId: freezed == selectedCategoryCloudId ? _self.selectedCategoryCloudId : selectedCategoryCloudId // ignore: cast_nullable_to_non_nullable
as String?,userNotes: freezed == userNotes ? _self.userNotes : userNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
