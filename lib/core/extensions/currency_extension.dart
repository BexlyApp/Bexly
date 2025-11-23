extension CurrencyExtension on String {
  /// Get currency symbol from ISO code (e.g., "USD" → "$", "VND" → "₫")
  String get currencySymbol {
    switch (toUpperCase()) {
      case 'USD':
        return '\$';
      case 'VND':
        return '₫';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'THB':
        return '฿';
      case 'INR':
        return '₹';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'SGD':
        return 'S\$';
      case 'HKD':
        return 'HK\$';
      default:
        return this; // Return currency code if symbol unknown
    }
  }
}
