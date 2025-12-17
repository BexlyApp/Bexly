# Bexly Premium Plan

## Overview
Bexly operates on a freemium model with cloud sync support. Free users get core functionality with ads. Premium users get more features, better AI, and ad-free experience. Family plans allow sharing wallets with up to 5 members.

## Tier Structure

### Free Tier
**Price:** $0 forever

**Features:**
- 3 wallets
- 2 budgets & 2 goals
- 5 recurring transactions
- 3 months analytics history
- 60 DOS AI messages/month
- Cloud sync (basic)
- Manual export/import (JSON/CSV)

**Limitations:**
- Contains ads
- No receipt photo storage
- DOS AI model only (cannot choose other models)
- No family sharing

---

### Plus Tier
**Price:** $2.99/month or $29.99/year (2 months free)

**Everything in Free, plus:**
- Unlimited wallets
- Unlimited budgets & goals
- Unlimited recurring transactions
- 6 months analytics history
- 120 DOS AI messages/month
- 120 Premium AI messages/month (Gemini 2.5 Pro)
- Can choose between DOS AI and Gemini
- Receipt photo storage (1GB)
- **No ads**

---

### Pro Tier
**Price:** $5.99/month or $59.99/year (2 months free)

**Everything in Plus, plus:**
- Full analytics history (unlimited)
- 300 DOS AI messages/month
- 300 Premium AI messages/month (Gemini 2.5 Pro)
- 100 Flagship AI messages/month (GPT-4o / Claude)
- Can choose any AI model
- Receipt photo storage (5GB)
- AI insights & predictions
- Priority support
- Early access to new features

---

### Plus Family Tier
**Price:** $4.99/month or $49.99/year (2 months free)

**Everything in Plus, plus:**
- Family sharing (up to 5 members)
- Shared wallets with role-based access
- Track who created each transaction
- Owner/Editor/Viewer roles
- Invite via link or email

---

### Pro Family Tier
**Price:** $9.99/month or $99.99/year (2 months free)

**Everything in Pro, plus:**
- Family sharing (up to 5 members)
- Shared wallets with role-based access
- Track who created each transaction
- Owner/Editor/Viewer roles
- Invite via link or email

---

## AI Model Tiers

| Tier | Description | Notes |
|------|-------------|-------|
| Standard | Free model for all users | Self-hosted, good for simple tasks |
| Premium | Better accuracy and reasoning | Available for Plus+ subscribers |
| Flagship | Best AI capabilities | Available for Pro subscribers only |

*Specific models are managed internally and may be upgraded over time.*

---

## Feature Comparison

| Feature | Free | Plus | Pro | Plus Family | Pro Family |
|---------|------|------|-----|-------------|------------|
| Wallets | 3 | Unlimited | Unlimited | Unlimited | Unlimited |
| Budgets & Goals | 2 each | Unlimited | Unlimited | Unlimited | Unlimited |
| Recurring transactions | 5 | Unlimited | Unlimited | Unlimited | Unlimited |
| Analytics history | 3 months | 6 months | Unlimited | 6 months | Unlimited |
| DOS AI messages | 60/month | 120/month | 300/month | 120/month | 300/month |
| Premium AI (Gemini) | - | 120/month | 300/month | 120/month | 300/month |
| Flagship AI (GPT-4o) | - | - | 100/month | - | 100/month |
| Choose AI model | No | Yes | Yes | Yes | Yes |
| Receipt photos | - | 1GB | 5GB | 1GB | 5GB |
| Cloud sync | Basic | Full | Full | Full | Full |
| Ads | Yes | No | No | No | No |
| Priority support | - | - | Yes | - | Yes |
| **Family sharing** | - | - | - | **5 members** | **5 members** |
| **Shared wallets** | - | - | - | **Yes** | **Yes** |

---

## Family Sharing Features

### Member Roles
| Role | Permissions |
|------|-------------|
| **Owner** | Full control - invite/remove members, share/unshare wallets, CRUD all transactions |
| **Editor** | Can share wallets, create/edit/delete transactions |
| **Viewer** | Read-only access to shared wallets |

### How It Works
1. **Create Family**: Owner creates a family group
2. **Invite Members**: Via email or shareable link (e.g., `join.bexly.app/f/ABC123`)
3. **Share Wallets**: Choose which wallets to share with the family
4. **Track Activity**: See who created each transaction
5. **Workspaces**: Toggle between Personal and Family view

