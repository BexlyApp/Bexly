/// Product IDs for in-app purchases.
/// These must match the product IDs configured in Google Play Console
/// and App Store Connect. See docs/PREMIUM_PLAN.md for prices.
class SubscriptionProducts {
  SubscriptionProducts._();

  // Go tier products ($1.99/mo, $19.99/yr)
  static const String goMonthly = 'bexly_go_monthly';
  static const String goYearly = 'bexly_go_yearly';

  // Plus tier products ($5/mo, $25/yr) — maps to DOS.Me Plus plan
  static const String plusMonthly = 'bexly_plus_monthly';
  static const String plusYearly = 'bexly_plus_yearly';

  /// All subscription product IDs
  static const Set<String> allProductIds = {
    goMonthly,
    goYearly,
    plusMonthly,
    plusYearly,
  };

  /// Go tier product IDs
  static const Set<String> goProductIds = {goMonthly, goYearly};

  /// Plus tier product IDs
  static const Set<String> plusProductIds = {plusMonthly, plusYearly};

  static bool isGoProduct(String productId) => goProductIds.contains(productId);

  static bool isPlusProduct(String productId) =>
      plusProductIds.contains(productId);

  static bool isYearlyProduct(String productId) =>
      productId.endsWith('_yearly');

  static bool isMonthlyProduct(String productId) =>
      productId.endsWith('_monthly');
}
