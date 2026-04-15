<p align="center">
  <img src="assets/icon/icon-transparent-full.png" width="100" alt="Bexly Logo"/>
</p>

<h1 align="center">Bexly</h1>
<p align="center"><strong>AI-Powered Personal Finance Assistant</strong></p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.joy.bexly"><img src="https://img.shields.io/badge/Google_Play-Download-00C853?logo=googleplay&logoColor=white" alt="Google Play"/></a>
  <a href="#"><img src="https://img.shields.io/badge/App_Store-TestFlight-007AFF?logo=apple&logoColor=white" alt="App Store"/></a>
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
- **Proactive coaching** — Warns you when a category is trending over budget
- **Spending insights** — Injects real-time financial data into every conversation
- **Action execution** — Creates transactions, budgets, and goals through chat
- **Voice input** — Speak your expenses, AI handles the rest
- **Receipt scanning** — Point your camera at any receipt and let AI extract the details

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

### Cloud & Sync

- **Offline-first** — Works without internet. Your data lives on your device
- **Cloud sync** — Sign in to sync across devices via Supabase
- **Family sharing** — Shared wallets and family groups
- **Backup & restore** — Never lose your financial history

---

## Platform Availability

| Platform | Status |
|----------|--------|
| Android | Available on [Google Play](https://play.google.com/store/apps/details?id=com.joy.bexly) |
| iOS | TestFlight Beta |
| Web | Available |
| Windows | Available |
| macOS | Available |
| Linux | Available |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter + Dart |
| **State** | Riverpod + Hooks |
| **Local DB** | Drift (SQLite) — 16 tables, offline-first |
| **Cloud** | Supabase (Auth, PostgreSQL, Edge Functions, Realtime) |
| **AI** | DOS AI (Qwen 3.5 via vLLM) + Gemini fallback |
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
┌─────────────────┐     ┌──────────────────┐
│   DOS AI (Qwen) │────▶│ Gemini (fallback) │
│   api.dos.ai    │     │ via Edge Function │
└─────────────────┘     └──────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Financial Context Injection     │
│ • Health Score    • Forecasts   │
│ • Budget status   • Anomalies  │
│ • Spending trends • Goals      │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Action Execution                │
│ • Create transactions           │
│ • Set budgets                   │
│ • Track goals                   │
│ • Product recommendations       │
└─────────────────────────────────┘
```

The AI doesn't just respond — it acts. Through the ACTION_JSON protocol, the AI can directly create transactions, set budgets, and manage goals within the conversation.

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

## License

This project is licensed under the **LGPL v3 License**. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with purpose by <a href="https://dos.ai">DOS Labs</a>
</p>
