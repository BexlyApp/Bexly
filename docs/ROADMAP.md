# Bexly Development Roadmap

> Last updated: 2026-03-15 | Current version: v0.0.10+545

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

### 3.3 Open Banking API
**Priority: LOW | Platform: All**

- Vietnam: Thông tư 64/2024 (effective 01/03/2025, banks must comply by 01/03/2027)
- International: Plaid (US/CA/UK/EU), Salt Edge (50+ countries)
- Transaction history sync, balance inquiries
- Wait for VN banks to publish APIs

### 3.4 Apple FinanceKit
**Priority: LOW | Platform: iOS only (US)**

- iOS 17.4+ only, Apple Card/Cash transactions
- Wait for wider adoption and mature Flutter package

---

## Phase 4: Monetization (Q3 2026)

### Pricing Strategy
**Freemium model** — core features free, premium for power users

| Feature | Free | Premium ($2.99/mo) | Pro ($5.99/mo) |
|---------|------|---------------------|-----------------|
| Wallets | 2 | Unlimited | Unlimited |
| Budgets/Goals | 2 each | Unlimited | Unlimited |
| Recurring | 2 | Unlimited | Unlimited |
| Currency | 1 only | Multi-currency | Multi-currency |
| AI Messages | 30/month | 50/month | Unlimited |
| Analytics | 2 months | 6 months | All history |
| Cloud Sync | ❌ | ✅ Supabase sync | ✅ Supabase sync |
| Receipt OCR | ❌ | ✅ | ✅ |
| Receipt Storage | ❌ | 1GB | Unlimited |
| Support | Community | Email | Priority |

### Implementation
1. RevenueCat integration for subscription management
2. Feature gating via `SubscriptionService`
3. Google Drive backup for free tier (weekly auto-backup)
4. AI message usage tracking (reset monthly)
5. Soft paywall with 7-day free trial

### Revenue Projections (Year 1)
- Conservative: 10K users, 5% Premium, 10% Pro → MRR ~$1,800
- Optimistic: 50K users, 10% Premium, 15% Pro → MRR ~$19,400
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
| AI (primary) | DOS AI (`api.dos.ai`) | Qwen3.5-35B-A3B, vision built-in |
| AI (fallback) | Gemini via Supabase Edge Function proxy | Server-side API keys |
| AI (optional) | OpenAI, Claude via proxy | Same proxy architecture |
| OAuth Tokens | dos.me ID API (`api.dos.me`) | Centralized token management |
| Analytics | Firebase Analytics + Crashlytics | Crash reporting |
| Push | Firebase Cloud Messaging | Recurring reminders |
| Storage | Firebase Storage | Avatar uploads |
| CI/CD | GitHub Actions | Android, iOS, Web, macOS, Linux builds |
