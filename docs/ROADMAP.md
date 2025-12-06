# Bexly Development Roadmap

## Overview
This document outlines the development roadmap for Bexly, focusing on transforming it from a basic expense tracker to a comprehensive financial management platform with AI-powered features.

## Current State (v0.0.8+368)
- ✅ Core expense/income tracking
- ✅ Multi-wallet support with real-time cloud sync
- ✅ Budget management
- ✅ Category organization
- ✅ Basic analytics with line charts (weekly + 6-month trends)
- ✅ Offline-first with SQLite
- ✅ Android release (Play Store beta)
- ✅ AI chat assistant (Gemini integration)
- ✅ Recurring payments UI (list and form screens)
- ✅ Planning features (budgets and goals)
- ✅ **Real-time sync with Firestore (v167-194)**
- ✅ **Wallet edit without duplication bug (v194)**
- ✅ **Multi-language AI chat support (v257)**
- ✅ **Built-in category protection from cloud corruption (v257)**
- ✅ **Chat message deduplication (v250-v257)**
- ✅ **Vietnamese wallet type detection with 3-tier fuzzy matching (v286-288)**
- ✅ **UNIQUE constraint on wallet names to prevent duplicates (v286)**
- ✅ **Dynamic AI context updates for current wallet list (v287-288)**
- ✅ **SIM card currency detection with 3-level fallback (v314)**
- ✅ **Currency conversion in analytics charts (v317)**
- ✅ **Smart Y-axis scaling for better data visualization (v317)**
- ✅ **Avatar upload to Firebase Storage with sync to AI Chat (v350-356)**
- ✅ **Transparent PNG avatar support (v356)**
- ✅ **Recurring auto-create with duplicate prevention (v358)**
- ✅ **Recurring expiration check and auto-expire (v358)**
- ✅ **WorkManager background scheduling for recurring payments (v358)**
- ✅ **AI response format fix - no raw JSON display (v359)**
- ✅ **AI transaction type detection (trả=expense, thu=income) (v359)**
- ✅ **Privacy consent dialog with GDPR compliance (v360)**
- ✅ **Contextual notification permission request (v360)**
- ✅ **Default wallet selection for AI fallback (v363)**
- ✅ **Default wallet indicator in Manage Wallets screen (v363)**
- ✅ **Google Sign In working (v368)**
- ✅ **Apple Sign In configured for Android (v368)**
- ⏳ **Facebook Sign In** - pending Facebook App Review
- 🚧 **iOS Build Workflow** - needs Distribution certificate with private key

---

## Phase 0: Bank Integration & Compliance (Q1 2025) 🔥 PRIORITY

### 0.1 Plaid Integration Setup
**Priority: CRITICAL | Timeline: 2 weeks | Status: 🚧 IN PROGRESS**

Features:
- Plaid account setup and API configuration
- Development environment testing (Sandbox mode)
- Link Token generation endpoint
- Public token exchange flow
- Access token secure storage

Technical:
- `plaid_flutter` package integration
- Firebase Cloud Functions for token exchange
- Flutter Secure Storage for token management
- Plaid webhook handler setup

Products to integrate:
- ✅ Transactions ($0.30/account/month)
- ✅ Balance ($0.10/account/month)
- 🔜 Recurring Transactions ($0.15/account/month) - Phase 2

### 0.2 Bank Connection UI/UX
**Priority: CRITICAL | Timeline: 1 week**

Features:
- Plaid Link integration in app
- Bank account selection flow
- Connection status management
- Disconnect/reconnect functionality
- Multi-bank support

UI Components:
- Bank connection settings screen
- Connected accounts list
- Account health indicators
- Transaction sync status
- Manual sync trigger

### 0.3 Transaction Sync Engine
**Priority: HIGH | Timeline: 2 weeks**

Features:
- Initial transaction import (24-month history)
- Incremental sync (daily/webhook-based)
- Transaction deduplication logic
- Category mapping from Plaid to Bexly
- Conflict resolution (manual vs synced)

Technical:
- Background sync service
- Webhook receiver for real-time updates
- Transaction matching algorithm
- Sync status tracking per account

### 0.4 Security & Compliance
**Priority: CRITICAL | Timeline: 1 week**

Documentation:
- ✅ Privacy Policy (GDPR/CCPA compliant)
- ✅ Terms of Service
- ✅ Data Retention & Deletion Policy
- ✅ Security questionnaire responses

