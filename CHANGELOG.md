# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.10+370] - 2025-12-10

### Added
- **Facebook Messenger Bot Integration**
  - Create transactions via Messenger chat
  - Same AI-powered parsing as Telegram bot
  - Link/unlink Messenger account from app
  - Unified link-account page for all platforms
- **Multi-AI Provider Support for Bots**
  - Support Gemini, OpenAI, Claude (configurable)
  - Gemini systemInstruction for implicit caching (75% token savings)
  - Easy to switch providers via config
- **Category Sync to Cloud**
  - Categories now sync to Firestore during fullSync()
  - Bot can access user's full category list

### Fixed
- Vietnamese currency detection - "tr/k" only implies VND in Vietnamese context
- AI empty category fallback to "Other" or "Other Income"
- Increased maxOutputTokens to 300 to prevent JSON truncation

### Changed
- Bot response time improved from 2+ minutes to ~15 seconds
- Unified prompt between Telegram and Messenger bots

---

## [0.0.9+369] - 2025-12-09

### Added
- **Auto Transaction from SMS** (Android)
  - Scan SMS inbox to detect bank transactions
  - Support Vietnamese banks: Vietcombank, Techcombank, TPBank, BIDV, MB Bank, ACB, VPBank, etc.
  - Auto-create wallets for detected bank accounts
  - Link bank SMS to existing wallets
  - Import historical transactions from SMS
- **Auto Transaction from Notifications** (Android)
  - Listen for banking app push notifications
  - Store pending notifications when app is in background
  - Process pending notifications on app startup
  - Support multi-account per bank (detect account by last 4 digits)
- **Telegram Bot Integration**
  - Create transactions via Telegram chat
  - AI-powered transaction parsing with Gemini
  - Link/unlink Telegram account from app
  - Default wallet sync to Firestore for bot
- **Subscription System**
  - Free tier with ads and limited AI messages
  - Plus tier ($2.99/month) with no ads and more AI
  - Pro tier ($5.99/month) with unlimited AI
  - AI usage tracking and limits
- **AdMob Integration** for free tier users
- **Apple Sign In** setup for Android
- **Filter Form Localization** - All filter labels support 14 languages
- **Dedicated Language Settings Screen**

### Fixed
- Facebook App ID corrected for Bexly app
- iOS build workflow improvements (Xcode 16 support)
- Notification delete dialog uses proper bottom sheet format
- Various UI improvements and localization fixes

### Changed
- iOS workflow simplified to signed builds only
- Upgraded `google_sign_in` from 6.2.0 to 6.3.0
- Improved notification card UI

---

## [0.0.8+368] - 2025-12-06

### Added
- **Cloud Sync with Conflict Resolution**
  - Initial cloud sync triggered automatically after first login
  - UUID v7 cloudId for globally unique identifiers across devices
  - Conflict detection when both local and cloud data exist
  - Interactive conflict resolution dialog showing:
    - Item counts (wallets + transactions)
    - Last updated timestamps
    - Latest transaction details
  - User choice: Keep Local Data or Use Cloud Data
  - Sync status tracking with SharedPreferences
  - Reset sync status on logout for testing
- AI Chat feature with OpenAI integration for natural language transaction creation
- Support for multiple currencies (VND/USD) with automatic conversion in AI Chat
- Budget form now allows selecting from all available wallets
- Transaction persistence from AI Chat to database with proper category matching
- Debug logging for AI transaction creation process
- Logger.w() method for warning messages

### Fixed
- Currency display issue when creating new wallet (was showing USD instead of selected currency)
- Non-functional edit wallet button on Home screen
- Bottom navigation tab labels corrected (Transactions → History, Analytics → Planning)
- Planning tab icon updated to Target02 for better clarity
- Wallet selector in Budget form not showing newly created wallets
- AI Chat messages disappearing after transaction creation
- Category matching in AI Chat with fallback to "Others" category
- UUID v7 generator by removing non-existent V7Options

### Changed
- **Cloud Sync Integration**
  - Google/Facebook/Apple Sign In now trigger cloud sync after authentication
  - Drift API usage updated for wallet insert/update operations
  - Database schema v11 with cloudId field on all sync tables
- AI Chat provider now uses keepAlive to preserve chat history across wallet changes
- Improved currency conversion logic between VND and USD (1 USD = 25,000 VND)
- Enhanced error handling and logging in AI transaction creation

## [0.1.0] - 2024-01-XX

### Initial Release
- Multi-wallet support with different currencies
- Transaction tracking (income/expense)
- Budget management
- Goal setting
- Basic analytics and reporting
- Firebase authentication with DOS-Me project integration
- Local database with Drift
- Dark/light theme support