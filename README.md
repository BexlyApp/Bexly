<p align="center">
  <img src="assets/icon/icon-transparent-full.png" width="100" alt="Bexly Logo"/>
</p>

<h1 align="center">Bexly</h1>
<p align="center"><strong>AI-Powered Personal Finance Assistant</strong></p>

<p align="center">
  <a href="https://play.google.com/apps/testing/com.joy.bexly"><img src="https://img.shields.io/badge/Google_Play-Beta-00C853?logo=googleplay&logoColor=white" alt="Google Play"/></a>
  <a href="https://testflight.apple.com/join/bJf9enac"><img src="https://img.shields.io/badge/App_Store-TestFlight-007AFF?logo=apple&logoColor=white" alt="App Store"/></a>
  <a href="https://app.bexly.app"><img src="https://img.shields.io/badge/Web-app.bexly.app-4285F4?logo=googlechrome&logoColor=white" alt="Web"/></a>
  <img src="https://img.shields.io/badge/macOS-Available-000000?logo=apple&logoColor=white" alt="macOS"/>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/AI-Qwen_3.5-FF6F00?logo=openai&logoColor=white" alt="AI Powered"/>
  <img src="https://img.shields.io/badge/License-LGPL_v3-blue" alt="License"/>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/BexlyApp/Bexly?style=social" alt="Stars"/>
  <img src="https://img.shields.io/github/forks/BexlyApp/Bexly?style=social" alt="Forks"/>
  <img src="https://img.shields.io/github/commit-activity/w/BexlyApp/Bexly?style=social" alt="Activity"/>
</p>

---

**Bexly** is a cross-platform AI-powered personal finance platform that goes beyond tracking — it **coaches** you. Available on Android, iOS, Web, Windows, macOS, and Linux, Bexly combines an offline-first local database with cloud sync and an AI financial coach that understands your spending patterns, predicts your cash flow, detects anomalies, and proactively guides you toward better financial health.

Think of it as having a personal financial advisor in your pocket — one that learns from your habits, speaks your language, and works even without internet.

---

## Why Bexly?

Most finance apps just **record** your money. Bexly **understands** it.

| Traditional Trackers | Bexly |
|---|---|
| Log expenses manually | AI scans receipts and auto-categorizes |
| Static charts and reports | Real-time Financial Health Score (0-100) |
| No guidance | AI Coach suggests where to cut spending |
| Month-end surprises | End-of-month spending forecast |
| Silent when you overspend | Anomaly alerts when spending spikes |

---

## Key Features

### AI Financial Coach

Bexly's built-in AI assistant acts as your personal financial advisor:

- **Natural conversation** — Ask "How much did I spend on food this month?" or "Create a budget for shopping"
- **Proactive coaching persona** — Warns you when a category trends over budget, encourages better savings, celebrates milestones
- **Spending insights injection** — Every AI turn automatically receives up-to-date context: monthly totals, month-over-month trend, top categories, budget status, recurring costs, health score and end-of-month forecast
- **Action execution** — Creates transactions, budgets, and goals through chat via a structured `ACTION_JSON` protocol
- **Voice input** — Speak your expenses, AI handles the rest
- **Receipt scanning** — Point your camera at any receipt and let Qwen Vision extract amount, merchant, category and date
- **Multilingual** — Automatically detects the user's language and replies in Vietnamese, English, Chinese, Japanese, Korean or Thai

### Financial Intelligence

- **Financial Health Score** — A dynamic 0-100 score based on savings rate, budget adherence, expense trends, and goal progress
- **Spending Forecast** — Predicts your end-of-month balance based on current velocity
- **Anomaly Detection** — Flags unusual transactions that exceed 3x your category average
- **Daily Digest** — Morning notification summarizing yesterday's activity and month-to-date status

### Core Finance

