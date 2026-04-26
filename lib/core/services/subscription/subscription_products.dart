/// Product IDs for in-app purchases.
/// These must match the product IDs configured in Google Play Console
/// and App Store Connect. See docs/PREMIUM_PLAN.md for prices.
class SubscriptionProducts {
  SubscriptionProducts._();

  // Go tier products ($1.99/mo, $19.99/yr)
  static const String goMonthly = 'bexly_go_monthly';
  static const String goYearly = 'bexly_go_yearly';

  // Premium tier products ($5/mo, $25/yr) — maps to DOS.Me Plus
  static const String premiumMonthly = 'bexly_premium_monthly';
  static const String premiumYearly = 'bexly_premium_yearly';

  /// All subscription product IDs
  static const Set<String> allProductIds = {
    goMonthly,
    goYearly,
    premiumMonthly,
    premiumYearly,
  };

  /// Go tier product IDs
  static const Set<String> goProductIds = {goMonthly, goYearly};

  /// Premium tier product IDs
  static const Set<String> premiumProductIds = {premiumMonthly, premiumYearly};

  static bool isGoProduct(String productId) => goProductIds.contains(productId);

  static bool isPremiumProduct(String productId) =>
      premiumProductIds.contains(productId);

  static bool isYearlyProduct(String productId) =>
      productId.endsWith('_yearly');

  static bool isMonthlyProduct(String productId) =>
      productId.endsWith('_monthly');
}
