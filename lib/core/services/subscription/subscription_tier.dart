import 'package:bexly/features/family/domain/enums/family_role.dart';

/// Subscription tier levels for Bexly
enum SubscriptionTier {
  /// Free tier - limited features
  free,

  /// Plus tier - $2.99/month or $29.99/year
  plus,

  /// Pro tier - $5.99/month or $59.99/year
  pro,

  /// Plus Family tier - $4.99/month or $49.99/year
  /// Plus features + Family sharing (up to 5 members)
  plusFamily,

  /// Pro Family tier - $9.99/month or $99.99/year
  /// Pro features + Family sharing (up to 5 members)
  proFamily,
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
      case SubscriptionTier.plusFamily:
        return 'Plus Family';
      case SubscriptionTier.proFamily:
        return 'Pro Family';
    }
  }

  /// Whether this tier includes the features of another tier
  bool includes(SubscriptionTier other) {
    // Family tiers include their base tier features
    if (this == SubscriptionTier.plusFamily) {
      return other == SubscriptionTier.free || other == SubscriptionTier.plus;
    }
    if (this == SubscriptionTier.proFamily) {
      return other != SubscriptionTier.proFamily;
    }
    return index >= other.index;
  }

  /// Check if user has at least this tier level
  bool hasAccess(SubscriptionTier requiredTier) {
    return includes(requiredTier);
  }

  /// Whether this tier has full family sharing (5 members, unlimited wallets)
  bool get hasFullFamily {
    return this == SubscriptionTier.plusFamily || this == SubscriptionTier.proFamily;
  }

  /// Get the base tier (without family)
  SubscriptionTier get baseTier {
    switch (this) {
      case SubscriptionTier.plusFamily:
        return SubscriptionTier.plus;
      case SubscriptionTier.proFamily:
        return SubscriptionTier.pro;
      default:
        return this;
    }
  }

  /// Check if this tier has Pro-level features
  bool get isProLevel {
    return this == SubscriptionTier.pro || this == SubscriptionTier.proFamily;
  }

  /// Check if this tier has Plus-level features (or higher)
  bool get isPlusLevel {
    return this != SubscriptionTier.free;
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
        return 3;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
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
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
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
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
        return -1; // Unlimited
    }
  }

  /// Maximum number of recurring transactions allowed
  int get maxRecurring {
    switch (tier) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
        return -1; // Unlimited
    }
  }

  /// Maximum AI messages per month
  int get maxAiMessagesPerMonth {
    switch (tier) {
      case SubscriptionTier.free:
        return 60;
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return 240;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return -1; // Unlimited
    }
  }

  /// AI model tier name
  String get aiModelTier {
    switch (tier) {
      case SubscriptionTier.free:
        return 'standard';
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return 'premium';
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return 'flagship';
    }
  }

  /// Analytics history in months (-1 = unlimited)
  int get analyticsHistoryMonths {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return 6;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return -1; // All history
    }
  }

  /// Whether multi-currency is allowed
  bool get allowMultiCurrency {
    // All tiers can use multi-currency now
    return true;
  }

  /// Whether Firebase real-time sync is allowed
  bool get allowFirebaseSync {
    // All tiers have basic cloud sync
    return true;
  }

  /// Whether receipt photos are allowed
  bool get allowReceiptPhotos {
    switch (tier) {
      case SubscriptionTier.free:
        return false;
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
        return true;
    }
  }

  /// Receipt storage limit in MB (-1 = unlimited)
  int get receiptStorageLimitMB {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return 1024; // 1GB
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return 5120; // 5GB
    }
  }

  /// Whether OCR receipt scanning is available
  bool get allowReceiptOCR {
    return tier.isProLevel;
  }

  /// Whether ads should be shown
  bool get showAds {
    return tier == SubscriptionTier.free;
  }

  /// Whether AI insights/predictions are available
  bool get allowAiInsights {
    return tier.isProLevel;
  }

  /// Whether priority support is available
  bool get hasPrioritySupport {
    return tier.isProLevel;
  }

  // ============== Family Sharing Limits ==============

  /// Whether family sharing is enabled (all tiers have basic family)
  bool get allowFamilySharing {
    return true; // All tiers can use family sharing
  }

  /// Maximum number of family members (including owner)
  /// Free: 2 (owner + 1 member)
  /// Plus/Pro: 3 members
  /// Family tiers: 5 members
  int get maxFamilyMembers {
    switch (tier) {
      case SubscriptionTier.free:
        return 2; // Owner + 1 member
      case SubscriptionTier.plus:
      case SubscriptionTier.pro:
        return 3; // Owner + 2 members
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
        return 5; // Owner + 4 members
    }
  }

  /// Maximum number of wallets that can be shared with family
  /// Free: 1 wallet
  /// Plus: 2 wallets
  /// Pro: 3 wallets
  /// Family tiers: Unlimited
  int get maxSharedWallets {
    switch (tier) {
      case SubscriptionTier.free:
        return 1;
      case SubscriptionTier.plus:
        return 2;
      case SubscriptionTier.pro:
        return 3;
      case SubscriptionTier.plusFamily:
      case SubscriptionTier.proFamily:
        return -1; // Unlimited
    }
  }

  /// Available family roles for this tier
  /// Free: Viewer only (cannot edit)
  /// Plus: Owner, Viewer
  /// Pro: Owner, Editor, Viewer
  /// Family tiers: All roles
  List<FamilyRole> get availableFamilyRoles {
    switch (tier) {
      case SubscriptionTier.free:
        return [FamilyRole.owner, FamilyRole.viewer];
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return [FamilyRole.owner, FamilyRole.viewer];
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return [FamilyRole.owner, FamilyRole.editor, FamilyRole.viewer];
    }
  }

  /// Whether members can have Editor role
  bool get allowEditorRole {
    return tier.isProLevel;
  }

  /// Whether user can create a family (all tiers can create)
  bool get canCreateFamily {
    return true;
  }

  /// Whether user can invite members (all tiers can invite up to their limit)
  bool get canInviteMembers {
    return true;
  }

  /// Check if a count exceeds the limit (-1 means unlimited)
  bool isWithinLimit(int count, int limit) {
    if (limit == -1) return true;
    return count < limit;
  }
}
