## Elevator Pitch

A self-hosted AI financial coach that banks can deploy on their own servers - fully open-source, regulation-ready, zero data leakage.

## Inspiration

Managing personal finances shouldn't require spreadsheets or financial literacy courses. We observed that most banking apps stop at showing transaction history - they don't *understand* the customer's financial behavior or proactively help them improve it.

When we saw Shinhan Bank Vietnam's [SB1] use case - an AI Personal Financial Coach embedded in the SOL app - it aligned perfectly with what we've been building: **an AI assistant that doesn't just track money, but actively coaches users to make better financial decisions**, in their own language.

Crucially, **banking regulation in Vietnam requires customer financial data to stay within bank infrastructure**. This means cloud-only AI solutions (OpenAI, Google Gemini, etc.) are not viable for production deployment. Our entire stack - from the AI model to the database - is open-source and self-hostable, making it the right fit for Shinhan's compliance requirements.

## What it does

Bexly is an AI-powered personal financial coach that:

**Conversational Finance Management**
- Users create transactions, budgets, savings goals, and recurring charges through natural language - *"I spent 150k on lunch"*, *"Set a 5M budget for food this month"*, *"Save 20M for a vacation by December"*
- The AI understands context: saying *"I pay Netflix 200k monthly"* automatically creates a recurring charge, not a one-time expense
- Supports 15+ structured actions: `create_expense`, `create_income`, `create_budget`, `create_goal`, `create_recurring`, `get_balance`, `get_summary`, `list_transactions`, and more

**Proactive Financial Coaching**
- **Financial Health Score (0-100)**: Dynamic score based on savings rate, budget adherence, expense trends, and goal progress - displayed on the dashboard and referenced by the AI in conversations
- **Spending Forecast**: Predicts end-of-month balance based on current spending velocity - warns users before shortfalls happen
- **Anomaly Detection**: Flags transactions exceeding 3x the category average - pushes alerts so users catch overspending in real-time
- **Daily Digest**: Morning notification summarizing yesterday's activity and month-to-date status
- The AI doesn't wait for questions - it proactively coaches: *"Your dining spend is 40% higher than last month - want to set a budget?"*

**Product Recommendation Engine**
- Based on spending analysis, the AI suggests relevant Shinhan financial products:
  - High dining/shopping spend → Shinhan cashback credit card
  - Idle balance in current account → high-yield savings account
  - No insurance transactions → life/health insurance product
  - Frequent international spend → Shinhan FX savings card
- Banking actions: `open_savings_account`, `apply_credit_card`, `apply_loan`, `transfer_to_savings`
- Auto-suggest savings plans: *"You have 5M idle this month → open a 6-month savings at 5.5% and earn 275k interest"*

**Smart Document Understanding**
- **Receipt/Invoice OCR**: Snap a photo of any receipt → AI extracts amount, merchant, category, date automatically
- **Banking Screenshot Import**: Take a screenshot of another banking app → AI bulk-extracts all visible transactions
- **Email Sync**: Connects to Gmail, parses banking notification emails using AI, and imports transactions with review workflow
- Supports camera, gallery, and PDF input

**Multi-Currency & Multi-Language**
- 14 languages: Vietnamese, English, Japanese, Korean, Chinese, Thai, Indonesian, Hindi, Arabic, and more
- Multi-wallet with independent currencies and real-time exchange rates
- Voice input with locale-aware speech recognition (Vietnamese default)

## How we built it

**AI Architecture - Open-Source, Self-Hosted, On-Premise Ready**

Every component of our AI stack is open-source and can be deployed on Shinhan's own infrastructure:

| Component | License | On-Premise Deployment |
|-----------|---------|----------------------|
| **Qwen 3.5 (35B-A3B)** | Apache 2.0 | Self-hosted via vLLM on any Linux server with GPU |
| **vLLM** | Apache 2.0 | OpenAI-compatible API server, Docker-ready |
| **Supabase** | Apache 2.0 | Self-hosted (PostgreSQL + Auth + Edge Functions) |
| **SQLite/Drift** | Public Domain | Runs locally on user's device |
| **Flutter** | BSD 3-Clause | Fully owned source code |

**No dependency on proprietary cloud AI APIs.** The entire inference pipeline runs on a single GPU server. For production banking deployment, Shinhan can:
1. Deploy vLLM + Qwen on their own GPU cluster
2. Self-host Supabase for cloud sync and auth
3. All customer financial data stays within Shinhan's data center
4. Zero data leaves the bank's infrastructure

