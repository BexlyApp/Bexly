# Customer Solution Deck — Bexly for Shinhan Bank Vietnam [SB1]

> Draft content for slide generation. Copy to Claude Cowork with prompt:
> "Generate a professional Customer Solution Deck PDF (16:9 slides) from this content.
> Brand colors: primary purple #731FE0, light purple #9156FC, accent purple-50 #F6F3FF, dark background #0F172A, white text.
> Logo is a purple receipt icon with dollar sign. Include diagrams where indicated. Modern fintech/banking style."

---

## Slide 1: Cover

**Bexly — AI Personal Financial Coach for Shinhan SOL**

A self-hosted AI financial coach that banks can deploy on their own servers — fully open-source, regulation-ready, zero data leakage.

bexly.app | DOS Labs

---

## Slide 2: The Problem

**Banking apps show data. They don't coach behavior.**

- 78% of Vietnamese consumers want personalized financial advice (PwC Vietnam 2025)
- Most banking apps stop at transaction history — no proactive insights, no coaching
- Financial literacy is low: users don't know *what to do*, not just *what happened*
- Cross-sell conversion is poor: products are pushed, not recommended based on behavior

**Shinhan's challenge [SB1]:** How to embed an AI assistant in SOL that *actively coaches* each customer — in their language, in real-time, on their data?

**Regulatory constraint:** Customer financial data MUST stay within bank infrastructure. Cloud-only AI (OpenAI, Gemini) is not an option for production.

---

## Slide 3: The Solution — Bexly

Bexly is an **AI-powered personal financial coach** that turns banking from passive tracking into active coaching.

| What users do today | What Bexly enables |
|--------------------|--------------------|
| Open app → see balance | Open app → see Financial Health Score (72/100) |
| Scroll transaction list | Ask "How much did I spend on dining?" → instant answer |
| Manually set budget | AI suggests: "Your dining is 40% higher — want a 5M budget?" |
| Ignore savings potential | AI calculates: "5M idle → open 6-month savings at 5.5% = 275K interest" |
| Miss overspending | AI alerts: "This transaction is 3x your category average" |
| Don't know which products fit | AI recommends: "High dining spend → Shinhan cashback card" |

**The AI doesn't wait for questions — it proactively coaches.**

---

## Slide 4: SB1 Outcome Mapping

[DIAGRAM: 5 outcomes grid with Bexly features mapped]

| # | SB1 Expected Outcome | Bexly Feature | Status |
|---|---------------------|---------------|--------|
| 1 | **Increase DAU/MAU** on SOL | Daily Digest notifications, Financial Health Score tracking, gamification streaks | Built |
| 2 | **Improve cross-sell conversion** (cards, loans, insurance) | Product Recommendation Engine — 6 Shinhan products with AI-driven suggestion rules + banking actions | Built |
| 3 | **Reduce churn** through proactive insights | Spending Anomaly Alerts, Churn Prevention (3-day inactivity re-engagement), Spending Forecast | Built |
| 4 | **Enhance NPS/CSAT** via personalized guidance | Financial Coach persona, personalized AI conversations, in-app NPS survey (1-5 stars every 10 interactions) | Built |
| 5 | **Grow CASA balance** through savings recommendations | Auto-Suggest Savings Plans with interest calculations, `open_savings_account` action, `transfer_to_savings` action | Built |

**All 5 expected outcomes are fully implemented and demo-ready.**

---

## Slide 5: Conversational Finance — 15+ AI Actions

[DIAGRAM: Chat conversation mockup showing natural language → action]

**Users manage finances through natural conversation:**

```
User: "I spent 150k on lunch today"
AI:   ✅ Recorded 150,000 VND — Food & Dining
      📊 You've used 80% of your Food budget with 15 days left.
      💡 Consider cooking at home a few days this week to stay on track!

User: "I pay Netflix 200k every month"  
AI:   ✅ Created recurring charge: Netflix — 200,000 VND/month
      📋 You now have 5 recurring charges totaling 1.2M/month.

User: "Set a 5M budget for food this month"
AI:   ✅ Budget created: Food & Dining — 5,000,000 VND (Apr 2026)

User: "How much did I spend last month?"
AI:   📊 March 2026 Summary:
      Total expenses: 12,450,000 VND
      Top categories: Food (4.2M), Transport (2.8M), Shopping (2.1M)
      vs February: ↑15% — mainly dining increased.
```

**Supported actions:** `create_expense`, `create_income`, `create_budget`, `create_goal`, `create_recurring`, `get_balance`, `get_summary`, `list_transactions`, `delete_transaction`, `update_transaction`, `open_savings_account`, `apply_credit_card`, `apply_loan`, `transfer_to_savings`, and more.

---

## Slide 6: Proactive Financial Intelligence

[DIAGRAM: 4 cards showing each intelligence feature]

**Financial Health Score (0-100)**
- Formula: savings rate (30%) + budget adherence (25%) + expense stability (20%) + goal progress (15%) + debt ratio (10%)
- Displayed on dashboard with grade (A+ to F)
- AI references in conversations: "Your score is 72 — reducing dining spend could push it above 80"

