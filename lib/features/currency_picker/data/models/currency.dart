import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';
part 'currency.g.dart';

@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    required String symbol,
    required String name,
    @JsonKey(name: 'decimal_digits') required int decimalDigits,
    required double rounding,
    @JsonKey(name: 'iso_code') required String isoCode,
    @JsonKey(name: 'name_plural') required String namePlural,
    required String country,
    @JsonKey(name: 'country_code') required String countryCode,
  }) = _Currency;

  factory Currency.fromJson(Map<String, dynamic> json) =>
      _$CurrencyFromJson(json);
}

extension CurrencyExtensions on Currency {
  String get symbolWithCountry => '$symbol - $country';
}

extension CurrencyUtils on List<Currency> {
  Currency? fromIsoCode(String code) {
    return firstWhereOrNull((currency) => currency.isoCode == code);
  }
}

/// Format amount with currency symbol in correct position
/// For VND: "123,456 đ" (symbol after)
/// For others: "$ 123,456" (symbol before)
String formatAmountWithCurrency({
  required double amount,
  required String symbol,
  required String isoCode,
  int? decimalDigits,
  bool showSign = false,
}) {
  final sign = showSign ? (amount >= 0 ? '+' : '-') : (amount < 0 ? '-' : '');
  final absAmount = _formatPrice(amount.abs(), decimalDigits ?? 0);

  // VND, JPY, KRW use symbol after amount
  final symbolAfterCurrencies = ['VND', 'JPY', 'KRW'];
  if (symbolAfterCurrencies.contains(isoCode.toUpperCase())) {
    return '$sign $absAmount $symbol'.trim();
  }
  // Others use symbol before amount
  return '$sign $symbol $absAmount'.trim();
}

String _formatPrice(double value, int decimalDigits) {
  // Handle negative zero
  final v = value.abs() < 0.005 ? 0.0 : value;
  if (decimalDigits == 0) {
    return _numberWithCommas(v.round());
  }
  return _numberWithCommas(v, decimalDigits: decimalDigits);
}

String _numberWithCommas(num value, {int decimalDigits = 0}) {
  if (decimalDigits == 0) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
  final parts = value.toStringAsFixed(decimalDigits).split('.');
  parts[0] = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return parts.join('.');
}
