# Bexly Development Roadmap

> Last updated: 2026-04-27 | Current version: v0.0.10+585

## Current State

### Core Features (DONE)
- ✅ Expense/income tracking with multi-wallet support
- ✅ Budget management (one-time, weekly, monthly auto-renewal)
- ✅ Goals/savings tracking
- ✅ Category organization with subcategories
- ✅ Recurring payments (auto-create, WorkManager, push notifications, duplicate prevention)
- ✅ Basic analytics (weekly + 6-month trends, pie charts, currency conversion)
- ✅ Offline-first with Drift/SQLite
- ✅ Dark/light mode with flex_color_scheme

### Cloud & Auth (DONE)
- ✅ Supabase bidirectional sync (wallets, categories, transactions, budgets, recurring, goals)
- ✅ Soft delete pattern for cloud sync
- ✅ CloudId-based sync architecture (UUID v7)
- ✅ Google Sign In (Android + iOS)
- ✅ Apple Sign In (iOS)
- ✅ Facebook Sign In (via DOS Facebook App)
- ✅ Privacy consent dialog (GDPR)
- ✅ Onboarding flow

### AI Features (DONE)
- ✅ AI Chat assistant with multi-provider support (DOS AI, Gemini, OpenAI, Claude)
- ✅ Natural language transaction creation (expense, income, recurring, budget, goal)
- ✅ Receipt/invoice OCR scanning (DOS AI vision → Gemini fallback)
- ✅ SMS transaction parsing (Android)
- ✅ Bank SMS auto-detection with pending queue
- ✅ Multi-language AI (14 languages)
- ✅ Safety net for recurring detection + VND amount sanity check
- ✅ Voice input support

### Bots & Integrations (DONE)
- ✅ Telegram Bot (create transactions via chat)
- ✅ Facebook Messenger Bot
- ✅ AI proxy via Supabase Edge Functions (server-side API keys)

### Platform & Distribution (DONE)
- ✅ Android (Play Store beta)
- ✅ iOS (TestFlight via GitHub Actions CI/CD)
- ✅ Web (bexly.app — Flutter Web with SEO, OG tags, sitemap)
- ✅ Localization: flutter gen-l10n with 14 languages (.arb files)

---

## Phase 1: Polish & Stability (Q1 2026) 🔥 CURRENT

### 1.1 AI Reliability Improvements
**Priority: HIGH | Status: ✅ MOSTLY DONE**

- ✅ DOS AI vision OCR with 30s timeout (separate from 5s text timeout)
- ✅ Gemini fallback when DOS AI fails
- ✅ Safety net: auto-upgrade to create_recurring when user mentions frequency keywords
- ✅ VND amount sanity check (re-parse from user message when LLM is >100x off)
- ✅ Image analyzing indicator shown immediately
- 🔜 Banking screenshot OCR (multi-transaction extraction from app screenshots)
- 🔜 Improve DOS AI prompt compliance for edge cases

### 1.2 Test Coverage
**Priority: MEDIUM | Status: 📋 PLANNED**

- Current coverage: minimal
- Target: 60%+ for core business logic (DAOs, sync service, AI action handlers)
- Focus: unit tests for amount parsing, recurring detection, currency conversion

### 1.3 Performance
**Priority: LOW | Status: 📋 PLANNED**

- Supabase sync optimization (incremental sync when >3000 transactions)
- Batch operations for bulk inserts
- Lazy loading for transaction history

---

## Phase 2: Analytics & Insights (Q2 2026)

### 2.1 Subscription Analytics
**Priority: MEDIUM**

- Total monthly/yearly subscription cost dashboard
- Cost per category (entertainment/work/utilities)
- Unused subscription detection
- Price increase alerts

### 2.2 Bill Calendar
**Priority: MEDIUM**

- Calendar view of upcoming bills/recurring payments
- Color-coded by category
- Payment status indicators

### 2.3 Custom Reports & Export
**Priority: MEDIUM**

- PDF/CSV export for transactions
- Custom date range reports
- Tax report preparation
- Monthly spending recap

### 2.4 Predictive Analytics
**Priority: LOW**

- Spending forecasts based on history
- Cash flow predictions
- Budget overrun warnings
- Financial health score

---

## Phase 3: Automated Transaction Input (Q2-Q3 2026)

### 3.1 Notification Listener Service
**Priority: HIGH | Platform: Android**

- Listen to push notifications from banking apps
- Parse notification content with AI
- Auto-create pending transactions
- Pros over SMS: works with e-wallets (Momo, ZaloPay), no SMS permission needed

### 3.2 Email Transaction Sync
**Priority: MEDIUM | Platform: All**

- Gmail OAuth (read-only) to scan banking emails
- AI-powered email parsing (Gemini)
- Historical import from past emails
- Works cross-platform (iOS, Android, Web)
- Supabase Edge Function for scheduled scanning

### 3.3 Open Banking via Tingee (Vietnam) 🔥
**Priority: HIGH | Platform: All | Spec: [docs/plans/2026-04-27-tingee-open-banking.md](plans/2026-04-27-tingee-open-banking.md)**