Technical Implementation:
- Database encryption (SQLCipher)
- Plaid token encryption at rest
- Secure communication (HTTPS/TLS)
- User consent management
- Account deletion workflow

### 0.5 Compliance & Legal
**Priority: CRITICAL | Timeline: 1 week**

Tasks:
- ✅ Complete Plaid security questionnaire
- ✅ Background check policy documentation
- 🔜 Publish Privacy Policy at bexly.app/privacy
- 🔜 Publish Terms of Service at bexly.app/terms
- 🔜 Implement consent dialogs
- 🔜 Data deletion automation (Cloud Functions)

Legal Documents:
- Data Processing Agreement (DPA) template
- User consent logging
- GDPR Article 17 compliance (Right to Erasure)
- GLBA 7-year retention for financial data

### 0.6 Production Readiness
**Priority: HIGH | Timeline: 1 week**

Requirements before Plaid Production approval:
- [ ] Privacy Policy published and linked in app
- [ ] Terms of Service published and linked in app
- [ ] Consent flow implemented (pre-Plaid Link)
- [ ] Data deletion functionality (30-day grace period)
- [ ] Automated cleanup jobs (Cloud Functions)
- [ ] Security audit checklist completed
- [ ] Plaid Production application submitted
- [ ] Test with 5-10 beta users in Sandbox

Monitoring:
- Plaid API error tracking
- Sync failure alerts
- Token expiration monitoring
- User consent audit logs

---

## Phase 1: Receipt & Document Management (Q1 2025)

### 1.1 Receipt Photo Capture
**Priority: HIGH | Timeline: 2 weeks | Status: ✅ COMPLETED**

Features:
- ✅ Camera integration for receipt photos
- ✅ Gallery picker for existing images
- ✅ Store locally with transactions
- ✅ Thumbnail preview in transaction list
- 🔜 Auto-crop and enhance

Technical:
- ✅ `image_picker` package
- ✅ Image compression/optimization
- ✅ Local file storage management

### 1.2 Invoice Scanner (Like Reference App)
**Priority: HIGH | Timeline: 3 weeks**

Features:
- Full invoice capture (multi-page)
- Document categorization (receipt/invoice/bill)
- PDF generation from photos
- Batch scanning mode
- Document templates

Technical:
- `flutter_document_scanner` or similar
- PDF creation with `pdf` package
- Template engine for invoices

### 1.3 Cloud Backup for Documents
**Priority: MEDIUM | Timeline: 1 week**

Features:
- Firebase Storage for premium users
- Automatic sync of receipts/invoices
- Cross-device access
- Storage quota management (5GB/user)

---

## Phase 2: Bill & Subscription Tracking (Q1-Q2 2025)

### 2.1 Recurring Transaction Management
**Priority: HIGH | Timeline: 2 weeks | Status: ✅ COMPLETED**

Features:
- ✅ Add recurring transactions (daily/weekly/monthly/yearly)
- ✅ List view with 3 tabs (Active, All, Paused)
- ✅ Form screen for add/edit (bottom sheet style)
- ✅ Category and wallet selection
- ✅ Enable reminder toggle
- ✅ Auto charge toggle
- ✅ Auto-create transactions on schedule (v358)
- ✅ Push notifications for recurring (v358)
- ✅ Track payment history (lastChargedDate, totalPayments)
- ✅ Duplicate prevention (v358)
- ✅ Auto-expire when endDate reached (v358)
- ✅ WorkManager background scheduling (v358)

Database Schema:
```sql
recurring_transactions:
  - id
  - name
  - amount
  - wallet_id (FK)
  - category_id (FK)
  - currency
  - frequency (enum: daily/weekly/monthly/yearly)
  - start_date
  - next_due_date
  - status (enum: active/paused/cancelled)
  - enable_reminder
  - reminder_days_before
  - auto_charge
  - notes
  - created_at
  - updated_at
```

Next Steps:
- ✅ Background job to auto-create transactions (v358 - WorkManager)
- 🔜 Integration with Plaid Recurring Transactions API
- ✅ Push notifications for due dates (v358 - recurring_notification_service.dart)
- 🔜 Smart detection of recurring patterns from transaction history

### 2.2 Subscription Analytics
**Priority: MEDIUM | Timeline: 1 week**

Features:
- Total monthly/yearly subscription cost
- Subscription timeline view
- Cost per category (entertainment/work/utilities)
- Unused subscription detection
- Price increase alerts

### 2.3 Bill Calendar
**Priority: MEDIUM | Timeline: 1 week**

