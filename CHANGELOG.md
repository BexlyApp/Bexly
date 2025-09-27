# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- AI Chat feature with OpenAI integration for natural language transaction creation
- Support for multiple currencies (VND/USD) with automatic conversion in AI Chat
- Budget form now allows selecting from all available wallets
- Transaction persistence from AI Chat to database with proper category matching
- Debug logging for AI transaction creation process

### Fixed
- Currency display issue when creating new wallet (was showing USD instead of selected currency)
- Non-functional edit wallet button on Home screen
- Bottom navigation tab labels corrected (Transactions → History, Analytics → Planning)
- Planning tab icon updated to Target02 for better clarity
- Wallet selector in Budget form not showing newly created wallets
- AI Chat messages disappearing after transaction creation
- Category matching in AI Chat with fallback to "Others" category

### Changed
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