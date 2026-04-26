import 'package:bexly/features/family/domain/enums/family_role.dart';

/// Subscription tier levels for Bexly. See docs/PREMIUM_PLAN.md for the
/// canonical feature matrix and pricing.
enum SubscriptionTier {
  /// Free tier - $0
  free,

  /// Go tier - $1.99/month or $19.99/year. Maps to DOS.Me Go.
  go,

  /// Premium tier - $5/month or $25/year. Maps to DOS.Me Plus.
  premium,
}

/// Extension to add utility methods to SubscriptionTier
extension SubscriptionTierExtension on SubscriptionTier {
  /// Display name for the tier
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.go:
        return 'Go';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  /// Whether this tier includes the features of another tier (ordered: free < go < premium)
  bool includes(SubscriptionTier other) => index >= other.index;

  /// Check if user has at least this tier level
  bool hasAccess(SubscriptionTier requiredTier) => includes(requiredTier);

  /// Check if this tier is Go or higher (any paid tier)
  bool get isPaid => this != SubscriptionTier.free;

  /// Check if this tier has Premium-level features
  bool get isPremiumLevel => this == SubscriptionTier.premium;
}

/// Feature limits based on subscription tier. See docs/PREMIUM_PLAN.md.
class SubscriptionLimits {
  final SubscriptionTier tier;

  const SubscriptionLimits(this.tier);

  /// Maximum number of wallets allowed (-1 = unlimited)
  int get maxWallets {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return -1;
    }
  }

  /// Maximum number of budgets allowed (-1 = unlimited)
  int get maxBudgets {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return -1;
    }
  }

  /// Maximum number of goals allowed (-1 = unlimited)
  int get maxGoals {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return -1;
    }
  }

  /// Maximum number of recurring transactions (-1 = unlimited)
  int get maxRecurring {
    switch (tier) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return -1;
    }
  }

  /// AI messages per month
  int get maxAiMessagesPerMonth {
    switch (tier) {
      case SubscriptionTier.free:
        return 60;
      case SubscriptionTier.go:
        return 240;
      case SubscriptionTier.premium:
        return 600;
    }
  }

  /// Analytics history in months (-1 = unlimited)
  int get analyticsHistoryMonths {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.go:
        return 6;
      case SubscriptionTier.premium:
        return 24; // 2 years
    }
  }

  /// Multi-currency available on all tiers
  bool get allowMultiCurrency => true;

  /// Cloud sync available on all tiers
  bool get allowFirebaseSync => true;

  /// Whether OCR receipt scanning is available
  bool get allowReceiptOCR => tier.isPaid;

  /// Whether receipt photo storage is available
  bool get allowReceiptPhotos => tier.isPaid;

  /// Receipt photo retention in months (-1 = no storage)
  int get receiptRetentionMonths {
    switch (tier) {
      case SubscriptionTier.free:
        return -1;
      case SubscriptionTier.go:
        return 12; // 1 year
      case SubscriptionTier.premium:
        return 36; // 3 years
    }
  }

  /// Whether ads should be shown
  bool get showAds => tier == SubscriptionTier.free;

  /// Whether AI insights/predictions are available
  bool get allowAiInsights => tier.isPremiumLevel;

  /// Whether priority support is available
  bool get hasPrioritySupport => tier.isPremiumLevel;

  // ============== Family Sharing ==============

  /// Family sharing available on all tiers
  bool get allowFamilySharing => true;

  /// Maximum number of family members (including owner)
  int get maxFamilyMembers {
    switch (tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.go:
        return 2;
      case SubscriptionTier.premium:
        return 5;
    }
  }

  /// Maximum number of wallets that can be shared with family (-1 = unlimited)
  int get maxSharedWallets {
    switch (tier) {
      case SubscriptionTier.free:
        return 1;
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return -1;
    }
  }

  /// Available family roles. Free is viewer-only; Go and Premium include Editor.
  List<FamilyRole> get availableFamilyRoles {
    switch (tier) {
      case SubscriptionTier.free:
        return [FamilyRole.owner, FamilyRole.viewer];
      case SubscriptionTier.go:
      case SubscriptionTier.premium:
        return [FamilyRole.owner, FamilyRole.editor, FamilyRole.viewer];
    }
  }

  /// Whether members can have Editor role
  bool get allowEditorRole => tier.isPaid;

  /// Whether user can create a family (all tiers can create)
  bool get canCreateFamily => true;

  /// Whether user can invite members (all tiers can invite up to their limit)
  bool get canInviteMembers => true;

  /// Check if a count is within the limit (-1 means unlimited)
  bool isWithinLimit(int count, int limit) {
    if (limit == -1) return true;
    return count < limit;
  }
}