**Spending Forecast**
- Predicts end-of-month balance based on daily burn rate
- Warns users before shortfalls: "At this pace, you'll end April with 1.2M — 800K less than last month"

**Anomaly Detection**
- Flags transactions exceeding 3x the 30-day category average
- Push notification: "Your shopping spend today is 3x your usual — want to review?"

**Daily Digest**
- Morning notification: yesterday's spending + month-to-date + budget status
- Taps → opens AI chat with context pre-loaded
- Drives daily app opens (DAU)

---

## Slide 7: Product Recommendation + Banking Actions

[DIAGRAM: Spending pattern → AI recommendation → banking action flow]

**AI detects spending patterns and recommends relevant Shinhan products:**

| Spending Signal | Recommended Product | Banking Action |
|----------------|--------------------|----|
| High dining/shopping spend | Shinhan Cashback Credit Card | `apply_credit_card` |
| Idle balance in current account | Shinhan High-Yield Savings | `open_savings_account` |
| No insurance transactions | Shinhan Life/Health Insurance | Product info + contact |
| Frequent international spend | Shinhan FX Savings Card | `apply_credit_card` |
| High recurring charges | Shinhan Consolidation Loan | `apply_loan` |
| Excess monthly surplus | Auto-sweep to Savings | `transfer_to_savings` |

**Auto-Suggest Savings:**
```
AI: You have 5,000,000 VND idle this month.
    → Open a 6-month Shinhan Savings Account at 5.5% APR
    → Earn 275,000 VND interest
    
    [Open Savings Account]  [Maybe Later]
```

Destructive/financial actions require explicit user confirmation via inline buttons.

---

## Slide 8: Smart Document Understanding

[DIAGRAM: Receipt photo → OCR → structured transaction]

**5-Provider OCR Pipeline with automatic fallback:**

```
Camera/Gallery/PDF
       │
       ▼
┌─────────────────┐     ┌──────────────────┐
│ Qwen Vision OCR │──X──│ Gemini Fallback  │
│ (on-premise)    │     │ (dev only)       │
└────────┬────────┘     └────────┬─────────┘
         │                       │
         ▼                       ▼
   Structured Data: amount, merchant, category, date
         │
         ▼
   Auto-fill Transaction Form → User confirms → Saved
```

**Supports:**
- Receipts & invoices (Vietnamese, English, mixed)
- Banking app screenshots (bulk extract multiple transactions)
- PDF statements
- Gmail banking notification emails (background sync with review workflow)

---

## Slide 9: Multi-Language & Multi-Currency

**14 languages out of the box** — critical for Shinhan's diverse customer base:

Vietnamese, English, Japanese, Korean, Chinese (Simplified & Traditional), Thai, Indonesian, Malay, Hindi, Arabic, French, German, Spanish

**Multi-wallet system:**
- Independent currencies per wallet (VND, USD, JPY, KRW, etc.)
- Real-time exchange rates
- AI understands wallet context: operations execute in the active wallet's currency

**Voice input:** Locale-aware speech recognition with Vietnamese as default.

---

## Slide 10: Technical Architecture

[DIAGRAM: Full architecture]

```
┌─ Client Layer ─────────────────────────────────────────┐
│  Android (Play Store)  │  iOS (TestFlight)  │  Web     │
│  macOS                 │  Linux             │          │
│  Flutter — Riverpod + Hooks — Single codebase          │
└──────────────────────────┬─────────────────────────────┘
                           │
┌─ Local-First Layer ──────▼─────────────────────────────┐
│  Drift/SQLite — 16 tables, 12 DAOs, schema v27        │
│  Source of truth — works fully offline                 │
│  Soft delete + bidirectional sync with cloud           │
└──────────────────────────┬─────────────────────────────┘
                           │
┌─ Cloud Sync Layer ───────▼─────────────────────────────┐
│  Supabase PostgreSQL — Schema: bexly                   │
│  Auth (Google/Apple/Facebook SSO)                      │
│  Edge Functions (AI proxy, webhooks)                   │
│  Realtime subscriptions for live sync                  │
└──────────────────────────┬─────────────────────────────┘
                           │
┌─ AI Layer ───────────────▼─────────────────────────────┐
│  Qwen 3.5 (35B-A3B-GPTQ-Int4) via vLLM               │
│  OpenAI-compatible API (/v1/chat/completions)          │
│  Text + Vision (receipt OCR) — single model            │
│  Self-hosted on Linux server with GPU                  │
└────────────────────────────────────────────────────────┘
```

---

## Slide 11: Why On-Premise Matters

**Vietnamese banking regulation requires customer financial data to stay within bank infrastructure.**

Cloud-only AI solutions (OpenAI, Google Gemini, Claude) **cannot** be used in production for banking.

**Bexly's entire stack is open-source and self-hostable:**

| Component | License | On-Premise Ready |
|-----------|---------|-----------------|
| **Qwen 3.5** | Apache 2.0 | Self-hosted via vLLM on any Linux GPU server |
| **vLLM** | Apache 2.0 | Docker-ready, OpenAI-compatible API |
| **Supabase** | Apache 2.0 | Self-hosted PostgreSQL + Auth + Edge Functions |
| **SQLite/Drift** | Public Domain | Runs on user's device — zero cloud dependency |
| **Flutter** | BSD 3-Clause | Fully owned source code, no vendor lock-in |

