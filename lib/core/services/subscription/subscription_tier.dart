/// Subscription tier levels for Bexly
enum SubscriptionTier {
  /// Free tier - limited features
  free,

  /// Plus tier - $2.99/month or $29.99/year
  plus,

  /// Pro tier - $5.99/month or $59.99/year
  pro,
}

/// Extension to add utility methods to SubscriptionTier
extension SubscriptionTierExtension on SubscriptionTier {
  /// Display name for the tier
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  /// Whether this tier includes the features of another tier
  bool includes(SubscriptionTier other) {
    return index >= other.index;
  }

  /// Check if user has at least this tier level
  bool hasAccess(SubscriptionTier requiredTier) {
    return index >= requiredTier.index;
  }
}

/// Feature limits based on subscription tier
class SubscriptionLimits {
  final SubscriptionTier tier;

  const SubscriptionLimits(this.tier);

  /// Maximum number of wallets allowed
  int get maxWallets {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Maximum number of budgets allowed
  int get maxBudgets {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Maximum number of goals allowed
  int get maxGoals {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Maximum number of recurring transactions allowed
  int get maxRecurring {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Maximum AI messages per month
  int get maxAiMessagesPerMonth {
    switch (tier) {
      case SubscriptionTier.free:
        return 30;
      case SubscriptionTier.plus:
        return 50;
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Analytics history in months (0 = current month only)
  int get analyticsHistoryMonths {
    switch (tier) {
      case SubscriptionTier.free:
        return 1; // Last month + current month
      case SubscriptionTier.plus:
        return 6;
      case SubscriptionTier.pro:
        return -1; // All history
    }
  }

  /// Whether multi-currency is allowed
  bool get allowMultiCurrency {
    switch (tier) {
      case SubscriptionTier.free:
        return false;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return true;
    }
  }

  /// Whether Firebase real-time sync is allowed
  bool get allowFirebaseSync {
    switch (tier) {
      case SubscriptionTier.free:
        return false;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return true;
    }
  }

  /// Whether receipt photos are allowed
  bool get allowReceiptPhotos {
    switch (tier) {
      case SubscriptionTier.free:
        return false;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return true;
    }
  }

  /// Receipt storage limit in MB (-1 = unlimited)
  int get receiptStorageLimitMB {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.plus:
        return 1024; // 1GB
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  /// Whether OCR receipt scanning is available
  bool get allowReceiptOCR {
    switch (tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.plus:
        return false;
      case SubscriptionTier.pro:
        return true;
    }
  }

  /// Check if a count exceeds the limit (-1 means unlimited)
  bool isWithinLimit(int count, int limit) {
    if (limit == -1) return true;
    return count < limit;
  }
}
