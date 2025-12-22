import 'package:freezed_annotation/freezed_annotation.dart';

part 'linked_account_model.freezed.dart';
part 'linked_account_model.g.dart';

/// Model representing a linked bank account from Stripe Financial Connections
@freezed
class LinkedAccount with _$LinkedAccount {
  const factory LinkedAccount({
    required String id,
    required String institutionName,
    String? displayName,
    String? last4,
    String? category, // checking, savings, credit_card, etc.
    String? status,
    LinkedAccountBalance? balance,
  }) = _LinkedAccount;

  factory LinkedAccount.fromJson(Map<String, dynamic> json) =>
      _$LinkedAccountFromJson(json);
}

@freezed
class LinkedAccountBalance with _$LinkedAccountBalance {
  const factory LinkedAccountBalance({
    int? current,
    int? available,
    String? asOf, // ISO 8601 date
  }) = _LinkedAccountBalance;

  factory LinkedAccountBalance.fromJson(Map<String, dynamic> json) =>
      _$LinkedAccountBalanceFromJson(json);
}
