/// Represents a suggested recurring payment detected by AI from transaction history.
///
/// This is a lightweight DTO parsed from AI JSON response.
/// Not stored in database - only used for display and conversion to RecurringModel.
class RecurringSuggestion {
  final String name;
  final double amount;
  final String currency;
  final String frequency; // "weekly", "monthly", "quarterly", "yearly"
  final int? billingDay;
  final String category;
  final double confidence;
  final List<String> matchingTitles;
  final DateTime nextExpected;

  const RecurringSuggestion({
    required this.name,
    required this.amount,
    required this.currency,
    required this.frequency,
    this.billingDay,
    required this.category,
    required this.confidence,
    required this.matchingTitles,
    required this.nextExpected,
  });

  factory RecurringSuggestion.fromJson(Map<String, dynamic> json) {
    return RecurringSuggestion(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      frequency: json['frequency'] as String? ?? 'monthly',
      billingDay: json['billing_day'] as int?,
      category: json['category'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      matchingTitles: (json['matching_titles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nextExpected: DateTime.tryParse(json['next_expected']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Get display label for frequency
  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }
}