Features:
- Calendar view of upcoming bills
- Color-coded by category
- Payment status indicators
- Drag-drop to reschedule
- Export to Google/Apple Calendar

---

## Phase 3: AI-Powered Features (Q2 2025)

### 3.1 Multi-Platform AI Chatbot Integration 🤖
**Priority: HIGH | Timeline: 4 weeks | Status: 🔜 PLANNED**

**Vision:** Let users manage finances through their favorite messaging platforms without opening the app.

**Supported Platforms:**
- **Telegram Bot** (Priority 1)
  - `/start` - Link Bexly account
  - `/expense` - Quick expense logging
  - `/balance` - Check wallet balances
  - `/report` - Get spending summary
  - Inline commands with natural language

- **Discord Bot** (Priority 2)
  - Server integration for team/family expenses
  - Slash commands for quick actions
  - Private DM for personal finance
  - Rich embeds for reports/analytics

- **Facebook Messenger** (Priority 3)
  - Chat-based expense tracking
  - Quick replies for common actions
  - Payment reminders
  - Budget alerts

- **Slack Bot** (Priority 4)
  - Business expense tracking
  - Team budget monitoring
  - Approval workflows
  - Receipt attachments

**Core Features (All Platforms):**
- Natural language expense/income logging
- Wallet balance inquiries
- Transaction history queries
- Spending insights and reports
- Budget status and alerts
- Bill payment reminders
- Receipt photo upload (via attachment)
- Multi-language support (EN/VI/ZH)

**Technical Architecture:**
```
User Message → Platform API → Firebase Cloud Function →
  ↓
Gemini AI (NLU) → Parse Intent & Extract Data →
  ↓
Bexly Backend API → Database Operations →
  ↓
Response Generator → Platform API → User
```

**Implementation:**
1. **Backend API Layer**
   - RESTful API for bot operations
   - Authentication with user tokens
   - Webhook handlers for each platform
   - Rate limiting and security

2. **AI Integration**
   - Reuse existing Gemini AI service
   - Platform-specific prompt engineering
   - Context management per conversation
   - Multi-turn dialogue support

3. **User Account Linking**
   - OAuth flow for secure linking
   - One-time pairing codes
   - Multi-device support
   - Unlink/revoke access

4. **Security & Privacy**
   - End-to-end encryption for sensitive data
   - No message storage on platform servers
   - GDPR-compliant data handling
   - User consent for each platform

**Monetization Integration:**
- Free tier: Basic commands (expense/income/balance)
- Premium: Advanced analytics, reports, AI insights
- Pro: Unlimited transactions, priority response
- Business: Team collaboration, admin controls

**Timeline Breakdown:**
- Week 1: Telegram bot MVP (basic expense logging)
- Week 2: Discord bot + backend API
- Week 3: Messenger integration
- Week 4: Slack bot + testing

**Success Metrics:**
- 20% of users enable at least one bot integration
- 50% of bot users become more active (higher transaction frequency)
- Bot users have 2x higher retention rate
- 15% conversion rate from free to premium via bot upsell

### 3.2 OCR Receipt Scanning
**Priority: HIGH | Timeline: 3 weeks**

Features:
- Extract amount, date, merchant automatically
- Multi-language support
- Auto-categorization based on merchant
- Line item extraction for itemized receipts
- Tax calculation detection

Technical:
- Google ML Kit or Tesseract
- Custom training for receipt formats
- Merchant database matching

### 3.3 Smart Categorization
**Priority: LOW | Timeline: 1 week**

Features:
- AI-powered auto-categorization
- Learn from user corrections
- Merchant-based rules
- Custom category suggestions

---

## Phase 4: Advanced Analytics (Q2-Q3 2025)

### 4.1 Predictive Analytics
**Priority: MEDIUM | Timeline: 2 weeks**

Features:
- Spending forecasts
- Cash flow predictions
- Budget overrun warnings
- Optimal payment scheduling
- Savings goal tracking

### 4.2 Financial Health Score
**Priority: LOW | Timeline: 1 week**

Features:
- Custom scoring algorithm
- Peer comparison (anonymous)
- Improvement suggestions
- Historical trend
- Achievement badges

### 4.3 Custom Reports
**Priority: MEDIUM | Timeline: 2 weeks**

Features:
- Customizable report builder
- Multiple export formats (PDF/Excel/CSV)
- Scheduled report generation
- Tax report preparation
- Business expense reports

---

## Phase 5: Platform Expansion (Q3 2025)

