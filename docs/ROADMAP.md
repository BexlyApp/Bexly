# Pockaw Development Roadmap

## Overview
This document outlines the development roadmap for Pockaw, focusing on transforming it from a basic expense tracker to a comprehensive financial management platform with AI-powered features.

## Current State (v1.94)
- ✅ Core expense/income tracking
- ✅ Multi-wallet support with real-time cloud sync
- ✅ Budget management
- ✅ Category organization
- ✅ Basic analytics
- ✅ Offline-first with SQLite
- ✅ Android release (Play Store beta)
- ✅ AI chat assistant (Gemini integration)
- ✅ Recurring payments UI (list and form screens)
- ✅ Planning features (budgets and goals)
- ✅ **Real-time sync with Firestore (v167-194)**
- ✅ **Wallet edit without duplication bug (v194)**

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

### 3.1 OCR Receipt Scanning
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

### 3.2 AI Financial Assistant
**Priority: MEDIUM | Timeline: 2 weeks**

Features:
- Chat interface for financial queries
- Spending insights and patterns
- Budget recommendations
- Bill negotiation tips
- Savings opportunities

Technical:
- OpenAI/Claude API integration
- Context-aware responses
- Transaction history analysis

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

### Migration Plans
- Consider moving to GraphQL
- Evaluate serverless architecture
- Implement event sourcing
- Add data warehouse for analytics

---

## Monetization Timeline

### Free Tier (Always)
- Basic expense tracking
- 3 wallets
- Manual backups
- Basic categories

### Premium ($6.99/month) - Phase 1
- Unlimited wallets
- Cloud sync
- Receipt photos
- Recurring transactions
- Bill tracking
- **Bank account sync (Plaid integration)**
- Real-time balance updates
- Automatic transaction import

### Pro ($9.99/month) - Phase 3
- Everything in Premium
- AI-powered insights
- OCR receipt scanning
- Advanced analytics
- Custom reports
- Auto-detect recurring payments (Plaid Recurring API)
- Priority support
- Export to Excel/PDF

### Business ($9.99/month) - Phase 5
- Team collaboration
- Approval workflows
- API access
- White-label options
- Dedicated support

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