# Pockaw Development Roadmap

## Overview
This document outlines the development roadmap for Pockaw, focusing on transforming it from a basic expense tracker to a comprehensive financial management platform with AI-powered features.

## Current State (v0.0.7+359)
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
**Priority: HIGH | Timeline: 2 weeks**

Features:
- Camera integration for receipt photos
- Gallery picker for existing images
- Auto-crop and enhance
- Store locally with transactions
- Thumbnail preview in transaction list

Technical:
- `image_picker` package
- Image compression/optimization
- Local file storage management

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
- 🔜 Auto-create transactions on schedule
- 🔜 Notification before due date
- 🔜 Track payment history

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
- 🔜 Background job to auto-create transactions
- 🔜 Integration with Plaid Recurring Transactions API
- 🔜 Push notifications for due dates
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
- **Freemium model** with generous free tier to attract users
- **Value-based pricing** - Premium features justify $6.99/month price point
- **Bot integration upsell** - Chatbots drive conversion to paid tiers
- **Platform costs covered** - Plaid costs (~$0.40/user/month) covered by Premium tier
- **Target**: 5% free-to-premium conversion = 1,000 paid users at 20K MAU

---

### 🆓 Free Tier (Forever Free)
**Target Audience:** Casual users, students, individuals starting financial tracking

**Core Features:**
- ✅ Basic expense/income tracking (unlimited transactions)
- ✅ 3 wallets (e.g., Cash, Bank, Credit Card)
- ✅ Manual transaction entry
- ✅ 15 built-in categories + subcategories
- ✅ Basic monthly reports (pie charts)
- ✅ Manual backups (export to JSON)
- ✅ Budget tracking (3 budgets max)
- ✅ Goal tracking (3 goals max)
- ✅ Multi-currency support
- ✅ Dark/light mode

**AI Chat Limitations:**
- 20 AI messages per month
- Basic natural language expense logging
- No advanced insights or recommendations

**Bot Access:**
- ❌ No Telegram/Discord/Messenger/Slack bot integration

**Analytics:**
- Basic pie charts (spending by category)
- Current month overview only
- No trend analysis

**Sync & Backup:**
- Manual backup/restore only
- No cloud sync across devices

**Expected User Behavior:**
- 60% of users stay on Free tier
- Average 50 transactions/month
- 3-month median retention

---

### 💎 Premium ($6.99/month or $69.99/year - Save 16%)
**Target Audience:** Active users needing cloud sync and automation

**Everything in Free, PLUS:**

**Wallets & Sync:**
- ✅ Unlimited wallets
- ✅ **Real-time cloud sync** across all devices
- ✅ Automatic backup to Firebase
- ✅ Multi-device support (phone, tablet, web)

**Bank Integration (Phase 0):**
- ✅ **Plaid bank account sync** (US banks)
- ✅ Auto-import transactions (24-month history)
- ✅ Real-time balance updates
- ✅ Connect up to 5 bank accounts
- ✅ Transaction deduplication & matching

**Automation:**
- ✅ Recurring transactions (unlimited)
- ✅ Auto-create scheduled transactions
- ✅ Bill reminders with push notifications
- ✅ Payment due date tracking

**AI Features:**
- ✅ **100 AI messages per month**
- ✅ Advanced natural language processing
- ✅ Smart category suggestions
- ✅ Spending pattern detection
- ✅ **Basic bot access (1 platform)** - Telegram OR Discord OR Messenger

**Analytics:**
- ✅ 6-month trend charts (income vs expense)
- ✅ Weekly spending breakdown
- ✅ Category comparison over time
- ✅ Budget vs actual tracking

**Document Management:**
- ✅ Receipt photo attachments (5GB cloud storage)
- ✅ Document categorization
- ✅ Receipt search by merchant/amount

**Export:**
- ✅ CSV export for transactions
- ✅ PDF monthly reports

**Expected User Behavior:**
- 30% of free users convert to Premium within 6 months
- Average 150 transactions/month
- 12-month median retention
- Churn rate: <5% monthly

**Value Proposition:**
- Bank sync alone worth $6.99/month (replaces manual entry)
- Saves 30 minutes/week on transaction logging
- Bot integration increases engagement by 2x

---

### 🚀 Pro ($14.99/month or $149.99/year - Save 17%)
**Target Audience:** Power users, freelancers, small business owners

**Everything in Premium, PLUS:**

**AI Superpowers:**
- ✅ **Unlimited AI messages**
- ✅ **OCR receipt scanning** (extract data from photos)
- ✅ AI-powered financial insights & recommendations
- ✅ Predictive analytics (cash flow forecasts)
- ✅ Smart budget recommendations
- ✅ Spending anomaly detection
- ✅ **All bot platforms** - Telegram + Discord + Messenger + Slack

