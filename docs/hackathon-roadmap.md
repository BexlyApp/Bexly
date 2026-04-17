# Hackathon Roadmap — Qwen AI Build Day x Shinhan Bank [SB1]

**Use Case:** AI Personal Financial Coach
**Hackathon:** https://qwen-ai-build-day.devpost.com/
**Target:** Shinhan Bank Vietnam — SOL App

---

## SB1 Expected Outcomes Mapping

| # | Expected Outcome | What it really means | Covered By |
|---|---|---|---|
| 1 | Increase DAU/MAU on SOL app | Build features that make users **want to open the app daily** — engagement, retention, habit formation | Daily AI insights, gamification streaks, proactive push notifications |
| 2 | Improve cross-sell conversion (cards, loans, insurance) | AI detects spending patterns → recommends relevant Shinhan products → user **applies/opens account directly in-app** | Product Recommendation + Banking Action engine |
| 3 | Reduce churn through proactive financial insights | AI reaches out **before** user asks — spending anomalies, budget warnings, personalized tips | Proactive AI Coach + Spending Alerts |
| 4 | Enhance NPS/CSAT via personalized guidance | Users feel the AI **understands them** personally, gives advice tailored to their situation | Financial Coach persona + NPS survey |
| 5 | Grow CASA balance through savings recommendations | Keep money **inside Shinhan** — AI identifies idle cash, recommends savings accounts, auto-sweeps surplus | Auto-Suggest Savings + Open Savings Account action |

> **CASA** = Current Account + Savings Account. Banks want to grow CASA because it's cheap funding (low interest paid). AI coach helps by: analyze spending → identify savings potential → recommend opening Shinhan savings account → money stays in Shinhan.

---

## P0 — Must Have (covers all 5 SB1 outcomes)

- [x] **Upgrade system prompt to Financial Coach persona** ✅
  - File: `lib/features/ai_chat/data/config/ai_prompts.dart`
  - Implemented: proactive coaching tone, spending habit analysis, savings advice, financial health tips
  - AI proactively comments on spending patterns after recording transactions
  - Covers: #1 DAU/MAU (engaging interactions), #3 churn (proactive), #4 NPS (personalized)

- [x] **AI Spending Insights in chat** ✅
  - File: `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` (spending context injection)
  - Implemented: monthly overview, category breakdown, budget status, wallet balance, savings potential injected into AI context
  - AI compares current vs previous month, surfaces category changes and budget adherence
  - Covers: #1 DAU/MAU (reason to check daily), #3 churn (insights keep users engaged)

- [x] **Product Recommendation + Banking Actions via AI** ✅
  - File: `lib/features/ai_chat/data/config/shinhan_products.dart` (6-product Shinhan catalog)
  - File: `chat_provider.dart` — banking action handlers with confirmation dialogs
  - Implemented: `open_savings_account`, `apply_credit_card`, `apply_loan`, `transfer_to_savings`
  - Recommendation rules: dining → cashback card, idle balance → savings, no insurance → insurance product, FX spend → FX card
  - Covers: #2 cross-sell (recommend + execute), #5 CASA (open savings in-app)

- [x] **Auto-Suggest Savings Plan + CASA Growth** ✅
  - File: `ai_prompts.dart` — proactive savings suggestions with interest calculations
  - AI calculates savings_potential and suggests: "You have 5M idle → open 6-month savings at 5.5%"
  - Links to `open_savings_account` action — user confirms → account opens
  - Covers: #5 CASA (direct savings growth), #1 DAU/MAU (actionable value)

---

## P1 — Should Have (stronger demo, better judges impression)

- [x] **Daily Financial Digest Push Notification** ✅
  - File: `lib/core/services/daily_digest_service.dart`
  - Implemented: scheduled daily at 8 AM, personalized spending summary, debounced to once per day
  - User taps notification → lands in AI chat
  - Covers: #1 DAU/MAU (daily re-engagement), #3 churn (proactive outreach)

- [x] **Spending Anomaly Alert** ✅
  - File: `lib/core/services/spending_anomaly_service.dart`
  - Implemented: detects anomalies using 3x rolling 30-day category average or 50% daily spend threshold
  - Push notification with context-aware message
  - Covers: #3 churn (proactive), #4 NPS (feels like the app watches out for you)

