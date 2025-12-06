# Bexly Premium Plan

## Overview
Bexly operates on a freemium model with cloud sync support. Free users get core functionality with ads. Premium users get more features, better AI, and ad-free experience.

## Tier Structure

### Free Tier
**Price:** $0 forever

**Features:**
- 3 wallets
- 2 budgets & 2 goals
- 5 recurring transactions
- 3 months analytics history
- 20 AI messages/month (Standard model)
- Cloud sync (basic)
- Manual export/import (JSON/CSV)

**Limitations:**
- Contains ads
- No receipt photo storage
- Limited AI capabilities

---

### Plus Tier
**Price:** $2.99/month or $29.99/year (2 months free)

**Everything in Free, plus:**
- Unlimited wallets
- Unlimited budgets & goals
- Unlimited recurring transactions
- 6 months analytics history
- 60 AI messages/month (Premium model)
- Receipt photo storage (1GB)
- **No ads**

---

### Pro Tier
**Price:** $5.99/month or $59.99/year (2 months free)

**Everything in Plus, plus:**
- Full analytics history (unlimited)
- Unlimited AI messages (Flagship model)
- Receipt photo storage (5GB)
- AI insights & predictions
- Priority support
- Early access to new features

---

## AI Model Tiers

| Tier | Model Name | Description |
|------|------------|-------------|
| Standard | TBD | Basic AI for simple tasks |
| Premium | TBD | Better AI with improved accuracy |
| Flagship | TBD | Best AI with advanced capabilities |

*Specific models will be defined based on cost/performance analysis.*

---

## Feature Comparison

| Feature | Free | Plus | Pro |
|---------|------|------|-----|
| Wallets | 3 | Unlimited | Unlimited |
| Budgets & Goals | 2 each | Unlimited | Unlimited |
| Recurring transactions | 5 | Unlimited | Unlimited |
| Analytics history | 3 months | 6 months | Unlimited |
| AI messages/month | 20 | 60 | Unlimited |
| AI model | Standard | Premium | Flagship |
| Receipt photos | - | 1GB | 5GB |
| Cloud sync | Basic | Full | Full |
| Ads | Yes | No | No |
| Priority support | - | - | Yes |

---

## Technical Implementation

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

bool canUseAI() {
  if (subscription.isPro) return true;
  return aiMessagesUsed < subscription.aiLimit;
}

String getAIModel() {
  switch (subscription.tier) {
    case Tier.pro: return 'flagship';
    case Tier.plus: return 'premium';
    default: return 'standard';
  }
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

### Conversion Tactics
1. **Soft limits**: Show upgrade prompt when hitting limits
2. **Trial period**: 7-day free trial for Plus
3. **Upgrade prompts**: After 30 days of active use
4. **Value highlight**: "Unlock Premium AI" when using Standard

---

## Success Metrics

### Target KPIs
- Free to Plus conversion: 3-5%
- Plus to Pro conversion: 10-15%
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
