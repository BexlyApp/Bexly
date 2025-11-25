import 'dart:typed_data';

/// Receipt scan result model - Manual implementation (no Freezed)
/// to avoid Freezed v3.2.0 code generation bug
class ReceiptScanResult {
  final double amount;
  final String? currency;
  final String category;
  final String date;
  final String merchant;
  final String paymentMethod;
  final List<String> items;
  final String? taxAmount;
  final String? tipAmount;
  final Uint8List? imageBytes; // Receipt image bytes

  const ReceiptScanResult({
    required this.amount,
    this.currency,
    required this.category,
    required this.date,
    required this.merchant,
    required this.paymentMethod,
    required this.items,
    this.taxAmount,
    this.tipAmount,
    this.imageBytes,
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    return ReceiptScanResult(
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount'].toString()),
      currency: json['currency'] as String?,
      category: json['category'] as String,
      date: json['date'] as String,
      merchant: json['merchant'] as String,
      paymentMethod: json['payment_method'] as String,
      items: (json['items'] as List<dynamic>).cast<String>(),
      taxAmount: json['tax_amount'] as String?,
      tipAmount: json['tip_amount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date,
      'merchant': merchant,
      'payment_method': paymentMethod,
      'items': items,
      'tax_amount': taxAmount,
      'tip_amount': tipAmount,
    };
  }

  @override
  String toString() {
    return 'ReceiptScanResult(amount: $amount, currency: $currency, category: $category, '
        'date: $date, merchant: $merchant, paymentMethod: $paymentMethod, '
        'items: $items, taxAmount: $taxAmount, tipAmount: $tipAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptScanResult &&
        other.amount == amount &&
        other.currency == currency &&
        other.category == category &&
        other.date == date &&
        other.merchant == merchant &&
        other.paymentMethod == paymentMethod &&
        _listEquals(other.items, items) &&
        other.taxAmount == taxAmount &&
        other.tipAmount == tipAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      amount,
      currency,
      category,
      date,
      merchant,
      paymentMethod,
      Object.hashAll(items),
      taxAmount,
      tipAmount,
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