- [x] **Financial Health Score (0-100)** ✅
  - File: `lib/features/dashboard/presentation/riverpod/financial_health_provider.dart`
  - Implemented: 0-100 score with grade (A+/A/B+/B/C+/C/D/F) from savings rate, budget adherence, expense trend, goal progress
  - Displayed on dashboard, AI references score in conversations
  - Covers: #1 DAU/MAU (track score daily), #4 NPS (tangible value)

- [x] **In-app NPS/CSAT Survey** ✅
  - File: `lib/features/ai_chat/presentation/widgets/nps_survey_bottom_sheet.dart`
  - Implemented: 1-5 star rating shown every 10 AI interactions with optional text feedback
  - Uses `showModalBottomSheet` (per UI rules)
  - Covers: #4 NPS/CSAT (direct measurement)

---

## P2 — Nice to Have (bonus points if time permits)

- [x] **Churn Prevention — Re-engagement Notification** ✅
  - File: `lib/core/services/churn_prevention_service.dart`
  - Implemented: tracks app opens, maintains daily streaks, schedules re-engagement at 3+ day inactivity
  - Covers: #1 DAU/MAU, #3 churn

- [x] **Spending Forecast** ✅
  - File: `lib/features/dashboard/presentation/riverpod/spending_forecast_provider.dart`
  - Implemented: end-of-month projection based on daily burn rate and velocity
  - AI references forecast in conversations

- [ ] **Peer Benchmarking (Mock)**
  - "You spend 20% more on dining than similar users in HCMC"
  - Mock anonymized aggregate data for demo
  - Effort: Medium

- [x] **Recurring Payment Optimization** ✅
  - File: `ai_prompts.dart` — prompt guidance for detecting overlaps, bundling, and high recurring-to-income ratios
  - AI proactively suggests optimization when recurring charges are detected

---

## Submission Checklist

### Demo Video (2-3 min)
- [ ] AI chat creating transactions via natural language (Vietnamese)
- [ ] AI proactively coaching: "You've spent a lot on dining — here's a tip"
- [ ] AI analyzing spending: compare months, category breakdown
- [ ] AI recommending Shinhan product based on spending pattern
- [ ] AI suggesting savings plan + opening savings account (mock banking action)
- [ ] Receipt OCR: snap photo → auto-extract transaction
- [ ] Voice input in Vietnamese
- [ ] Multi-language switch (Vietnamese ↔ English)
- [ ] Push notification with personalized financial digest

### Devpost
- [x] Project story (`docs/hackathon-about.md`) ✅
- [x] Elevator pitch ✅
- [ ] Screenshots / images (at least 4-5 screens)
- [x] GitHub repo link (secrets purged, history clean) ✅
- [x] Tech stack: Qwen 3.5, vLLM, Flutter, Supabase — all open-source ✅
- [x] Use case [SB1] clearly referenced ✅
- [x] Link to live web app: https://app.bexly.app ✅

### Code
- [x] Repo clean for sharing (secrets purged, history rewritten) ✅
- [ ] `.env.example` updated with all required env vars
- [x] README updated with AI-first branding and cross-platform positioning ✅

---

## Tech Architecture for Hackathon

```
User (SOL App / Bexly)
    │
    ├── Natural language input (text / voice / image)
    │
    ▼
Flutter App (Riverpod + Hooks)
    │
    ├── Chat Provider (action protocol + context injection)
    │   ├── Spending data from FinancialHealthRepository
    │   ├── Budget status from BudgetDao
    │   ├── Wallet balances from WalletDao
    │   └── Shinhan product catalog
    │
    ▼
Qwen 3.5 (35B-A3B) via vLLM — api.dos.ai
    │
    ├── Financial coaching response
    ├── ACTION_JSON: create_expense, create_budget, open_savings_account...
    └── Product recommendation with reasoning
    │
    ▼
Action Executor (chat_provider.dart)
    │
    ├── Local DB (Drift/SQLite) — record transaction, create budget/goal
    ├── Cloud Sync (Supabase) — bidirectional sync
    └── Mock Banking API — open account, apply card (hackathon demo)
```

**Qwen is the brain** — all financial reasoning, coaching, recommendations, and action decisions run through Qwen. The app provides context (spending data, balances, products) and executes Qwen's decisions.
