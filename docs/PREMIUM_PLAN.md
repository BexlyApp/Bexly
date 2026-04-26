# Bexly Subscription Plans

## Overview

Bexly uses a 3-tier freemium model. Subscriptions are billed centrally through
DOS.Me — one DOS.Me subscription unlocks the corresponding tier across every
DOS product (Bexly, DOSafe, DOS.AI, etc.). Users can also subscribe directly
inside the Bexly app via Google Play Billing or App Store IAP; either path
syncs back to the user's DOS.Me account.

---

## Tier Structure

| Tier | DOS.Me equivalent | Price (USD) | Price (VND) |
|------|-------------------|-------------|-------------|
| **Free** | DOS.Me Free | $0 | 0đ |
| **Go** | DOS.Me Go | $1.99/mo · $19.99/yr | 49,000đ/mo · 490,000đ/yr |
| **Premium** | DOS.Me Plus | $5/mo · $25/yr | 125,000đ/mo · 625,000đ/yr |

Yearly Go saves ~17% (≈ 2 months free). Yearly Premium saves ~58% — the deep
discount is intentional to drive annual commitment on the flagship plan.

---

## Feature Matrix

| Feature | Free | Go | Premium |
|---------|------|------|---------|
| **Core** | | | |
| Wallets | 3 | Unlimited | Unlimited |
| Budgets / Goals (each) | 2 | Unlimited | Unlimited |
| Recurring transactions | 5 | Unlimited | Unlimited |
| Analytics history | 3 months | 6 months | 2 years |
| Cloud sync | Basic | Full | Full |
| Ads | Yes | No | No |
| **AI** | | | |
| AI messages / month | 60 | 240 | 600 |
| AI insights & predictions | ❌ | ❌ | ✅ |
| **Receipt** | | | |
| OCR scan | ❌ | ✅ | ✅ |
| Photo retention | ❌ | 1 year auto-delete | 3 years auto-delete |
| **Family Sharing** | | | |
| Members (incl. owner) | 2 | 2 | 5 |
| Editor role | ❌ (Viewer only) | ✅ | ✅ |
| Shared wallets | 1 | Unlimited | Unlimited |
| **Support** | | | |
| Priority support | ❌ | ❌ | ✅ |

### Notes on AI

- All tiers use the same default AI model. Bexly does not expose model
  selection to the user — keeps UX simple and lets us upgrade the underlying
  model without breaking expectations.
- The 600/month cap on Premium is a soft anti-abuse cap, not a target. Most
  users land at 50-150 messages/month. The cap stops "use AI to write poetry"
  scenarios that would burn provider quota disproportionately.
- AI insights & predictions (Premium only) are proactive notifications:
  spending anomalies, budget-burn forecasts, savings opportunities.

### Notes on receipt retention

- Auto-delete runs as a background job. Users do not need a "manage storage"
  UI — old photos disappear quietly past the retention window.
- 1 year for Go and 3 years for Premium align with typical personal
  bookkeeping needs; users who must keep receipts longer (e.g. tax records
  in jurisdictions requiring 5+ years) should export to their own storage.

### Notes on Family Sharing

- Free and Go both support 2 members. The difference is role: Free is
  Viewer-only, Go unlocks Editor. This makes Go meaningful for couples who
  both want to log transactions.
- Premium expands to 5 members for households or multi-generational families.
- All shared wallets sync via Supabase realtime; Family is gated by tier
  but uses the same sync stack.

---

## Cross-product Subscription Model

DOS.Me is the source of truth for billing. Each product reads the user's
DOS.Me tier and maps it to its own feature set:

| User's DOS.Me tier | Bexly tier | DOSafe tier (example) | DOS.AI tier (example) |
|--------------------|------------|----------------------|----------------------|
| Free | Free | Basic | Free |
| Go | Go | Pro | Plus |
| Plus | Premium | Enterprise | Pro |

A single DOS.Me Go or Plus subscription covers every DOS product the user
opens — they never see a "buy again" prompt in a sister app.

### Purchase paths

1. **Bexly in-app (Google Play / App Store IAP)** — user buys
   `bexly_go_monthly` / `bexly_premium_monthly` etc. The receipt is
   verified server-side, then DOS.Me is updated to reflect the user's tier.
2. **DOS.Me web (https://app.dos.ai/billing/plans)** — user buys directly
   from DOS.Me. Bexly receives the tier via DOS.Me API on next sync.

Both paths land at the same place — the user's DOS.Me account holds the
canonical subscription state, and Bexly reads from there.

---

## Product IDs (Google Play & App Store)

| Plan | Product ID | Price (USD) |
|------|------------|-------------|
| Go Monthly | `bexly_go_monthly` | $1.99/month |
| Go Yearly | `bexly_go_yearly` | $19.99/year |
| Premium Monthly | `bexly_premium_monthly` | $5/month |
| Premium Yearly | `bexly_premium_yearly` | $25/year |

**Subscription Group:** `Bexly Subscriptions` (App Store)

---

## Implementation Reference

The canonical feature limits live in
[`lib/core/services/subscription/subscription_tier.dart`](../lib/core/services/subscription/subscription_tier.dart).
This document and that file must stay in sync; if you change one, change the
other in the same commit.

### Feature gating pattern

```dart
final limits = ref.watch(subscriptionLimitsProvider);

// Hard limit example
if (!limits.isWithinLimit(currentWalletCount, limits.maxWallets)) {
  showUpgradePrompt(context, requiredTier: SubscriptionTier.go);
  return;
}

// Boolean feature example
if (limits.allowReceiptOCR) {
  showOcrButton();
}
```

### Verification

- IAP receipts: validated via the App Store / Google Play APIs in a
  Supabase Edge Function before tier is upgraded in DOS.Me.
- DOS.Me tier sync: pulled on app start and on Supabase auth state change.
- Grace period: 7 days for expired payments before downgrade.

---

## Conversion Strategy

- **Soft limits**: when a free user hits 3 wallets / 2 budgets / 60 AI
  messages, show inline upgrade prompt (not a modal blocker).
- **Free trial**: 7-day Premium trial unlocked after first 30 days of
  active use, one trial per DOS.Me account.
- **Yearly nudge**: when a user has been on monthly Go/Premium for 90 days,
  surface a "switch to yearly" banner highlighting savings.

### Target KPIs

- Free → Go conversion: 5-8%
- Go → Premium conversion: 10-15%
- Monthly churn (any tier): <5%
- Yearly mix of paid users: >40%
