# Bexly Premium Plan

## Overview
Bexly operates on a freemium model with cloud sync support. Free users get core functionality with ads. Premium users get more features, better AI, ad-free experience, and enhanced family sharing.

## Tier Structure

### Free Tier
**Price:** $0 forever

**Features:**
- 3 wallets
- 2 budgets & 2 goals
- 5 recurring transactions
- 3 months analytics history
- 60 AI messages/month
- Cloud sync (basic)
- Manual export/import (JSON/CSV)
- Family sharing (2 members, 2 shared wallets, viewer-only)

**Limitations:**
- Contains ads
- No receipt photo storage

---

### Plus Tier
**Price:** $1.99/month or $19.99/year (2 months free)

**Everything in Free, plus:**
- Unlimited wallets
- Unlimited budgets & goals
- Unlimited recurring transactions
- 6 months analytics history
- 240 AI messages/month
- Scan & store receipts (1 year retention)
- **Family sharing (3 members, 5 shared wallets)**
- Priority support
- **No ads**

---

### Pro Tier
**Price:** $3.99/month or $39.99/year (2 months free)

**Everything in Plus, plus:**
- Full analytics history (unlimited)
- **Unlimited** AI messages
- Scan & store receipts (3 years retention)
- **Family sharing (5 members, unlimited shared wallets, Editor role)**
- AI insights & predictions

---

## AI Quota

| Tier | AI Messages |
|------|-------------|
| Free | 60/month |
| Plus | 240/month |
| Pro | **Unlimited** |

*AI models are managed internally and may be upgraded over time.*

---

## Feature Comparison

| Feature | Free | Plus | Pro |
|---------|------|------|-----|
| **Price** | $0 | $1.99/mo ($19.99/yr) | $3.99/mo ($39.99/yr) |
| **Price (VND)** | 0đ | 49k/tháng (490k/năm) | 99k/tháng (990k/năm) |
| | | | |
| **Core Features** | | | |
| Wallets | 3 | Unlimited | Unlimited |
| Budgets & Goals | 2 each | Unlimited | Unlimited |
| Recurring transactions | 5 | Unlimited | Unlimited |
| Analytics history | 3 months | 6 months | Unlimited |
| Cloud sync | Basic | Full | Full |
| Ads | Yes | No | No |
| | | | |
| **AI Assistant** | | | |
| AI messages | 60/month | 240/month | **Unlimited** |
| AI insights & predictions | - | - | Yes |
| | | | |
| **Receipt** | | | |
| Scan receipt (OCR) | - | Yes | Yes |
| Receipt storage | - | 1 year | 3 years |
| | | | |
| **Family Sharing** | | | |
| Family members | 2 | 3 | **5** |
| Shared wallets | 2 | 5 | **Unlimited** |
| Editor role | - | - | Yes |
| | | | |
| **Email Sync** | | | |
| Email accounts | - | 1 | 3 |
| Scan period | - | 30 days | All time |
| | | | |
| **Support** | | | |
| Priority support | - | Yes | Yes |

---

## Email Sync Feature

Automatically scan and import transactions from banking emails.

### Email Sync Limits by Tier
| Feature | Free | Plus | Pro |
|---------|------|------|-----|
| Email accounts | - | 1 | 3 |
| Auto-sync | - | ✅ | ✅ |
| Manual sync | - | ✅ | ✅ |
| Scan period | - | 30 days | All time |

### Scan Period Options
- **Last 7 days**: Quick scan for recent transactions
- **Last 30 days**: Default for Plus tier
- **Last 90 days**: Extended scan
- **All time**: Full inbox scan (Pro only)

---

## Family Sharing Features

**All tiers have access to Family Sharing with different limits!**

### Family Limits by Tier
| Limit | Free | Plus | Pro |
|-------|------|------|-----|
| Max members | 2 | 3 | **5** |
| Shared wallets | 2 | 5 | **Unlimited** |
| Available roles | Owner, Viewer | Owner, Viewer | Owner, Editor, Viewer |
| Can create family | ✅ | ✅ | ✅ |
| Can invite members | ✅ | ✅ | ✅ |

### Member Roles
| Role | Permissions | Available in |
|------|-------------|--------------|
| **Owner** | Full control - invite/remove members, share/unshare wallets, CRUD all transactions | All tiers |
| **Editor** | Can share wallets, create/edit/delete transactions | Pro only |
| **Viewer** | Read-only access to shared wallets | All tiers |

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
| Plus Monthly | `bexly_plus_monthly` | $1.99/month | 49,000đ/tháng |
| Plus Yearly | `bexly_plus_yearly` | $19.99/year | 490,000đ/năm |
| Pro Monthly | `bexly_pro_monthly` | $3.99/month | 99,000đ/tháng |
| Pro Yearly | `bexly_pro_yearly` | $39.99/year | 990,000đ/năm |

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

bool canUseAI() {
  final usage = getAIUsage();
  // Pro = unlimited, Plus = 240, Free = 60
  if (subscription.isPro) return true; // Unlimited
  final limit = subscription.isPlus ? 240 : 60;
  return usage.messages < limit;
}

// All tiers can use family, but with different limits
int getMaxFamilyMembers() {
  if (subscription.isPro) return 5;
  if (subscription.isPlus) return 3;
  return 2; // Free
}

int getMaxSharedWallets() {
  if (subscription.isPro) return -1; // Unlimited
  if (subscription.isPlus) return 5;
  return 2; // Free
}

bool canUseEditorRole() {
  return subscription.isPro;
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
| Plus | 49,000đ | 490,000đ |
| Pro | 99,000đ | 990,000đ |

### Conversion Tactics
1. **Soft limits**: Show upgrade prompt when hitting limits
2. **Trial period**: 7-day free trial for Plus
3. **Upgrade prompts**: After 30 days of active use
4. **Value highlight**: "Get more AI messages" when quota low
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
