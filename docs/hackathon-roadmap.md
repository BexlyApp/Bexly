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

- [ ] **Upgrade system prompt to Financial Coach persona**
  - File: `lib/features/ai_chat/data/config/ai_prompts.dart`
  - Current prompt is transactional only (record/query data)
  - Add: proactive coaching tone — don't wait for questions, offer insights
  - Add: spending habit analysis, savings advice, financial health tips
  - Add: "after recording a transaction, briefly comment on the user's spending pattern if relevant"
  - Effort: Low (prompt engineering, no new code)
  - Covers: #1 DAU/MAU (engaging interactions), #3 churn (proactive), #4 NPS (personalized)

- [ ] **AI Spending Insights in chat**
  - When user asks "analyze my spending" → compare current vs previous month
  - Surface: category changes, unusual spikes, budget adherence rate
  - Also: AI proactively mentions insights after recording transactions ("You've spent 80% of your food budget with 15 days left")
  - Data source: `FinancialHealthRepository` (already has 6-month trend, weekly breakdown, category data)
  - Need: inject previous month's category totals + current budget status into AI context
  - File: `chat_provider.dart` — extend context building before sending message
  - Effort: Medium
  - Covers: #1 DAU/MAU (reason to check daily), #3 churn (insights keep users engaged)

- [ ] **Product Recommendation + Banking Actions via AI**
  - **Catalog**: Create Shinhan product catalog (credit cards, savings accounts, loans, insurance)
  - **Recommendation rules** in system prompt:
    - High dining/shopping spend → Shinhan cashback credit card
    - Paying high credit card interest → debt consolidation loan
    - Idle balance sitting in current account → high-yield savings account
    - No insurance transactions → life/health insurance product
    - Frequent international spend → Shinhan FX savings card
  - **Banking Actions** (new action types for SOL integration):
    - `open_savings_account` — AI creates savings account via banking API
    - `apply_credit_card` — AI submits credit card application
    - `apply_loan` — AI initiates loan application
    - `transfer_to_savings` — AI sweeps idle cash to savings
  - For hackathon: mock Shinhan Banking API responses, but build the full UX flow
  - Files: new `lib/features/ai_chat/data/config/shinhan_products.dart`, update `ai_prompts.dart`, update `chat_provider.dart` action handlers
  - Effort: Medium-High
  - Covers: #2 cross-sell (recommend + execute), #5 CASA (open savings in-app)

- [ ] **Auto-Suggest Savings Plan + CASA Growth**
  - AI calculates: `monthly_income - monthly_expense = savings_potential`
  - Proactively suggests: "You have 5M idle this month → open a 6-month savings at 5.5% and earn 275k interest"
  - Links to `open_savings_account` action — user confirms → account opens
  - After creating budget/reviewing spending: "If you cut dining by 20%, you could save an extra 2M/month"
  - Data: already available via `get_summary` + wallet balances
  - Effort: Low-Medium (prompt engineering + new action handler)
  - Covers: #5 CASA (direct savings growth), #1 DAU/MAU (actionable value)

---

## P1 — Should Have (stronger demo, better judges impression)

- [ ] **Daily Financial Digest Push Notification**
  - Every evening: "Today you spent 350k. Budget remaining: 650k. Keep it up!" or "You overspent by 100k today — here's a tip to stay on track tomorrow"
  - AI-generated message, not generic template — personalized to actual spending
  - Drives daily app opens (DAU) — user taps notification → lands in AI chat
  - Infrastructure: `NotificationService` + `ScheduledNotificationsService` already exist (daily 9PM slot)
  - Need: replace generic reminder with AI-generated personalized digest
  - Effort: Medium
  - Covers: #1 DAU/MAU (daily re-engagement), #3 churn (proactive outreach)

- [ ] **Spending Anomaly Alert**
  - Trigger: category spend increases >30% vs previous month, or single large transaction
  - Push notification: "Your dining spend is 40% higher than last month — want to set a budget?"
  - Tap → AI chat with context pre-loaded
  - Need: new `SpendingAnalysisService` that runs after each transaction
  - Effort: Medium
  - Covers: #3 churn (proactive), #4 NPS (feels like the app watches out for you)

- [ ] **Financial Health Score (0-100)**
  - Formula: savings_rate (30%) + budget_adherence (25%) + expense_stability (20%) + debt_ratio (15%) + goal_progress (10%)
  - Display on dashboard as circular progress with color gradient
  - AI references score in conversations: "Your financial health is 72 — let's get it above 80 by reducing subscriptions"
  - Gamification: achievements for hitting score milestones
  - Effort: Medium
  - Covers: #1 DAU/MAU (track score daily), #4 NPS (tangible value)

- [ ] **In-app NPS/CSAT Survey**
  - Bottom sheet after every 10 AI interactions: "How helpful was this advice?" (1-5 stars)
  - Optional text feedback
  - Store in local DB + sync to Supabase for analytics
  - Use `showModalBottomSheet` (per UI rules — no AlertDialog)
  - Effort: Low
  - Covers: #4 NPS/CSAT (direct measurement)

---

## P2 — Nice to Have (bonus points if time permits)

- [ ] **Churn Prevention — Re-engagement Notification**
  - If user hasn't opened app in 3+ days → push: "You have 3 upcoming bills this week — check your cash flow"
  - 7+ days → push with financial tip + reminder of unreviewed transactions
  - Use WorkManager scheduled task
  - Effort: Low
  - Covers: #1 DAU/MAU, #3 churn

- [ ] **Spending Forecast**
  - Predict end-of-month balance based on current spending velocity
  - "At this rate, you'll end the month with 2M remaining — 500k less than last month"
  - Visual: projected line on spending chart
  - Effort: Medium

- [ ] **Peer Benchmarking (Mock)**
  - "You spend 20% more on dining than similar users in HCMC"
  - Mock anonymized aggregate data for demo
  - Effort: Medium

- [ ] **Recurring Payment Optimization**
  - AI detects: "You pay 3 streaming services totaling 500k/month — consider bundling or dropping one"
  - Effort: Low

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
- [ ] Push notification with personalized financial digest (if P1 done)

### Devpost
- [ ] Project story (done: `docs/hackathon-about.md`)
- [ ] Elevator pitch / tagline
- [ ] Screenshots / images (at least 4-5 screens)
- [ ] GitHub repo link (done: secrets purged, history clean)
- [ ] Tech stack: Qwen 3.5, Qwen3-VL, Flutter, Supabase, vLLM
- [ ] Use case [SB1] clearly referenced
- [ ] Link to live app (Play Store beta) if allowed

### Code
- [ ] Repo clean for sharing (done: secrets purged, history rewritten)
- [ ] `.env.example` updated with all required env vars
- [ ] README updated for hackathon context (setup instructions for judges)

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