**Zero dependency on proprietary cloud AI APIs.**

**Deployment for Shinhan:**
1. Deploy vLLM + Qwen on Shinhan's GPU cluster
2. Self-host Supabase for auth and cloud sync
3. All customer data stays in Shinhan's data center
4. Audit trail: every AI action is logged locally

---

## Slide 12: Qwen Integration Deep Dive

**3 ways Bexly uses Qwen:**

| # | Role | How |
|---|------|-----|
| 1 | **Financial Coach Brain** | System prompt with coaching persona, spending analysis context, product recommendation rules — all reasoning runs through Qwen |
| 2 | **Action Engine** | Qwen parses natural language → embeds `ACTION_JSON` in response → app executes structured database operations |
| 3 | **Vision OCR** | Qwen Vision processes receipt/invoice photos → extracts amount, merchant, category, date |

**Action Protocol:**
```json
User: "I spent 150k on lunch"

Qwen response:
"Recorded your lunch expense! You've used 80% of your food budget."

ACTION_JSON: {
  "action": "create_expense",
  "amount": 150000,
  "currency": "VND",
  "category": "Food & Dining",
  "description": "Lunch"
}
```

**Current setup:**
- vLLM serving Qwen 3.5-35B-A3B-GPTQ-Int4
- `max_model_len=16384`, `gpu-memory-utilization=0.65`
- Response time: < 5 seconds
- Production: multiple Qwen instances behind load balancer

---

## Slide 13: SOL App Integration Path

[DIAGRAM: Integration phases]

**Phase 1 — Standalone (Current)**
- Bexly runs as independent app
- Users manually input or scan transactions
- AI coaching based on user-reported data

**Phase 2 — SOL SDK Integration**
- Embed Bexly's AI chat as a module inside SOL app
- Share Shinhan auth (SSO) — no separate login
- Flutter module can be integrated via platform channel

**Phase 3 — Full Banking API Integration**
- Connect to Shinhan's Core Banking System
- Real-time transaction feed — zero manual entry
- Banking actions execute directly (open account, apply card, transfer)
- AI has full context: balances, products, transaction history

**Phase 4 — Scale**
- Multi-instance Qwen behind load balancer
- A/B test coaching strategies
- Peer benchmarking with anonymized aggregate data
- Home screen widgets for SOL app

---

## Slide 14: Live Demo Flow

**Demo scenario: Vietnamese user managing daily finances**

1. **Natural Language Transaction** — "Toi vua an trua 150k" → expense created, budget warning
2. **Spending Analysis** — "Phan tich chi tieu thang nay" → category breakdown, month-over-month comparison
3. **Proactive Coaching** — AI suggests budget based on spending patterns
4. **Receipt OCR** — Snap receipt photo → auto-extract and create transaction
5. **Product Recommendation** — AI detects high dining spend → recommends Shinhan cashback card
6. **Savings Suggestion** — AI calculates idle balance → suggests opening savings account
7. **Banking Action** — User confirms → savings account opened (mock banking API)
8. **Financial Health Score** — Dashboard shows 72/100 with improvement tips
9. **Voice Input** — Vietnamese speech → transaction created
10. **Multi-Language** — Switch to English/Korean → same features, same data

**Live at:** https://app.bexly.app

---

## Slide 15: Competitive Advantage

| Feature | Traditional Banking Apps | Generic AI Chatbots | **Bexly** |
|---------|------------------------|--------------------|----|
| Transaction tracking | Yes | No | **Yes** |
| Natural language input | No | Yes (text only) | **Yes (text + voice + image)** |
| Proactive coaching | No | No | **Yes — daily digest, anomaly alerts** |
| Financial Health Score | No | No | **Yes (0-100 with grade)** |
| Spending forecast | No | No | **Yes — end-of-month prediction** |
| Product recommendation | Generic banners | N/A | **AI-driven based on spending patterns** |
| Banking actions via chat | No | No | **Yes — open account, apply card, transfer** |
| Receipt OCR | Some (basic) | No | **Yes — 5-provider fallback chain** |
| On-premise deployable | N/A | No (cloud-only) | **Yes — fully open-source stack** |
| Multi-language | 1-2 languages | Depends on API | **14 languages** |
| Offline-first | No | No | **Yes — SQLite local DB** |

---

## Slide 16: Contact & Next Steps

**DOS Labs**
- Web App: bexly.app
- Live Demo: app.bexly.app
- GitHub: github.com/BexlyApp/Bexly
- Email: joy@dos.ai

**Team:** Anh Le (JOY) — Founder, DOS Labs

**Next steps:**
1. Live demo at Qwen AI Build Day (21 Apr 2026)
2. Pilot integration discussion with Shinhan Digital Business Unit
3. PoC scoping: embed Bexly module in SOL app (2-4 week timeline)
4. On-premise Qwen deployment on Shinhan GPU infrastructure

---