**Current Self-Hosted Setup:**
- vLLM serving Qwen 3.5 via OpenAI-compatible API (`/v1/chat/completions`)
- Config: `max_model_len=16384`, `gpu-memory-utilization=0.65`
- 5-second timeout with automatic fallback to Gemini (for development only - production would use multiple Qwen instances)
- Vision capabilities for receipt OCR via the same Qwen model

**Action Protocol Design**

The AI doesn't just chat - it *acts*. We designed a structured action protocol where the model embeds JSON actions within its response:

```
ACTION_JSON: {"action": "create_expense", "amount": 150000, "currency": "VND", "category": "Food & Dining", "description": "Lunch"}
```

The app parses these actions, executes them against the local database, syncs to cloud, and confirms back to the user - all in one conversational turn. Destructive actions (delete, bulk operations) require explicit user confirmation via inline buttons.

**Tech Stack**
- **Frontend**: Flutter (cross-platform - Android, iOS, Web, macOS, Linux) with Riverpod + Hooks for state management
- **Database**: Drift/SQLite (16 tables, 12 DAOs, schema v27) with cloud sync to Supabase PostgreSQL
- **Auth**: Supabase with Google/Apple/Facebook social login
- **AI Proxy**: Supabase Edge Functions (Deno) - routes AI requests with JWT auth, keeps keys server-side
- **Background Processing**: WorkManager for email sync, recurring charge automation, daily digest generation
- **OCR Pipeline**: Strategy pattern with 5 provider implementations (`DosAiOcrProvider`, `GeminiOcrProvider`, `OpenAiOcrProvider`, `ClaudeOcrProvider`, `FallbackOcrProvider`)

## How Qwen Powers Bexly

Qwen is the brain behind every feature - not a wrapper, but the core reasoning engine:

| # | Role | How Qwen is Used |
|---|------|-----------------|
| 1 | **Financial Coach Brain** | System prompt with coaching persona + spending context injection → Qwen reasons about user's financial behavior, generates personalized advice, and decides which actions to take |
| 2 | **Action Engine** | Qwen parses natural language intent → embeds structured `ACTION_JSON` in response → app executes database operations (create transactions, budgets, goals, banking actions) |
| 3 | **Vision OCR** | Qwen Vision processes receipt/invoice photos → extracts amount, merchant, category, date into structured data |
| 4 | **Product Recommender** | Qwen analyzes spending patterns against Shinhan product catalog → generates contextual recommendations with reasoning |

All inference runs on a self-hosted vLLM instance - no external API calls, no data leaving the server.

## Challenges we ran into

1. **On-premise model optimization**: Running a 35B-parameter model on a single GPU required careful tuning - quantization (GPTQ-Int4), context length limits, and memory utilization balancing. We achieved <5s response times with `gpu-memory-utilization=0.65`

2. **Action ambiguity**: *"I pay 200k for electricity every month"* - is this a one-time expense or a recurring charge? We built keyword detection that auto-upgrades `create_expense` to `create_recurring` when frequency words are present

3. **Receipt OCR accuracy across Vietnamese receipts**: Vietnamese receipts have inconsistent formats, mixed Vietnamese/English text, and varying quality. We implemented a fallback OCR chain (Qwen Vision → Gemini) and structured prompts that handle receipts, invoices, bank statements, and banking app screenshots

4. **Financial Health Score without banking API access**: Computing a meaningful health score without direct access to bank account data required creative use of transaction history, budget adherence, and goal progress as proxy signals

5. **Multi-currency AI context**: When a user has wallets in VND, USD, and JPY, the AI needs to understand which wallet context it's operating in. We implemented a wallet fallback chain (active → default → first available) and pre-fetch exchange rates on chat open

## Accomplishments that we're proud of

- **Fully open-source, self-hosted AI stack** - no dependency on proprietary cloud APIs, deployable on bank infrastructure from day one
- **15+ AI-driven financial actions** executable through natural conversation - not just a chatbot, but a financial operating system
- **Financial Health Score** that gives users a tangible, trackable metric for their financial well-being
- **Spending Forecast** that predicts end-of-month balance and warns users before problems happen
- **5-provider OCR pipeline** with automatic fallback - receipts, screenshots, PDFs all work seamlessly
- **Gmail integration** that turns banking email notifications into structured transactions with AI parsing
- **14 languages** supported out of the box - critical for a banking app serving diverse markets
- **33 feature modules** in a clean architecture - from gamification to family shared wallets to subscription management
- **Zero exposed API keys** - all AI provider keys are server-side via Edge Function proxy

## What we learned

