## Inspiration

Managing personal finances shouldn't require spreadsheets or financial literacy courses. We observed that most banking apps stop at showing transaction history — they don't *understand* the customer's financial behavior or proactively help them improve it.

When we saw Shinhan Bank Vietnam's [SB1] use case — an AI Personal Financial Coach embedded in the SOL app — it aligned perfectly with what we've been building: **an AI assistant that doesn't just track money, but actively coaches users to make better financial decisions**, in their own language.

The opportunity to power this with Qwen's multilingual capabilities made the fit even stronger for the Vietnamese market.

## What it does

Bexly is an AI-powered personal financial coach that:

**Conversational Finance Management**
- Users create transactions, budgets, savings goals, and recurring charges through natural language — *"I spent 150k on lunch"*, *"Set a 5M budget for food this month"*, *"Save 20M for a vacation by December"*
- The AI understands context: saying *"I pay Netflix 200k monthly"* automatically creates a recurring charge, not a one-time expense
- Supports 15+ structured actions: `create_expense`, `create_income`, `create_budget`, `create_goal`, `create_recurring`, `get_balance`, `get_summary`, `list_transactions`, and more

**Proactive Financial Insights**
- Analyzes spending patterns across categories and surfaces actionable recommendations
- Spending summaries with category breakdowns — users ask *"How much did I spend on dining this month?"* and get instant answers
- Budget tracking with smart alerts when approaching limits

**Smart Document Understanding**
- **Receipt/Invoice OCR**: Snap a photo of any receipt → AI extracts amount, merchant, category, date automatically
- **Banking Screenshot Import**: Take a screenshot of another banking app → AI bulk-extracts all visible transactions
- **Email Sync**: Connects to Gmail, parses banking notification emails using AI, and imports transactions with review workflow
- Supports camera, gallery, and PDF input

**Multi-Currency & Multi-Language**
- 14 languages: Vietnamese, English, Japanese, Korean, Chinese, Thai, Indonesian, Hindi, Arabic, and more
- Multi-wallet with independent currencies and real-time exchange rates
- Voice input with locale-aware speech recognition (Vietnamese default)

**Product Recommendation Engine**
- Based on spending analysis, the AI can suggest relevant financial products (credit cards, savings plans, insurance, loans)
- Cross-sell opportunities identified from transaction patterns — exactly what Shinhan's SB1 use case requires

## How we built it

**AI Architecture — Qwen-Powered with Smart Fallback**

The core AI engine runs on **Qwen 3.5 (35B-A3B)** via a self-hosted vLLM server, providing:
- Natural language understanding for financial queries
- Structured action extraction via an `ACTION_JSON` protocol — the model outputs both human-readable responses and machine-parseable actions in a single response
- Vision capabilities for receipt OCR and screenshot analysis (Qwen3-VL)
- `enable_thinking: false` for fast, deterministic responses

Fallback chain: **Qwen (primary) → Gemini (backup) → OpenAI (premium tier)**, ensuring 99.9% availability. Non-Qwen providers route through a Supabase Edge Function proxy to keep API keys server-side.

**Tech Stack**
- **Frontend**: Flutter (cross-platform — Android, iOS, Web) with Riverpod + Hooks for state management
- **Database**: Drift/SQLite (16 tables, 12 DAOs, schema v27) with cloud sync to Supabase PostgreSQL
- **Auth**: Supabase with Google/Apple/Facebook social login
- **AI Proxy**: Supabase Edge Functions (Deno) — routes AI requests with JWT auth, keeps keys server-side
- **Background Processing**: WorkManager for email sync and recurring charge automation
- **OCR Pipeline**: Strategy pattern with 5 provider implementations (`DosAiOcrProvider`, `GeminiOcrProvider`, `OpenAiOcrProvider`, `ClaudeOcrProvider`, `FallbackOcrProvider`)

**Action Protocol Design**

The AI doesn't just chat — it *acts*. We designed a structured action protocol where the model embeds JSON actions within its response:

```
ACTION_JSON: {"action": "create_expense", "amount": 150000, "currency": "VND", "category": "Food & Dining", "description": "Lunch"}
```

The app parses these actions, executes them against the local database, syncs to cloud, and confirms back to the user — all in one conversational turn. Destructive actions (delete, bulk operations) require explicit user confirmation via inline buttons.

## Challenges we ran into

1. **Action ambiguity**: *"I pay 200k for electricity every month"* — is this a one-time expense or a recurring charge? We built keyword detection that auto-upgrades `create_expense` to `create_recurring` when frequency words are present

2. **Receipt OCR accuracy across Vietnamese receipts**: Vietnamese receipts have inconsistent formats, mixed Vietnamese/English text, and varying quality. We implemented a fallback OCR chain (Qwen Vision → Gemini) and structured prompts that handle receipts, invoices, bank statements, and banking app screenshots

3. **Email parsing reliability**: Banking notification emails from different Vietnamese banks (Vietcombank, BIDV, Techcombank, Shinhan) have wildly different formats. We use LLM-powered parsing instead of regex, with a human-in-the-loop review screen before importing

4. **Multi-currency AI context**: When a user has wallets in VND, USD, and JPY, the AI needs to understand which wallet context it's operating in. We implemented a wallet fallback chain (active → default → first available) and pre-fetch exchange rates on chat open

5. **Qwen response latency**: Self-hosted Qwen on a single GPU needed optimization. We set `DOS_AI_TIMEOUT=5s` — if Qwen can't respond in 5 seconds, we instantly fall back to Gemini, so the user never waits

## Accomplishments that we're proud of

- **15+ AI-driven financial actions** executable through natural conversation — not just a chatbot, but a financial operating system
- **5-provider OCR pipeline** with automatic fallback — receipts, screenshots, PDFs all work seamlessly
- **Gmail integration** that turns banking email notifications into structured transactions with AI parsing
- **14 languages** supported out of the box — critical for a banking app serving diverse markets
- **32 feature modules** in a clean architecture — from gamification to family shared wallets to subscription management
- **Zero exposed API keys** — all AI provider keys are server-side via Edge Function proxy, only the free-tier Qwen key ships with the app
- **Voice input** with real-time transcription in Vietnamese — users can speak their expenses naturally

## What we learned

- **LLMs as action engines, not just chatbots**: The real power isn't in generating text — it's in parsing user intent into structured database operations. The `ACTION_JSON` protocol was the breakthrough that made the AI genuinely useful
- **Fallback chains are essential for production AI**: No single model is 100% reliable. Having Qwen → Gemini → OpenAI means users never see a failure
- **Vietnamese NLP is hard**: Currency formats (150.000 vs 150,000), mixed-script text, and colloquial financial terms required careful prompt engineering
- **OCR needs multiple strategies**: A single OCR provider can't handle all document types. The strategy pattern with fallback made the system robust across receipts, screenshots, and PDFs

## What's next for Bexly

- **Proactive push notifications**: AI analyzes spending trends and sends alerts — *"You've spent 80% of your food budget with 10 days left"*
- **Product recommendation engine**: Based on spending patterns, suggest relevant Shinhan products (credit cards with dining cashback, savings accounts, insurance)
- **Predictive cash flow**: Use transaction history to forecast end-of-month balances and warn about potential shortfalls
- **Family financial coaching**: Shared budgets with AI insights for household spending optimization
- **Integration with banking APIs**: Direct connection to Shinhan's SOL app for real-time transaction feeds instead of manual entry
