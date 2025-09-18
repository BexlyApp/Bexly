
class ReceiptScanResult {
  final double amount;
  final String category;
  final String date;
  final String merchant;
  final String paymentMethod;
  final List<String> items;
  final String? taxAmount;
  final String? tipAmount;

  ReceiptScanResult({
    required this.amount,
    required this.category,
    required this.date,
    required this.merchant,
    required this.paymentMethod,
    required this.items,
    this.taxAmount,
    this.tipAmount,
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    return ReceiptScanResult(
      amount: json['amount'] is num
          ? json['amount'].toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      category: json['category'] as String? ?? 'Uncategorized',
      date: json['date'] as String? ?? 'Unknown date',
      merchant: json['merchant'] as String? ?? 'Unknown merchant',
      paymentMethod: json['payment_method'] as String? ?? 'Unknown',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      taxAmount: json['tax_amount']?.toString(),
      tipAmount: json['tip_amount']?.toString(),
    );
  }
}