**Advanced Analytics:**
- ✅ Custom report builder
- ✅ 12-month+ historical data
- ✅ Predictive spending forecasts
- ✅ Financial health score
- ✅ Peer comparison (anonymous benchmarking)
- ✅ Tax report preparation

**Bank Integration Pro:**
- ✅ Connect unlimited bank accounts
- ✅ **Plaid Recurring Transactions API** (auto-detect subscriptions)
- ✅ Auto-categorize recurring payments
- ✅ Subscription cost tracking & alerts

**Document Management Pro:**
- ✅ Unlimited cloud storage for receipts
- ✅ Invoice scanner (multi-page PDF)
- ✅ Document templates
- ✅ Batch scanning mode

**Export & Integrations:**
- ✅ Excel export with formatting
- ✅ PDF reports with charts
- ✅ API access (read-only)
- ✅ Zapier integration
- ✅ Scheduled report emails (weekly/monthly)

**Priority Support:**
- ✅ Email support with 24h response time
- ✅ Chat support (business hours)
- ✅ Feature request priority

**Expected User Behavior:**
- 10% of Premium users upgrade to Pro
- Average 300+ transactions/month
- 18-month median retention
- Churn rate: <3% monthly

**Value Proposition:**
- OCR saves 1 hour/week on manual entry
- AI insights help save $200+/month on average
- Bot access on all platforms = manage finances anywhere

---

### 🏢 Business ($24.99/month per user or $249.99/year - Save 17%)
**Target Audience:** Teams, families, small businesses (5+ users)

**Everything in Pro, PLUS:**

**Team Collaboration:**
- ✅ Shared wallets with role-based permissions
- ✅ Team budgets with approval workflows
- ✅ Expense submission & approval
- ✅ Multi-level approval chains
- ✅ Audit logs for all transactions

**Family Features:**
- ✅ Family expense tracking
- ✅ Child accounts with spending limits
- ✅ Allowance automation
- ✅ Shared goals (e.g., vacation fund)
- ✅ Parental controls

**Business Tools:**
- ✅ Invoice generation & tracking
- ✅ Client/project expense tracking
- ✅ Mileage tracking with GPS
- ✅ Tax category mapping
- ✅ Multi-currency transactions
- ✅ Reimbursement workflows

**Advanced Integrations:**
- ✅ QuickBooks integration
- ✅ Xero integration
- ✅ API access (full CRUD)
- ✅ Webhook notifications
- ✅ Custom integrations

**Support & Customization:**
- ✅ Dedicated account manager
- ✅ Priority phone support
- ✅ Custom onboarding
- ✅ White-label options (Enterprise)
- ✅ SLA guarantee (99.9% uptime)

**Pricing Structure:**
- Minimum 5 users
- Volume discounts: 10+ users = 15% off, 25+ users = 25% off
- Annual billing only

**Expected User Behavior:**
- 5% of Pro users upgrade to Business
- Average 500+ transactions/user/month
- 24-month median retention (B2B stickiness)
- Churn rate: <2% monthly
- $500+ LTV per user

**Value Proposition:**
- Replaces multiple tools (Expensify, FreshBooks, Splitwise)
- Saves 10+ hours/month on expense management
- Team collaboration increases financial transparency

---

### 📊 Pricing Comparison Table

| Feature | Free | Premium | Pro | Business |
|---------|------|---------|-----|----------|
| **Price** | $0 | $6.99/mo | $14.99/mo | $24.99/user/mo |
| **Wallets** | 3 | Unlimited | Unlimited | Unlimited |
| **Cloud Sync** | ❌ | ✅ | ✅ | ✅ |
| **Bank Sync (Plaid)** | ❌ | ✅ (5 accounts) | ✅ (Unlimited) | ✅ (Unlimited) |
| **AI Messages** | 20/month | 100/month | Unlimited | Unlimited |
| **Bot Platforms** | ❌ | 1 platform | All platforms | All platforms |
| **OCR Receipt Scan** | ❌ | ❌ | ✅ | ✅ |
| **Cloud Storage** | ❌ | 5GB | Unlimited | Unlimited |
| **Recurring Detection** | ❌ | Manual | Auto (Plaid API) | Auto + Custom |
| **Team Collaboration** | ❌ | ❌ | ❌ | ✅ |
| **API Access** | ❌ | ❌ | Read-only | Full CRUD |
| **Support** | Community | Email | Priority Email + Chat | Dedicated Manager |