Vietnam's Thông tư 64/2024 mandates Open Banking at all VN banks by
2027-03-01, but rather than waiting, Bexly will integrate **[Tingee](https://developers.tingee.vn)**
as an aggregator (the VN equivalent of Plaid). Partner credentials already
secured.

- **Phase A (MVP, ~3 weeks)** — read-only: link bank account, real-time
  transaction notifications via webhook, surface in existing
  `pending_transactions` queue for AI categorization + user confirm.
- **Phase B (~2 weeks)** — Pay-by-Bank for recurring bills via VietQR / deep link.
- **Phase C (~3 weeks)** — Direct Debit (highest trust tier; legal review required).

Architecture: Tingee → Supabase Edge Function (`tingee-webhook`) → HMAC
verify → `bexly.tingee_transactions` table → Realtime → client. Secret
key stays server-side; client only reads via Supabase Realtime.

Tier gating: Free 1 account, Go 3 accounts, Premium unlimited + Direct Debit.

International (Plaid, Salt Edge) deferred — focus on VN market first.

### 3.4 Apple FinanceKit
**Priority: LOW | Platform: iOS only (US)**

- iOS 17.4+ only, Apple Card/Cash transactions
- Wait for wider adoption and mature Flutter package

---

## Phase 4: Monetization (Q3 2026)

**Canonical pricing**: see [`docs/PREMIUM_PLAN.md`](PREMIUM_PLAN.md) — 3 tiers
(Free / Go $1.99 / Premium $5), billed centrally via DOS.Me with in-app
IAP fallback. Per-product quota tracked through DOS.AI Gateway (see
[`docs/plans/2026-04-22-bexly-quota-schema.md`](plans/2026-04-22-bexly-quota-schema.md)).

### Implementation status
- ✅ Tier definitions in `lib/core/services/subscription/subscription_tier.dart`
- ✅ Product IDs registered in `subscription_products.dart`
- 📋 Google Play / App Store IAP products created (manual step in console)
- 📋 IAP receipt verification via Supabase Edge Function
- 📋 DOS.Me tier sync on auth + every app start
- 📋 Quota counter wired to `bexly.usage_counters` (waiting on DOS.AI Gateway)
- 📋 Soft paywall + 7-day Premium trial after 30 days active use

### Revenue Projections (Year 1)
- Conservative: 10K users, 5% Go, 2% Premium → MRR ~$1,500
- Optimistic: 50K users, 8% Go, 4% Premium → MRR ~$17,950
- Gross margin: ~85% (AI costs ~$0.03/free user/month)

---

## Phase 5: Gamification (Q3-Q4 2026)

### 5.1 Achievement System
- Badges: First Steps, Saver, Streak Master, Budget Pro, Goal Crusher, AI Friend, Receipt Collector
- Unlock rewards: custom themes, special app icons, early access

### 5.2 Streak & Daily Check-in
- Daily streak counter (Duolingo-style)
- Streak freeze, weekly recap with celebration animation
- Push notification reminders

### 5.3 XP & Levels
- +10 XP per transaction, +50 XP daily goal, +500 XP savings goal
- Level 1-100: Newbie → Legend
- Level benefits: unlock themes, analytics, custom icons

### 5.4 Challenges & Leaderboards
- Weekly challenges ("No Eating Out Week", "Save $50")
- Anonymous leaderboards (savings rate, streak, transactions)
- Virtual currency "Bexly Coins" for in-app shop

---

## Phase 6: Platform Expansion (Q4 2026)

### 6.1 Desktop Applications
- Windows, macOS, Linux via Flutter Desktop
- Responsive design, bulk operations
- System tray integration

### 6.2 Wearable Integration
- Apple Watch, Wear OS
- Quick expense entry, spending alerts, budget status

---

## Phase 7: Social & Collaboration (2027+)

### 7.1 Family Sharing
- Shared wallets, family budgets, child accounts with limits

### 7.2 Bill Splitting
- Group expense tracking, split by percentage/amount, settlement tracking

### 7.3 Shared Financial Goals
- Progress visualization, milestone celebrations, social accountability

---

## Technical Debt & Ongoing

### Infrastructure
- ⏳ Increase test coverage to 60%+
- ⏳ Supabase sync performance optimization (when needed)
- ⏳ Security audits
- ✅ L10n migration to flutter gen-l10n (14 languages)
- ✅ Migrate from Firestore → Supabase (completed)
- ✅ Firebase Functions removed (Telegram bot + all webhooks moved to Supabase Edge Functions)
- ✅ `.env` no longer bundled into APK; switched to `--dart-define-from-file` (security: April 2026)
- 📋 Force-update gate for old APKs that still ship leaked keys

### Known Issues
- Health category icon mapping (Dental and Fitness share same icon)
- `flutter build appbundle` warning about debug symbols (cosmetic, not a real error)

---

## Backend Architecture Reference

| Component | Technology | Notes |
|-----------|-----------|-------|
| Auth | Supabase (dos.me ID) | Google, Apple, Facebook Sign In |
| Local DB | Drift/SQLite | Source of truth for offline |
| Cloud Sync | Supabase PostgreSQL (schema `bexly`) | Bidirectional sync |
| AI gateway | DOS.AI Gateway (in progress) | JWT auth, per-product quota, routes to Qwen / Gemini / Claude |
| AI (primary model) | DOS AI Qwen3.5-35B-A3B | vision built-in, served via gateway |
| AI (fallback) | Gemini, OpenAI, Claude via gateway | Keys stay server-side |
| OAuth Tokens | dos.me ID API (`api.dos.me`) | Centralized token management |
| Open Banking (VN) | Tingee aggregator (Q2-Q3 2026) | Webhook + HMAC signed, see Phase 3.3 |
| Subscription billing | DOS.Me central + Google Play / App Store IAP | Tier sync via DOS.Me API |
| Analytics | Firebase Analytics + Crashlytics + Performance | |
| Push (receive only) | Firebase Cloud Messaging | Server-side delivery TBD; no fcm_tokens table yet |
| Telegram + Stripe webhooks | Supabase Edge Functions | All migrated off Firebase Functions |
| Storage | Firebase Storage | Avatar uploads |
| CI/CD | GitHub Actions | Android, iOS, Web, macOS, Linux builds |