- **On-premise is not optional for banking**: Cloud AI APIs are convenient for development, but Vietnamese banking regulation requires data sovereignty. Building on open-source from the start was the right architectural decision
- **LLMs as action engines, not just chatbots**: The real power isn't in generating text - it's in parsing user intent into structured database operations. The `ACTION_JSON` protocol was the breakthrough that made the AI genuinely useful
- **Fallback chains are essential for production AI**: No single model is 100% reliable. For production banking, this means multiple Qwen instances rather than falling back to cloud providers
- **Vietnamese NLP is hard**: Currency formats (150.000 vs 150,000), mixed-script text, and colloquial financial terms required careful prompt engineering
- **Financial coaching > financial tracking**: Users don't need another app that shows them charts - they need one that tells them what to *do*

## SB1 Expected Outcome Coverage

| # | Shinhan's Expected Outcome | How Bexly Delivers | Status |
|---|---------------------------|-------------------|--------|
| 1 | Increase DAU/MAU on SOL | Daily Digest notifications, Financial Health Score, gamification streaks, churn prevention re-engagement | Built |
| 2 | Improve cross-sell conversion | AI-driven product recommendations (6 Shinhan products) + banking actions (`apply_credit_card`, `open_savings_account`, `apply_loan`) | Built |
| 3 | Reduce churn through proactive insights | Spending Anomaly Alerts, Spending Forecast, proactive AI coaching after every transaction | Built |
| 4 | Enhance NPS/CSAT via personalized guidance | Financial Coach persona, personalized conversations, in-app NPS survey (1-5 stars) | Built |
| 5 | Grow CASA balance through savings recommendations | Auto-Suggest Savings with interest calculations, `transfer_to_savings` action | Built |

## How to Test

### Telegram Bot (@BexlyBot)

1. Open Telegram and search for **@BexlyBot**
2. Send `/start` - the bot will show a welcome message and demo account selector
3. **Pick a demo account** - each has different financial profiles:
   - **Minh** - Office Worker, 20M VND/month salary, high dining spend
   - **Lan** - Freelancer, irregular income, 8 subscriptions
   - **Huy** - Student, tight budget, minimal savings
   - **Trang** - Business Owner, multi-currency (VND/USD/EUR/JPY), 4 wallets
   - **Duc** - Expat, USD+VND, international spending patterns
4. Try these commands:
   - `/insights` - View spending overview with Financial Health Score
   - `/demo` - Switch to a different demo account
   - `/help` - See all available commands
5. Chat naturally with the AI coach:
   - `Tinh hinh tai chinh thang nay?` - Get personalized coaching advice
   - `How can I save more?` - Financial coaching in English
   - `ăn trưa 50k` - Record a lunch expense
   - `lương 15 triệu` - Record salary income
6. The AI will reference real spending data and suggest relevant **Shinhan banking products** based on each persona's patterns

### Mobile App (Flutter)

1. Download and install Bexly from the provided APK/TestFlight link
2. On the login screen, tap **"Demo Accounts"** to see 5 pre-configured accounts
3. Select any demo account - it auto-fills credentials and logs in
4. Explore features:
   - **Dashboard**: Financial Health Score, spending forecast, budget status
   - **AI Chat**: Tap the chat icon, try natural language commands
   - **Transactions**: View seeded transaction history
   - **Budgets & Goals**: See budget tracking with progress bars
   - **Receipt Scanner**: Take a photo of any receipt for AI OCR

### What Each Demo Account Triggers

| Account | Shinhan Product Triggers |
|---------|------------------------|
| Minh (test1) | Cashback Credit Card (high dining), Auto-Save (many small transactions) |
| Lan (test2) | Auto-Save (8 subscriptions), Personal Loan (irregular income) |
| Huy (test3) | Premium Savings (idle balance), Life Insurance (no coverage) |
| Trang (test4) | FX Multi-Currency Card (international transactions), Personal Loan |
| Duc (test5) | FX Multi-Currency Card (USD spending), Premium Savings |

## What's next for Bexly

- **Shinhan SOL App integration**: Embed Bexly AI module inside SOL via Flutter platform channel → real-time transaction feed from Core Banking API, zero manual entry
- **Multi-instance Qwen deployment**: Load-balanced vLLM cluster for production-grade throughput on Shinhan's GPU infrastructure
- **Home screen widgets**: Quick glance at balance, budget status, and AI tips without opening the app
- **Peer benchmarking**: *"You spend 20% more on dining than similar users in HCMC"* using anonymized aggregate data
- **Open Banking API integration**: Connect to multiple Vietnamese banks for consolidated financial view
