# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Apple Sign In** setup for Android (Firebase configured with Service ID, Team ID, Key ID)
- **iOS Build Workflow** improvements (macos-15 runner for Xcode 16 support)
- **Telegram Bot: Default Wallet Sync**
  - App now syncs `defaultWalletCloudId` to Firestore when user sets default wallet
  - Telegram bot reads default wallet from user settings instead of picking first wallet
  - Fallback to first wallet if no default is set
- **Filter Form Localization** - All filter labels (Income, Expense, Transfer, Category, Wallet) now support 14 languages

### Fixed
- **Facebook App ID** corrected from DOS app to Bexly app (1583820202985076)
- Removed unused `oidc` and `flutter_web_auth_2` packages to resolve AppAuth version conflict
- **Notification delete dialog** now uses proper bottom sheet format (AlertBottomSheet)

### Changed
- iOS workflow simplified to signed builds only (removed unsigned job)
- Upgraded `google_sign_in` from 6.2.0 to 6.3.0

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