- **Multi-wallet** — Separate wallets for cash, bank accounts, e-wallets, each with its own currency
- **Smart budgets** — Monthly/weekly budgets with auto-renewal and progress tracking
- **Goal planning** — Savings goals with checklists and progress visualization
- **Recurring payments** — Track subscriptions and bills, get reminded before due dates
- **Reports & analytics** — Category breakdowns, trends, cash flow charts
- **14 languages** — Vietnamese, English, Japanese, Korean, Chinese, and more

### Banking Actions & Product Recommendations

When the AI detects relevant signals in your spending, it can propose concrete banking actions directly from the chat:

- **Open savings account** — Auto-suggests moving idle balance into a higher-yield savings product
- **Transfer to savings** — Proposes specific sweep amounts based on cash flow
- **Apply for a card** — Cashback, FX (foreign-currency), or premium card recommendations triggered by your spending profile
- **Apply for a loan** — Debt consolidation suggestions when high-interest balances are detected

All recommendations come with clear reasoning based on your real transaction history — no banner ads, no generic upsell.

### Channels

- **Mobile & web app** — Full Flutter experience on Android, iOS, Web, macOS, Windows, Linux
- **Telegram bot** — Chat with the same Financial Coach on Telegram, log expenses in natural language, get spending summaries on the go
- **Demo accounts** — Try the Coach with pre-seeded demo profiles (office worker, freelancer, etc.) without creating an account

### Cloud & Sync

- **Offline-first** — Works without internet. Your data lives on your device
- **Cloud sync** — Sign in to sync across devices via Supabase
- **Family sharing** — Shared wallets and family groups
- **Backup & restore** — Never lose your financial history

---

## Platform Availability