### 5.1 Web Application
**Priority: HIGH | Timeline: 4 weeks**

Features:
- Full-featured web app
- Responsive design
- Real-time sync
- Larger screen optimizations
- Bulk operations

### 5.2 Desktop Applications
**Priority: LOW | Timeline: 3 weeks**

Features:
- Windows native app
- macOS native app
- Linux support
- Offline mode
- System tray integration

### 5.3 Wearable Integration
**Priority: LOW | Timeline: 2 weeks**

Features:
- Apple Watch app
- Wear OS app
- Quick expense entry
- Spending alerts
- Budget status

---

## Phase 6: Social & Collaboration (Q4 2025)

### 6.1 Family Sharing
**Priority: MEDIUM | Timeline: 2 weeks**

Features:
- Shared wallets
- Family budgets
- Expense splitting
- Approval workflows
- Child accounts with limits

### 6.2 Bill Splitting
**Priority: MEDIUM | Timeline: 1 week**

Features:
- Group expense tracking
- Split by percentage/amount
- Settlement tracking
- Payment reminders
- Integration with payment apps

### 6.3 Financial Goals
**Priority: LOW | Timeline: 2 weeks**

Features:
- Shared savings goals
- Progress visualization
- Milestone celebrations
- Social accountability
- Goal templates

---

## Pre-Launch Requirements 🚀

### Onboarding & User Consent (P0-P1)
**Priority: CRITICAL | Status: ✅ COMPLETED (v360)**

#### User Flow:
```
Mở app lần đầu
    ↓
Onboarding screens (3-4 slides giới thiệu features)
    ↓
Privacy consent (nhẹ): "Chúng tôi sử dụng data để cải thiện app.
                        Xem Privacy Policy" [Đồng ý & Tiếp tục]
    ↓
Tạo wallet đầu tiên
    ↓
... dùng app bình thường ...
    ↓
Khi bật recurring/reminder lần đầu → Xin notification permission (contextual)
```

#### Tasks:
- ✅ Onboarding screens (3 slides)
  - Slide 1: Welcome + App intro
  - Slide 2: Powerful Features (Multi-wallet, AI, Budgets, Cloud Sync)
  - Slide 3: Setup Profile (Avatar, Name, Wallet)
- ✅ Privacy consent dialog (GDPR/CCPA compliant)
  - Simple notice với link Privacy Policy & Terms of Service
  - Lưu consent vào SharedPreferences
  - Shows before completing onboarding
- ✅ Contextual notification permission
  - Trigger khi user bật recurring reminder lần đầu
  - Pre-permission explanation dialog với benefits
  - Fallback to Settings nếu user đã từ chối trước đó

#### Technical:
- `shared_preferences` cho first launch check
- `introduction_screen` hoặc custom PageView
- `permission_handler` cho notification
- Firebase Analytics consent mode

---

## Technical Debt & Infrastructure

### Ongoing Improvements
- Increase test coverage to 80%
- Performance optimizations
- Accessibility improvements
- Internationalization (i18n)
- Security audits
- API versioning

### UI/UX Fixes
- **Fix Health category icon mapping (v235)**
  - Issue: Dental and Fitness both use `category-health-5` icon
  - Current icons: health-1 (parent), health-2 (Doctor Visits), health-3 (Pharmacy), health-4 (Insurance), health-5 (Fitness & Dental - DUPLICATE!)
  - Solution: Create `category-health-6.webp` for Dental (tooth icon) OR reassign existing icons
  - Priority: LOW | Timeline: 1 hour

### Migration Plans
- Consider moving to GraphQL
- Evaluate serverless architecture
- Implement event sourcing
- Add data warehouse for analytics

---

## Monetization Strategy & Pricing Plans 💰

### Philosophy
- **Freemium model** - Core features free, premium for power users
- **AI as USP** - AI Chat là unique selling point (competitors không có)
- **Low barrier** - Giá thấp ($2.99-$5.99) để maximize conversion
- **Cost-conscious** - Free tier chỉ tốn ~$0.03/user/month (30 AI messages)
- **Target**: 10% free-to-premium conversion

### Cost Analysis (Per User/Month)
| Item | Free | Premium | Pro |
|------|------|---------|-----|
| AI Chat (Gemini) | $0.03 (30 msgs) | $0.05 (50 msgs) | $0.50 (unlimited) |
| Google Drive | $0 (user storage) | - | - |
| Firebase Sync | - | $0.01 | $0.01 |
| Firebase Storage | - | $0.10 (1GB) | $0.50 (unlimited) |
| **Total Cost** | **~$0.03** | **~$0.16** | **~$1.01** |

