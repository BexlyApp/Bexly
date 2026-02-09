import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/config/number_format_config.dart';

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
  if (_symbolAfterCurrencies.contains(isoCode.toUpperCase())) {
    return '$sign $absAmount $symbol'.trim();
  }
  // Others use symbol before amount
  return '$sign $symbol $absAmount'.trim();
}

/// Currencies where symbol appears after the amount
const _symbolAfterCurrencies = ['VND', 'JPY', 'KRW'];

/// Whether this currency places the symbol after the amount (e.g., VND, JPY, KRW)
bool isSymbolAfterAmount(String isoCode) {
  return _symbolAfterCurrencies.contains(isoCode.toUpperCase());
}

/// Position a currency symbol around a pre-formatted amount string.
///
/// For VND/JPY/KRW: "14,800,555 ₫"
/// For others: "$ 100.50"
String formatCurrency(String formattedAmount, String symbol, String isoCode) {
  if (_symbolAfterCurrencies.contains(isoCode.toUpperCase())) {
    return '$formattedAmount $symbol';
  }
  return '$symbol$formattedAmount';
}

String _formatPrice(double value, int decimalDigits) {
  // Handle negative zero
  final v = value.abs() < 0.005 ? 0.0 : value;
  final locale = NumberFormatConfig.locale;
  if (decimalDigits == 0) {
    return NumberFormat('#,##0', locale).format(v.round());
  }
  return NumberFormat('#,##0.${'0' * decimalDigits}', locale).format(v);
}