| Platform | Status | Distribution |
|----------|--------|-------------|
| Android | **Beta** | [Google Play Beta](https://play.google.com/apps/testing/com.joy.bexly) |
| iOS | **Beta** | [TestFlight](https://testflight.apple.com/join/bJf9enac) |
| Web | **Stable** | [app.bexly.app](https://app.bexly.app) |
| macOS | **Stable** | CI/CD build |
| Windows | In development | Local build |
| Linux | In development | Local build |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter + Dart |
| **State** | Riverpod + Hooks |
| **Local DB** | Drift (SQLite) — 16 tables, offline-first |
| **Cloud** | Supabase (Auth, PostgreSQL, Edge Functions, Realtime) |
| **AI** | Self-hosted Qwen 3.5 via vLLM (OpenAI-compatible) with cloud Qwen fallback |
| **Auth** | Google, Apple, Facebook sign-in |
| **Analytics** | Firebase Analytics + Crashlytics |
| **Payments** | Stripe + Google Play Billing |
| **CI/CD** | GitHub Actions (Android, iOS, Web, macOS, Linux) |

---

## Architecture

```
Bexly follows a feature-first modular architecture with 33+ feature modules:

lib/
├── core/                    # Shared infrastructure
│   ├── database/            # Drift tables, DAOs, migrations
│   ├── services/            # AI, sync, notifications, background tasks
│   ├── components/          # Reusable UI components
│   └── config/              # App configuration
├── features/
│   ├── ai_chat/             # AI financial coach
│   ├── dashboard/           # Home screen with health score & forecast
│   ├── transaction/         # Income & expense tracking
│   ├── budget/              # Budget management with auto-renewal
│   ├── goal/                # Savings goals with checklists
│   ├── recurring/           # Subscription & bill tracking
│   ├── receipt_scanner/     # AI-powered receipt OCR
│   ├── reports/             # Analytics & visualizations
│   ├── family/              # Family groups & shared wallets
│   ├── wallet/              # Multi-wallet management
│   ├── gamification/        # Levels & achievements
│   └── ...                  # 20+ more feature modules
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK
- Android Studio or VS Code

### Setup

```bash
# Clone the repository
git clone https://github.com/BexlyApp/Bexly.git
cd Bexly

# Install dependencies
flutter pub get

# Generate code (Drift schemas, Freezed models)
dart run build_runner build

# Run on Android
flutter run -d emulator-5554

# Run on Chrome
flutter run -d chrome
```

### Environment

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
BEXLY_FREE_AI_KEY=your_ai_key
BEXLY_FREE_AI_MODEL=dos-ai
```

---

## AI Integration

Bexly uses a multi-provider AI architecture:

```
User message
    │
    ▼
┌──────────────────────┐     ┌────────────────────┐
│ Self-hosted Qwen 3.5 │────▶│ Qwen 3.5 Cloud     │
│ vLLM / OpenAI API    │     │ (automatic fallback)│
└──────────────────────┘     └────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Financial Context Injection     │
│ • Health Score    • Forecasts   │
│ • Budget status   • Anomalies   │
│ • Spending trends • Goals       │
│ • Recurring costs • Wallet data │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Action Execution                │
│ • Create transactions           │
│ • Set budgets & goals           │
│ • Open savings accounts         │
│ • Product recommendations       │
└─────────────────────────────────┘
```

The AI doesn't just respond — it acts. Through the ACTION_JSON protocol, the AI can directly create transactions, set budgets, open savings accounts, and suggest relevant financial products within the conversation.

Because Qwen 3.5 is open-source and Bexly's inference layer uses the OpenAI-compatible API standard, the entire AI stack can be deployed fully on-premise — suitable for privacy-sensitive environments where customer financial data cannot leave the organization's own infrastructure.

---

## Roadmap

### Completed

- [x] Multi-wallet with multi-currency support
- [x] Expense & income tracking with custom categories
- [x] Budget management with weekly/monthly auto-renewal
- [x] Savings goals with checklist breakdowns
- [x] Recurring payment & subscription tracking
- [x] AI Financial Coach (chat, voice input, action execution)
- [x] Receipt scanning with AI-powered OCR
- [x] Financial Health Score (0-100 dynamic scoring)
- [x] End-of-month spending forecast
- [x] Spending anomaly detection & alerts
- [x] Daily financial digest notifications
- [x] Cloud sync via Supabase (offline-first)
- [x] Family groups & shared wallets
- [x] Gamification (levels & achievements)
- [x] Email transaction sync
- [x] Telegram bot with Financial Coach persona
- [x] Banking actions from chat (open savings, transfer, card & loan suggestions)
- [x] Contextual product recommendations based on spending profile
- [x] Self-hosted AI deployment option (Qwen 3.5 via vLLM)
- [x] Demo accounts with pre-seeded spending profiles
- [x] Dark/light theme with custom color schemes
- [x] 14 language localization
- [x] Google, Apple, Facebook sign-in
- [x] CI/CD for Android, iOS, Web, macOS, Linux

### In Progress

- [ ] NPS survey & user satisfaction tracking
- [ ] Churn prevention with re-engagement notifications
- [ ] Richer coaching dialogues with long-term goal planning

### Planned

- [ ] Home screen widgets (Android & iOS)
- [ ] Smart notification suggestions from device payment notifications
- [ ] Advanced investment tracking
- [ ] Bank account connections via Open Banking APIs
- [ ] Collaborative budgeting for families and couples

---

## Contributing

We welcome contributions! Fork this project, submit issues, or open pull requests.

```bash
# Run tests
flutter test

# Check code quality
flutter analyze

# Generate localization
flutter gen-l10n
```

---

## Community

- [GitHub Discussions](https://github.com/BexlyApp/Bexly/discussions) — Feature requests & technical discussion
- [Discord](https://discord.gg/xt5wDe4w) — Chat with the community

---

## Credits

Bexly is a fork of [**Pockaw**](https://github.com/layground/pockaw), an MIT-licensed Flutter personal finance tracker. Pockaw gave us a production-quality starting point for the core wallet/transaction/budget UI and offline-first Drift database layer, which let us focus our own work on the AI coach, action protocol, self-hosted inference pipeline, contextual product recommender and financial health intelligence. Thanks to the Pockaw team and the broader open-source community.

---

## License

This project is licensed under the **LGPL v3 License**. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with purpose by <a href="https://dos.ai">DOS Labs</a>
</p>