---

### 🆓 Free Tier (Forever Free)
**Target Audience:** Casual users, students, individuals starting financial tracking

**Limits:**
- 2 wallets max
- 2 budgets max
- 2 goals max
- 2 recurring transactions max
- 1 currency only (all wallets use same currency)

**Core Features:**
- ✅ Basic expense/income tracking (unlimited transactions)
- ✅ Manual transaction entry
- ✅ 15 built-in categories + subcategories
- ✅ Dark/light mode
- ✅ Offline-first (all data stored locally)

**AI Chat:**
- ✅ 30 messages per month
- ✅ Natural language expense logging
- ✅ Basic spending insights

**Analytics:**
- ✅ Last month + Current month data
- ✅ Basic pie charts (spending by category)
- ❌ No trend analysis

**Backup:**
- ✅ **Google Drive auto-backup** (weekly)
- ✅ Manual JSON export/import
- ❌ No real-time sync across devices

**Not Included:**
- ❌ Multi-currency
- ❌ Receipt photos
- ❌ Firebase real-time sync
- ❌ Bot integration

---

### 💎 Premium ($2.99/month or $29.99/year - Save 17%)
**Target Audience:** Active users needing more flexibility and sync

**Everything in Free, PLUS:**

**Unlimited:**
- ✅ Unlimited wallets
- ✅ Unlimited budgets
- ✅ Unlimited goals
- ✅ Unlimited recurring transactions

**Multi-Currency:**
- ✅ Different currency per wallet
- ✅ Auto exchange rate updates
- ✅ Currency conversion in reports

**AI Chat:**
- ✅ **50 messages per month**
- ✅ Smart category suggestions
- ✅ Spending pattern detection

**Analytics:**
- ✅ **6-month trend charts**
- ✅ Income vs expense comparison
- ✅ Category trends over time
- ✅ Budget vs actual tracking

**Cloud Sync:**
- ✅ **Firebase real-time sync** across devices
- ✅ Multi-device support (phone, tablet, web)
- ✅ Automatic backup

**Document Management:**
- ✅ Receipt photo attachments
- ✅ **1GB cloud storage** for receipts
- ✅ Photo gallery view

**Export:**
- ✅ CSV export for transactions
- ✅ PDF monthly reports

---

### 🚀 Pro ($5.99/month or $59.99/year - Save 17%)
**Target Audience:** Power users, freelancers needing full features

**Everything in Premium, PLUS:**

**AI Superpowers:**
- ✅ **Unlimited AI messages**
- ✅ AI-powered financial insights & recommendations
- ✅ Smart budget recommendations
- ✅ Spending anomaly detection

**Advanced Analytics:**
- ✅ **All historical data** (không giới hạn thời gian)
- ✅ Custom date range reports
- ✅ Financial health score
- ✅ Predictive spending forecasts

**Document Management Pro:**
- ✅ **Unlimited cloud storage** for receipts
- ✅ **Receipt OCR** (future) - extract data from photos
- ✅ Batch photo upload

**Priority Support:**
- ✅ Email support with 24h response time
- ✅ Feature request priority
- ✅ Early access to new features

---

### 📊 Pricing Comparison Table

| Feature | Free | Premium | Pro |
|---------|------|---------|-----|
| **Price** | $0 | $2.99/mo | $5.99/mo |
| **Wallets** | 2 | Unlimited | Unlimited |
| **Budgets** | 2 | Unlimited | Unlimited |
| **Goals** | 2 | Unlimited | Unlimited |
| **Recurring** | 2 | Unlimited | Unlimited |
| **Currency** | 1 only | Multi-currency | Multi-currency |
| **AI Messages** | 30/month | 50/month | Unlimited |
| **Analytics** | 2 months | 6 months | All history |
| **Backup** | Google Drive | Firebase Sync | Firebase Sync |
| **Receipt Storage** | ❌ | 1GB | Unlimited |
| **Receipt OCR** | ❌ | ❌ | ✅ (future) |
| **Support** | Community | Email | Priority |

---

### 💡 Implementation Strategy

**Phase 1: RevenueCat Integration**
- Setup RevenueCat for subscription management
- Create products in App Store Connect & Google Play Console
- Implement paywall UI
- Handle subscription states (active, expired, grace period)