---

### 💡 Monetization Strategy Deep Dive

**Phase 1 (Q1 2025): Launch Premium with Plaid**
- Goal: 1,000 Premium subscribers = $7K MRR
- Covers Plaid costs (~$400/month) + infrastructure
- Break-even at 500 subscribers

**Phase 2 (Q2 2025): Bot Integration Upsell**
- Telegram bot free trial (14 days) → Premium conversion
- Bot users have 3x higher conversion rate
- Goal: 500 new Premium users from bot funnel

**Phase 3 (Q2 2025): Launch Pro Tier with OCR**
- Goal: 300 Pro subscribers = $4.5K MRR
- Targets power users and freelancers
- OCR feature is main differentiator

**Phase 4 (Q3 2025): Business Tier Launch**
- Goal: 50 business accounts (250 users) = $6.25K MRR
- B2B sales motion (direct outreach, partnerships)
- Higher LTV offsets higher CAC

**Total Revenue Target (End of 2025):**
- Free: 18,000 users (90%)
- Premium: 1,500 users (7.5%) = $10.5K MRR
- Pro: 400 users (2%) = $6K MRR
- Business: 100 accounts (500 users, 0.5%) = $12.5K MRR
- **Total MRR: $29K** = $348K ARR

**Cost Structure:**
- Plaid: $600/month (1,500 Premium users @ $0.40)
- Firebase/Cloud: $1,500/month (storage, functions, hosting)
- Gemini AI: $800/month (API calls, bot usage)
- Infrastructure: $500/month (monitoring, CDN, etc.)
- **Total Costs: ~$3,400/month**
- **Gross Margin: 88%** ($29K - $3.4K = $25.6K profit)

**CAC & LTV:**
- Free user CAC: $2 (organic, ASO, content marketing)
- Premium CAC: $15 (in-app upsell, email campaigns)
- Pro CAC: $40 (targeted ads, bot integration)
- Business CAC: $200 (direct sales, partnerships)

- Premium LTV: $84 (12-month retention @ $6.99/mo)
- Pro LTV: $270 (18-month retention @ $14.99/mo)
- Business LTV: $600+ (24-month retention @ $24.99/user/mo)

**Payback Period:**
- Premium: 2 months (CAC $15 / $6.99 MRR)
- Pro: 3 months (CAC $40 / $14.99 MRR)
- Business: 8 months (CAC $200 / $24.99 MRR)

---

### 🎯 Conversion Funnels

**Bot-to-Premium Funnel:**
1. User discovers Telegram bot via friend/community
2. Links Bexly account (free tier)
3. Uses bot for 1 week (20 free messages)
4. Hits message limit → Prompt to upgrade
5. **14-day Premium trial** with all bot platforms
6. After trial: 25% convert to Premium ($6.99/mo)

**Free-to-Premium Funnel:**
1. User downloads app, creates account
2. Uses free tier for 2-4 weeks
3. Reaches wallet limit (3 wallets) OR sync needs
4. In-app prompts: "Upgrade for unlimited wallets + cloud sync"
5. **7-day Premium trial**
6. After trial: 15% convert to Premium

**Premium-to-Pro Funnel:**
1. Premium user active for 3+ months
2. Uses AI chat heavily (hits 100 message limit)
3. Takes many receipt photos
4. In-app prompt: "Upgrade for unlimited AI + OCR"
5. Showcase OCR demo (scan receipt → auto-fill transaction)
6. **30-day Pro trial** (upgrade path, not separate trial)
7. After trial: 10% convert to Pro

**Pro-to-Business Funnel:**
1. Pro user adds family members (manual workaround)
2. Shares wallets via manual coordination
3. Pain point: "Need proper multi-user support"
4. In-app prompt: "Upgrade to Business for team collaboration"
5. Sales call with dedicated account manager
6. Custom demo with business features
7. After evaluation: 20% convert to Business

---

## Success Metrics

### User Acquisition
- Month 1: 1,000 downloads
- Month 6: 10,000 active users
- Year 1: 50,000 registered users

### Monetization
- 5% free-to-premium conversion
- <3% monthly churn
- $70+ LTV per premium user (increased due to Plaid value-add)
- Target: 1,000 paid users to cover Plaid costs (~$400/mo at $0.40/user)

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
   - Receipt photo capture
   - Push notifications for bills
   - Invoice scanner
   - Budget vs actual tracking with bank data

4. **Long-term** (Next quarter) - Scale & Optimize:
   - Launch OCR features
   - Deploy web application
   - Optimize Plaid costs (caching, smart sync)
   - Expand to Canada market
   - Implement fraud detection