### Invite Link Format
```
join.bexly.app/f/ABC123XY   → Family invite (random 8-char code)
join.bexly.app/f/joyng      → Family invite via username
join.bexly.app/f/u_abc123   → Family invite via user ID (default, before username claimed)
```

---

## Technical Implementation

### Product IDs (Google Play & App Store)

| Plan | Product ID | Price (USD) | Price (VND) |
|------|------------|-------------|-------------|
| Plus Monthly | `bexly_plus_monthly` | $2.99/month | 79,000đ/tháng |
| Plus Yearly | `bexly_plus_yearly` | $29.99/year | 790,000đ/năm |
| Pro Monthly | `bexly_pro_monthly` | $5.99/month | 149,000đ/tháng |
| Pro Yearly | `bexly_pro_yearly` | $59.99/year | 1,490,000đ/năm |
| Plus Family Monthly | `bexly_plus_family_monthly` | $4.99/month | 129,000đ/tháng |
| Plus Family Yearly | `bexly_plus_family_yearly` | $49.99/year | 1,290,000đ/năm |
| Pro Family Monthly | `bexly_pro_family_monthly` | $9.99/month | 249,000đ/tháng |
| Pro Family Yearly | `bexly_pro_family_yearly` | $99.99/year | 2,490,000đ/năm |

**Subscription Group:** `Bexly Premium`

### Subscription Management
**Payment Processing:**
- Google Play Billing (Android)
- StoreKit (iOS)
- RevenueCat for cross-platform management (optional)

**Verification:**
- Server-side validation via Firebase Functions
- Grace period for expired payments (7 days)

### Feature Gating
```dart
// Check feature access
bool canCreateWallet() {
  if (subscription.isPro || subscription.isPlus) return true;
  return currentWalletCount < 3;
}

bool canUseAI(AIModel model) {
  final usage = getAIUsage();
  switch (model) {
    case AIModel.dosAI:
      final limit = subscription.isProLevel ? 300 : subscription.isPlusLevel ? 120 : 60;
      return usage.dosAI < limit;
    case AIModel.gemini:
      if (subscription.isFree) return false;
      final limit = subscription.isProLevel ? 300 : 120;
      return usage.gemini < limit;
    case AIModel.openAI:
      if (!subscription.isProLevel) return false;
      return usage.openAI < 100;
  }
}

bool canChooseModel() {
  return subscription.isPlusLevel; // Plus, Pro, Plus Family, Pro Family
}

bool canUseFamily() {
  return subscription.hasFamily; // Plus Family or Pro Family
}

List<AIModel> getAvailableModels() {
  if (subscription.isProLevel) return [AIModel.dosAI, AIModel.gemini, AIModel.openAI];
  if (subscription.isPlusLevel) return [AIModel.dosAI, AIModel.gemini];
  return [AIModel.dosAI];
}
```

### Ad Implementation (Free Tier)
- Banner ads on Home/History screens
- Interstitial ads after every 5th transaction (non-intrusive)
- No ads during onboarding or critical flows

---

## Pricing Strategy

### Regional Pricing (VND)
| Plan | Monthly | Yearly |
|------|---------|--------|
| Plus | 79,000đ | 790,000đ |
| Pro | 149,000đ | 1,490,000đ |
| Plus Family | 129,000đ | 1,290,000đ |
| Pro Family | 249,000đ | 2,490,000đ |

### Conversion Tactics
1. **Soft limits**: Show upgrade prompt when hitting limits
2. **Trial period**: 7-day free trial for Plus
3. **Upgrade prompts**: After 30 days of active use
4. **Value highlight**: "Unlock Premium AI" when using Standard
5. **Family upsell**: "Share with family" prompt when adding multiple wallets

---

## Success Metrics

### Target KPIs
- Free to Plus conversion: 3-5%
- Plus to Pro conversion: 10-15%
- Plus to Family conversion: 5-10%
- Monthly churn rate: <5%

### Milestones
- 100 paid users: Cover development costs
- 500 paid users: Part-time sustainable
- 2000 paid users: Full-time sustainable

---

## Privacy & Security

- Cloud data encrypted at rest and in transit
- GDPR/CCPA compliant
- User owns and controls their data
- Export/delete at any time
- Ad tracking can be disabled (limited ads still shown)
- Family data isolated per family group
- Members only see shared wallets, not personal data