**Phase 2: Feature Gating**
- Create `SubscriptionService` to check user tier
- Gate features based on subscription:
  - Wallet count limit
  - AI message counter (reset monthly)
  - Analytics date range
  - Storage quota check
- Show upgrade prompts when limits reached

**Phase 3: Google Drive Backup (Free tier)**
- Integrate `googleapis` package
- Request Google Drive scope during auth
- Implement weekly auto-backup with WorkManager
- Export all data to JSON → Upload to Drive

**Phase 4: Usage Tracking**
- Track AI message usage per month
- Track storage usage for receipts
- Show usage in Settings screen
- Reset counters on subscription renewal

---

### 🎯 Conversion Funnels

**Free-to-Premium Funnel:**
1. User downloads app, uses free tier
2. Hits limit (3rd wallet, 31st AI message, etc.)
3. Soft paywall: "Upgrade for more"
4. **7-day free trial** of Premium
5. Target: 10% conversion rate

**Premium-to-Pro Funnel:**
1. Premium user hits 50 AI messages
2. Wants to see older analytics
3. Needs more receipt storage
4. In-app prompt: "Upgrade for unlimited"
5. Target: 15% of Premium users

---

### 📈 Revenue Projections

**Conservative Estimate (Year 1):**
- 10,000 free users
- 5% convert to Premium (500 users) = $1,495/month
- 10% of Premium upgrade to Pro (50 users) = $299/month
- **Total MRR: ~$1,800** = $21,600 ARR

**Optimistic Estimate (Year 1):**
- 50,000 free users
- 10% convert to Premium (5,000 users) = $14,950/month
- 15% of Premium upgrade to Pro (750 users) = $4,492/month
- **Total MRR: ~$19,400** = $233,000 ARR

**Cost Structure (at 50K users):**
- Free tier costs: 45K × $0.03 = $1,350/month
- Premium costs: 5K × $0.16 = $800/month
- Pro costs: 750 × $1.01 = $757/month
- **Total Costs: ~$2,900/month**
- **Gross Margin: 85%**

---

## Success Metrics

### User Acquisition
- Month 1: 1,000 downloads
- Month 6: 10,000 active users
- Year 1: 50,000 registered users

### Monetization
- 10% free-to-premium conversion
- <5% monthly churn
- Premium LTV: $36 (12-month retention @ $2.99/mo)
- Pro LTV: $72 (12-month retention @ $5.99/mo)
- Target: Break-even at ~$0.03/free user/month (AI costs)

### Engagement
- 60% weekly active users
- 5+ transactions per week
- 2-minute average session

### Technical
- 99.9% uptime
- <2s page load
- <100ms transaction save
- 4.5+ app store rating

---

## Risk Mitigation

### Technical Risks
- Cloud cost overruns → Implement usage quotas
- Data privacy concerns → End-to-end encryption
- Platform changes → Abstract dependencies

### Market Risks
- Competition from banks → Focus on UX
- Economic downturn → Emphasize saving features
- Regulatory changes → Stay compliant

### Execution Risks
- Feature creep → Stick to MVP
- Technical debt → Regular refactoring
- Burnout → Sustainable pace

---

## Next Steps

1. **Immediate** (Next 2 weeks) - Phase 0 Critical Path:
   - ✅ Complete Plaid security questionnaire
   - 🔜 Publish Privacy Policy and Terms of Service
   - 🔜 Implement user consent dialogs
   - 🔜 Setup Firebase Cloud Functions for Plaid
   - 🔜 Integrate Plaid Flutter SDK
   - 🔜 Build bank connection UI
   - 🔜 Test in Plaid Sandbox with 5 users

2. **Short-term** (Next month) - Plaid Production Launch:
   - 🔜 Implement transaction sync engine
   - 🔜 Add data deletion automation
   - 🔜 Submit Plaid Production application
   - 🔜 Launch Premium tier ($6.99/mo with bank sync)
   - 🔜 Beta test with 50 paid users
   - 🔜 Monitor Plaid costs and sync reliability

3. **Mid-term** (2-3 months) - Feature Enhancement:
   - Auto-detect recurring payments (Plaid Recurring API)
   - ✅ Receipt photo capture (DONE)
   - ✅ Push notifications for bills (DONE - v358)
   - Invoice scanner with OCR
   - Budget vs actual tracking with bank data

4. **Long-term** (Next quarter) - Scale & Optimize:
   - Launch OCR features
   - Deploy web application
   - Optimize Plaid costs (caching, smart sync)
   - Expand to Canada market
   - Implement fraud detection