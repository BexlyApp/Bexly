/// Product IDs for in-app purchases
/// These must match the product IDs configured in Google Play Console and App Store Connect
class SubscriptionProducts {
  SubscriptionProducts._();

  // Plus tier products
  static const String plusMonthly = 'bexly_plus_monthly';
  static const String plusYearly = 'bexly_plus_yearly';

  // Pro tier products
  static const String proMonthly = 'bexly_pro_monthly';
  static const String proYearly = 'bexly_pro_yearly';

  /// All subscription product IDs
  static const Set<String> allProductIds = {
    plusMonthly,
    plusYearly,
    proMonthly,
    proYearly,
  };

  /// Plus tier product IDs
  static const Set<String> plusProductIds = {
    plusMonthly,
    plusYearly,
  };

  /// Pro tier product IDs
  static const Set<String> proProductIds = {
    proMonthly,
    proYearly,
  };

  /// Check if a product ID belongs to Plus tier
  static bool isPlusProduct(String productId) {
    return plusProductIds.contains(productId);
  }

  /// Check if a product ID belongs to Pro tier
  static bool isProProduct(String productId) {
    return proProductIds.contains(productId);
  }

  /// Check if a product is a yearly subscription
  static bool isYearlyProduct(String productId) {
    return productId.endsWith('_yearly');
  }

  /// Check if a product is a monthly subscription
  static bool isMonthlyProduct(String productId) {
    return productId.endsWith('_monthly');
  }
}
