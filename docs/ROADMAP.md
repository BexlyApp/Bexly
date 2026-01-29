# Bexly Development Roadmap

## Overview
This document outlines the development roadmap for Bexly, focusing on transforming it from a basic expense tracker to a comprehensive financial management platform with AI-powered features.

## Current State (v0.0.10+370)
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
- ✅ **Telegram Bot Integration (v369)** - Create transactions via Telegram chat
- ✅ **Facebook Messenger Bot Integration (v370)** - Create transactions via Messenger chat
- ✅ **Multi-AI Provider Support (v370)** - Gemini, OpenAI, Claude with easy switching
- ✅ **Category Sync to Cloud (v370)** - Bot can access user's full category list
- ✅ **Filter Form Localization** - All 14 languages supported for filter UI
- ✅ **Supabase Bidirectional Sync (v371)** - Full cloud sync (upload + download) for wallets, categories, transactions
- ✅ **Login Data Pull (v371)** - App now pulls user data from cloud after authentication
- ✅ **CloudId-based Sync Architecture (v371)** - UUID-based mapping to decouple local IDs from cloud IDs
- ⏳ **Facebook Sign In** - pending Facebook App Review
- 🚧 **iOS Build Workflow** - needs Distribution certificate with private key

---

## Phase 0A: Automated Transaction Input (Q1 2025) 🔥 NEW

> **Goal:** Tự động nhập liệu giao dịch cho user thông qua nhiều kênh: SMS, Notification, và Open Banking API.

### Research Summary

**Các phương pháp tự động nhập liệu:**

| Method | Pros | Cons | Effort |
|--------|------|------|--------|
| **SMS Parsing** | Hoạt động offline, không cần API của ngân hàng | Cần permission, mỗi bank format khác | Medium |
| **Notification Listener** | Đọc push notification từ banking apps | Android only, cần permission đặc biệt | Medium |
| **Open Banking API** | Chuẩn hóa, reliable, history data | Phí cao, không có ở VN | High |
| **Email Parsing** | Cross-platform, nhiều bank gửi email | User phải grant Gmail access | Medium |

### 0A.1 SMS Transaction Parsing (Priority 1)
**Timeline: 2 weeks | Platform: Android**

**How it works:**
- App xin permission `READ_SMS` và `RECEIVE_SMS`
- Background service lắng nghe SMS mới từ các số ngân hàng (VD: Vietcombank, TPBank, Techcombank...)
- AI (Gemini) parse SMS content → extract: amount, type (debit/credit), balance, merchant
- Auto-create pending transaction → User confirm hoặc app tự approve

**Technical Implementation:**
```dart
// SMS Receiver Service
flutter_sms_inbox + telephony package
- Foreground service for listening
- AI parsing với Gemini (cost: ~$0.001/SMS)
- Bank sender ID whitelist
- Template-based fallback parsing
```

**Challenges:**
- Mỗi ngân hàng format SMS khác nhau
- Một số bank dùng mã OTP chung với thông báo
- iOS không cho phép đọc SMS

**Reference Apps:**
- [Finout](https://iauro.com/finout-case-study/) - Smart SMS parsing
- [FinArt](https://play.google.com/store/apps/details?id=com.finart) - SMS + Notification

### 0A.2 Notification Listener Service (Priority 2)
**Timeline: 1 week | Platform: Android**

**How it works:**
- App yêu cầu NotificationListenerService permission
- Lắng nghe notification từ banking apps (VD: `com.vietcombank.banking`)
- Parse notification content với AI
- Auto-create transaction

**Technical Implementation:**
```dart
// NotificationListener
flutter_notification_listener package
- Filter by package name (whitelist banking apps)
- Extract notification text
- AI parse → transaction data
```

**Pros over SMS:**
- Không cần SMS permission (nhiều user ngại)
- Có thể đọc notification từ e-wallet (Momo, ZaloPay)
- Notification thường có format dễ parse hơn

**Cons:**
- User phải vào Settings grant permission
- Chỉ hoạt động trên Android

### 0A.3 Open Banking API Integration (Priority 3)
**Timeline: 4 weeks | Platform: All**

#### 🇻🇳 Vietnam Open Banking - Thông tư 64/2024/TT-NHNN

**QUAN TRỌNG:** Vietnam đã có Open Banking regulation!

| Mốc thời gian | Nội dung |
|---------------|----------|
| 31/12/2024 | Thông tư 64/2024/TT-NHNN được ban hành |
| **01/03/2025** | **Có hiệu lực** (đã active!) |
| 01/07/2025 | Banks phải có danh mục API và kế hoạch triển khai |
| 01/03/2027 | Banks phải tuân thủ đầy đủ |

**Yêu cầu cho bên thứ ba (fintech apps như Bexly):**
- Tuân thủ quy định về bảo mật dữ liệu cá nhân
- Xử lý dữ liệu đúng mục đích theo hợp đồng
- Hệ thống đáp ứng tối thiểu cấp độ 3 về an toàn thông tin

**References:**
- [Thông tư 64/2024 - LuatVietnam](https://luatvietnam.vn/tin-van-ban-moi/tu-01-3-2025-trien-khai-open-api-trong-nganh-ngan-hang-186-100851-article.html)
- [Vietnam Open Banking - Brankas Blog](https://blog.brankas.com/Vietnam-Open-Banking-with-Circular64)

---

#### Global Open Banking API Providers

**For US/Canada Market:**
| Provider | Coverage | Price | Notes |
|----------|----------|-------|-------|
| **[Plaid](https://plaid.com)** | 12,000+ FIs (US, CA, UK, EU) | $0.30-0.50/account/month | Market leader |
| **[MX](https://mx.com)** | 13,000+ FIs (US, CA only) | Contact sales | AI-powered categorization |
| **[Yodlee](https://yodlee.com)** | 17,000+ (US, CA, UK, AU, India) | Contact sales | Acquired by STG 6/2025 |
| **[Finicity](https://finicity.com)** | US, CA | Contact sales | Mastercard owned, lending focus |

**For Europe:**
| Provider | Coverage | Notes |
|----------|----------|-------|
| **[TrueLayer](https://truelayer.com)** | 16 EU markets, 95%+ coverage | UK/EU only, no Asia |
| **[Salt Edge](https://saltedge.com)** | 50+ countries, 5,000+ banks | Best global coverage |
| **[Yapily](https://yapily.com)** | 19 EU countries, 2,000+ FIs | Enterprise focus |

**For Southeast Asia:**
| Provider | Coverage | AIS (Transaction Data) | Notes |
|----------|----------|------------------------|-------|
| **[Brankas](https://brankas.com)** | ID, PH, VN, TH | ❌ Payment only | Partnership with Gimasys for VN |
| **Brick** | Indonesia | ❓ Need verify | - |

**⚠️ Note:** Brankas chỉ cung cấp Payment APIs (Direct, Disburse), KHÔNG có Account Information Service (AIS) để pull transaction history cho personal finance apps.

### 0A.4 Email Transaction Sync (Priority 4)
**Timeline: 3-4 weeks | Platform: All | Status: 📋 PLANNED**

#### Overview
Scan user's email inbox for banking transaction notifications and automatically extract transaction data using AI. This is a **cross-platform solution** that works regardless of phone manufacturer or bank.

#### Why Email Sync?

| Method | Platform | Coverage | Reliability |
|--------|----------|----------|-------------|
| SMS Parsing | Android only | VN banks | High (structured) |
| FinanceKit | iOS only, US only | Apple Wallet | Limited |
| Open Banking | Region-specific | Bank dependent | API changes |
| **Email Sync** | **All platforms** | **All banks** | **Medium-High** |

**Advantages:**
- ✅ Works on iOS, Android, Web, Desktop
- ✅ Works globally (any bank that sends email)
- ✅ User already has email notifications enabled
- ✅ Historical data (can scan past emails)
- ✅ No need for bank API integration
- ✅ Privacy: user controls which emails to scan

**Disadvantages:**
- ❌ Requires Gmail OAuth (complex setup)
- ❌ Email format varies by bank (AI parsing needed)
- ❌ Slight delay (email delivery time)
- ❌ Some users don't enable email notifications

---

#### Banks That Send Email Notifications

**🇻🇳 Vietnam:**
| Bank | Email Notifications | Format Quality |
|------|---------------------|----------------|
| Vietcombank | ✅ Có (phải bật) | Good - structured |
| BIDV | ✅ Có (phải bật) | Good |
| Techcombank | ✅ Có | Medium |
| VPBank | ✅ Có | Medium |
| MB Bank | ✅ Có | Good |
| ACB | ✅ Có | Medium |
| TPBank | ✅ Có | Good |
| Sacombank | ✅ Có | Medium |

**🌍 International:**
| Bank | Email Notifications | Notes |
|------|---------------------|-------|
| Chase | ✅ Detailed | Amount, merchant, category |
| Citi | ✅ Detailed | Real-time alerts |
| HSBC | ✅ Standard | Basic info |
| Bank of America | ✅ Detailed | Customizable alerts |
| Wells Fargo | ✅ Standard | Transaction alerts |
| Capital One | ✅ Detailed | Instant notifications |

---

#### Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        USER FLOW                             │
├─────────────────────────────────────────────────────────────┤
│  1. User taps "Connect Email" in Settings                    │
│  2. OAuth consent screen (Gmail)                             │
│  3. Grant read-only access to emails                         │
│  4. Cloud Function starts scanning                           │
│  5. Transactions appear in app (with "Email" source tag)     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    SYSTEM ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────────┐    ┌─────────────────┐   │
│  │  Flutter │───▶│   Firebase   │───▶│  Cloud Function │   │
│  │   App    │    │    Auth      │    │   (scheduled)   │   │
│  └──────────┘    └──────────────┘    └────────┬────────┘   │
│       │                                        │            │
│       │                                        ▼            │
│       │                               ┌─────────────────┐   │
│       │                               │   Gmail API     │   │
│       │                               │  (read-only)    │   │
│       │                               └────────┬────────┘   │
│       │                                        │            │
│       │                                        ▼            │
│       │                               ┌─────────────────┐   │
│       │                               │   Gemini AI     │   │
│       │                               │  (parse email)  │   │
│       │                               └────────┬────────┘   │
│       │                                        │            │
│       │                                        ▼            │
│       │                               ┌─────────────────┐   │
│       │                               │   Firestore     │   │
│       ◀───────────────────────────────│  (transactions) │   │
│       │                               └─────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

#### Implementation Details

**Phase 1: Gmail OAuth Setup (Week 1)**

```dart
// lib/features/email_sync/services/gmail_auth_service.dart

class GmailAuthService {
  // OAuth 2.0 scopes needed
  static const scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  Future<GoogleSignInAccount?> connectGmail() async {
    final googleSignIn = GoogleSignIn(
      scopes: scopes,
      // Request offline access for Cloud Function
      serverClientId: 'YOUR_WEB_CLIENT_ID',
    );
    return await googleSignIn.signIn();
  }

  // Get server auth code for Cloud Function
  Future<String?> getServerAuthCode() async {
    final account = await googleSignIn.signInSilently();
    return account?.serverAuthCode;
  }
}
```

**Phase 2: Cloud Function - Email Scanner (Week 2)**

```typescript
// functions/src/emailSync/scanBankingEmails.ts

import { gmail_v1, google } from 'googleapis';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { VertexAI } from '@google-cloud/vertexai';

// Known banking email domains
const BANK_DOMAINS = [
  // Vietnam
  'vietcombank.com.vn',
  'bidv.com.vn',
  'techcombank.com.vn',
  'vpbank.com.vn',
  'mbbank.com.vn',
  'acb.com.vn',
  'tpb.vn',
  'sacombank.com.vn',
  // International
  'chase.com',
  'citi.com',
  'notifications.citi.com',
  'email.capitalone.com',
  'alerts.bankofamerica.com',
];

// Run every 15 minutes
export const scanBankingEmails = onSchedule('every 15 minutes', async (event) => {
  const users = await getEmailSyncEnabledUsers();

  for (const user of users) {
    const gmail = await getGmailClient(user.refreshToken);
    const emails = await fetchBankingEmails(gmail, user.lastSyncTime);

    for (const email of emails) {
      const transaction = await parseEmailWithAI(email);
      if (transaction) {
        await saveTransaction(user.id, transaction);
      }
    }
  }
});

async function fetchBankingEmails(gmail: gmail_v1.Gmail, since: Date) {
  // Build query for banking emails
  const senderQuery = BANK_DOMAINS.map(d => `from:${d}`).join(' OR ');
  const query = `(${senderQuery}) after:${formatDate(since)}`;

  const response = await gmail.users.messages.list({
    userId: 'me',
    q: query,
    maxResults: 50,
  });

  return response.data.messages || [];
}
```

**Phase 3: AI Email Parsing (Week 2-3)**

```typescript
// functions/src/emailSync/parseEmailWithAI.ts

const PARSE_PROMPT = `
Extract transaction information from this banking email.
Return JSON with these fields:
- amount: number (positive for income, negative for expense)
- currency: string (VND, USD, etc.)
- merchant: string (who received/sent money)
- date: ISO date string
- type: 'expense' | 'income' | 'transfer'
- category_hint: string (suggested category like 'food', 'shopping', etc.)
- confidence: number (0-1, how confident you are)

If this is not a transaction email, return { "is_transaction": false }

Email content:
---
{EMAIL_BODY}
---
`;

async function parseEmailWithAI(emailHtml: string): Promise<Transaction | null> {
  const vertexai = new VertexAI({ project: 'bexly-app' });
  const model = vertexai.getGenerativeModel({ model: 'gemini-1.5-flash' });

  // Convert HTML to plain text
  const plainText = htmlToText(emailHtml);

  const result = await model.generateContent(
    PARSE_PROMPT.replace('{EMAIL_BODY}', plainText)
  );

  const jsonResponse = extractJSON(result.response.text());

  if (!jsonResponse.is_transaction || jsonResponse.confidence < 0.7) {
    return null;
  }

  return {
    amount: jsonResponse.amount,
    currency: jsonResponse.currency,
    merchant: jsonResponse.merchant,
    date: new Date(jsonResponse.date),
    categoryHint: jsonResponse.category_hint,
    source: 'email',
    sourceEmailId: emailId,
  };
}
```

**Phase 4: Flutter UI (Week 3-4)**

```dart
// lib/features/email_sync/presentation/screens/email_sync_settings_screen.dart

class EmailSyncSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(emailSyncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Email Sync')),
      body: Column(
        children: [
          // Connection status card
          EmailConnectionCard(
            isConnected: syncStatus.isConnected,
            email: syncStatus.connectedEmail,
            onConnect: () => _connectGmail(context, ref),
            onDisconnect: () => _disconnectGmail(ref),
          ),

          // Sync statistics
          if (syncStatus.isConnected) ...[
            SyncStatsCard(
              lastSync: syncStatus.lastSyncTime,
              transactionsFound: syncStatus.totalTransactions,
              pendingReview: syncStatus.pendingReview,
            ),

            // Bank filter settings
            BankFilterSettings(
              enabledBanks: syncStatus.enabledBanks,
              onToggle: (bank, enabled) => _toggleBank(ref, bank, enabled),
            ),

            // Manual sync button
            ElevatedButton.icon(
              icon: Icon(Icons.sync),
              label: Text('Sync Now'),
              onPressed: () => _triggerManualSync(ref),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

#### Database Schema

```dart
// lib/core/database/tables/email_sync_table.dart

class EmailSyncSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get gmailEmail => text().nullable()();
  TextColumn get encryptedRefreshToken => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  TextColumn get enabledBanks => text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// Add to Transaction table
class Transactions extends Table {
  // ... existing columns ...
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual', 'sms', 'email', 'api'
  TextColumn get sourceEmailId => text().nullable()(); // Gmail message ID
  BoolColumn get isAutoImported => boolean().withDefault(const Constant(false))();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
}
```

---

#### Privacy & Security

**Data Protection:**
- ✅ Only request `gmail.readonly` scope (cannot modify/delete emails)
- ✅ Refresh token encrypted in Firestore
- ✅ User can disconnect anytime (tokens revoked)
- ✅ No email content stored, only extracted transaction data
- ✅ Processing done server-side (Cloud Functions)

**User Control:**
- Toggle which banks to scan
- Review auto-imported transactions before confirming
- Option to delete all synced data
- View sync history and logs

---

#### Cost Estimation

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Gmail API | 1M requests/day free | $0 |
| Cloud Functions | 2M invocations free | ~$5-10 |
| Gemini Flash | ~$0.075/1M input tokens | ~$10-20 |
| Firestore | Per user storage | ~$5 |
| **Total** | | **~$20-40/month** |

*For 1000 active users with email sync enabled*

---

#### Implementation Checklist

- [ ] **Week 1: OAuth Setup**
  - [ ] Configure Google Cloud OAuth consent screen
  - [ ] Add gmail.readonly scope
  - [ ] Implement GmailAuthService in Flutter
  - [ ] Store refresh token securely in Firestore

- [ ] **Week 2: Cloud Function**
  - [ ] Create scanBankingEmails scheduled function
  - [ ] Implement Gmail API client with refresh token
  - [ ] Build bank domain filter list
  - [ ] Add email fetching logic

- [ ] **Week 3: AI Parsing**
  - [ ] Design parsing prompt for Gemini
  - [ ] Handle multiple email formats (HTML, plain text)
  - [ ] Add confidence scoring
  - [ ] Test with VN and international bank emails

- [ ] **Week 4: Flutter UI**
  - [ ] Email sync settings screen
  - [ ] Transaction review screen (for auto-imported)
  - [ ] Sync status indicators
  - [ ] Error handling and retry logic

---

#### Sample Email Formats

**Vietcombank:**
```
Subject: VCB: GD thanh toan the 123456xxxx7890

Quy Khach da thanh toan
So tien: 150,000 VND
Tai: GRAB VIETNAM
Ngay: 18/12/2025 14:30:25
So du: 5,234,000 VND
```

**Chase:**
```
Subject: Your $45.67 transaction with AMAZON.COM

Transaction Details:
Amount: $45.67
Merchant: AMAZON.COM
Date: December 18, 2025
Card ending in: 1234
```

**Techcombank:**
```
Subject: TCB - Thong bao giao dich

Tai khoan: 190xxxx1234
Giao dich: -500,000 VND
Noi dung: Thanh toan QR
Thoi gian: 18/12/2025 10:15
So du: 12,500,000 VND
```

### 0A.5 Apple FinanceKit Integration (Priority 5)
**Timeline: 2-4 weeks | Platform: iOS only | Status: 🔬 RESEARCH**

**What is FinanceKit?**
Apple's native framework (iOS 17.4+) for accessing financial data from Apple Wallet:
- Apple Card transactions
- Apple Cash transactions
- Bank accounts linked to Apple Wallet

**Limitations:**
- **iOS 17.4+ only** - limited user base
- **US market only** - Apple Card not available elsewhere
- **Requires Apple entitlement** - must apply for approval
- **No Flutter package** - only 1 unofficial package on GitHub ([dasbudget/flutter_financekit](https://github.com/dasbudget/flutter_financekit))

**Technical Implementation:**
```swift
// Native Swift code required
import FinanceKit

// Request authorization
let store = FinanceStore.shared
let authStatus = await store.requestAuthorization()

// Fetch transactions
let transactions = try await store.transactions(query: query)
```

**Flutter Integration Options:**
1. Fork & improve `flutter_financekit` package
2. Write custom platform channel + Swift code
3. Wait for official/mature package

**When to implement:**
- After US market expansion
- When iOS 17.4+ adoption reaches 50%+
- If Apple Card user base is significant

**References:**
- [Apple FinanceKit Documentation](https://developer.apple.com/financekit/)
- [flutter_financekit (GitHub)](https://github.com/dasbudget/flutter_financekit) - 2 stars, last update Aug 2024

---

### Implementation Roadmap

**Phase 1 (Week 1-2): SMS Parsing MVP**
- [ ] Implement SMS permission request flow
- [ ] Build SMS listener background service
- [ ] Create bank sender ID whitelist (VN banks)
- [ ] AI prompt engineering for SMS parsing
- [ ] Pending transaction queue UI
- [ ] User confirmation flow

**Phase 2 (Week 3): Notification Listener**
- [ ] NotificationListenerService setup
- [ ] Banking app package whitelist
- [ ] Notification parsing with AI
- [ ] Merge with SMS transactions (dedup)

**Phase 3 (Week 4+): Open Banking**
- [ ] Evaluate Brick/Brankas for SEA
- [ ] Plaid integration for US/Canada
- [ ] Transaction sync engine
- [ ] Historical import

### Privacy & Security Considerations

**User Consent:**
- Explicit opt-in for each method
- Clear explanation of what data is collected
- Easy toggle on/off in settings

**Data Handling:**
- SMS content NOT stored permanently
- Only extracted transaction data saved
- Notification content processed locally
- Bank credentials NEVER stored

**Compliance:**
- GDPR/PDPA compliant
- Data minimization principle
- Right to delete all automation data

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

### 0.7 Supabase Sync Performance Optimization
**Priority: P3 (Future) | Timeline: TBD | Status: 📋 PLANNED**

**Current Implementation (v371):**
- ✅ **Full bidirectional sync operational** - Upload and download for wallets, categories, transactions
- ✅ **Sync time:** 2-3 seconds for typical user (~500-1000 transactions)
- ✅ **Local-first architecture** with cloud backup
- ✅ **CloudId mapping** - UUID-based global identifiers to decouple local IDs from cloud IDs
- ✅ **Dependency-order sync** - Wallets → Categories → Transactions (prevents foreign key violations)
- ✅ **Last-write-wins conflict resolution** based on updatedAt timestamps
- ✅ **Separation of concerns** - DAOs handle local DB, Sync service handles cloud operations
- ✅ **Login flow sync** - App pulls data from cloud after authentication

**Data Size Analysis:**
- Personal finance apps typically have 500-1000 transactions (~100KB data)
- Full sync completes in 2-3 seconds for typical users
- Cost: ~$0.03/user/month for sync operations

**Future Optimizations (implement when needed):**

#### 0.7.1 Incremental Sync
**Trigger Conditions:**
- User has >3000 transactions (currently ~1000 typical)
- Sync time exceeds 4-5 seconds
- User complaints about sync speed
- Backend costs become significant

**Implementation:**
- Timestamp-based filtering (`updated_at > lastSyncTime`)
- Track last sync timestamp per data type (wallets, categories, transactions)
- Only pull records modified since last sync
- Edge case handling:
  - Clock skew (use server timestamps)
  - Offline periods (full sync if >7 days)
  - First sync (always full)

**Benefits:**
- Faster sync for users with large datasets
- Reduced network bandwidth
- Lower cloud costs

**Trade-offs:**
- Increased complexity
- More potential for bugs
- Edge cases to handle (clock skew, offline periods)

#### 0.7.2 Batch Operations
**Benefits:**
- Reduce number of database round trips
- Faster bulk inserts for large datasets
- Lower latency for multi-record operations

**Implementation:**
- `batchUpsertWallets()`, `batchUpsertCategories()`, `batchUpsertTransactions()`
- Batch size optimization (100-500 records per batch)
- Supabase supports batch upsert natively
- Transaction-level error handling

#### 0.7.3 Soft Delete for Cloud Sync
**Purpose:**
- Track deleted items across devices
- Prevent deleted items from reappearing after sync
- Maintain referential integrity

**Implementation:**
- Add `is_deleted` and `deleted_at` columns to all sync tables
- Modified sync logic to handle deleted items:
  - Download: Mark as deleted locally instead of skipping
  - Upload: Send delete flag instead of removing record
- Cleanup job to permanently remove old deleted records (90 days)

**Database Changes:**
```sql
ALTER TABLE wallets ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE wallets ADD COLUMN deleted_at TIMESTAMP NULL;
ALTER TABLE categories ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE categories ADD COLUMN deleted_at TIMESTAMP NULL;
ALTER TABLE transactions ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE transactions ADD COLUMN deleted_at TIMESTAMP NULL;
```

**Priority Rationale:**
- ✅ Current full sync is **production-ready and performant**
- ✅ Optimizations add complexity and potential bugs
- ✅ Industry standard: many apps use full sync successfully
  - **1Password** - Uses full sync, one of most trusted password managers
  - **Bear Notes** - Full sync for all notes
  - **Day One** - Full sync for journal entries
- ✅ Cost is acceptable (~$0.03/user/month for sync operations)
- ✅ Performance is acceptable (2-3 seconds for typical user)
- ⏳ Optimize when: >3000 transactions OR >4s sync time OR user complaints

**When to Implement:**
- Phase 3: After core features are stable
- When >20% of users have >3000 transactions
- When sync time complaints increase
- When cloud costs become significant portion of revenue

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

## Phase 6: Gamification & Engagement (Q3-Q4 2025) 🎮

> **Goal:** Biến việc quản lý tài chính thành trải nghiệm thú vị và gây nghiện thông qua game mechanics.

### 6.0 Achievement System
**Priority: HIGH | Timeline: 2 weeks**

**Badges & Achievements:**
- 🏅 **First Steps** - Tạo giao dịch đầu tiên
- 💰 **Saver** - Tiết kiệm được 10% thu nhập trong tháng
- 🔥 **Streak Master** - Ghi chép liên tục 7/30/100 ngày
- 📊 **Budget Pro** - Không vượt ngân sách 3 tháng liên tiếp
- 🎯 **Goal Crusher** - Hoàn thành mục tiêu tiết kiệm đầu tiên
- 🤖 **AI Friend** - Sử dụng AI Chat 50 lần
- 📸 **Receipt Collector** - Scan 100 hóa đơn
- 🌍 **Globe Trotter** - Sử dụng 5+ loại tiền tệ khác nhau
- 👨‍👩‍👧‍👦 **Family Manager** - Mời 3 thành viên gia đình

**Unlock Rewards:**
- Custom themes/colors khi đạt milestone
- Special app icons
- Priority support access
- Early access to beta features

### 6.1 Streak & Daily Check-in
**Priority: HIGH | Timeline: 1 week**

**Features:**
- Daily streak counter (giống Duolingo)
- Streak freeze (bảo vệ streak 1 ngày)
- Weekly recap với celebration animation
- Streak milestones (7, 30, 100, 365 ngày)
- Push notification nhắc nhở check-in

**UI Elements:**
- 🔥 Fire icon với số ngày streak
- Calendar view hiển thị các ngày active
- Streak recovery option (xem quảng cáo để khôi phục)

### 6.2 Leaderboards & Challenges
**Priority: MEDIUM | Timeline: 2 weeks**

**Weekly Challenges:**
- "No Eating Out Week" - Không chi tiêu ăn ngoài
- "Save $50 Challenge" - Tiết kiệm được $50 trong tuần
- "Track Everything" - Ghi chép 100% giao dịch
- "Budget Warrior" - Giữ 5 ngân sách dưới limit

**Leaderboards:**
- Anonymous ranking (chỉ hiện username)
- Categories: Savings rate, Streak, Transactions logged
- Weekly/Monthly/All-time rankings
- Friend leaderboards (opt-in)

**Rewards:**
- Top 10% nhận badge đặc biệt
- Winner tuần được highlight
- Virtual currency/points để unlock features

### 6.3 Progress & Levels
**Priority: MEDIUM | Timeline: 1 week**

**XP System:**
- +10 XP: Thêm giao dịch
- +20 XP: Thêm giao dịch với receipt
- +50 XP: Hoàn thành daily goal
- +100 XP: Duy trì ngân sách cả tuần
- +500 XP: Hoàn thành savings goal

**Level Progression:**
- Level 1-10: Newbie → Beginner → Learner
- Level 11-25: Tracker → Planner → Organizer
- Level 26-50: Saver → Investor → Wealthy
- Level 51-100: Expert → Master → Legend

**Level Benefits:**
- Unlock new themes tại certain levels
- Unlock advanced analytics
- Unlock custom categories/icons
- Special badge next to username

### 6.4 Virtual Rewards & Shop
**Priority: LOW | Timeline: 2 weeks**

**Virtual Currency: "Bexly Coins"**
- Earn coins from achievements, streaks, challenges
- Spend coins on:
  - Premium themes
  - Custom app icons
  - Profile decorations
  - Streak freezes
  - Double XP boosts

**Premium Store:**
- Exclusive themes (purchasable hoặc high coin cost)
- Limited edition badges
- Custom category icons
- Avatar frames

### 6.5 Social Sharing
**Priority: LOW | Timeline: 1 week**

**Features:**
- Share achievements to social media
- Monthly recap cards (Instagram story style)
- "I saved $X this month" shareable
- Referral program với rewards
- Invite friends challenges

**Privacy:**
- All social features opt-in
- No real financial data exposed
- Only share percentages/achievements

---

### Gamification Technical Implementation

**Database Schema:**
```sql
user_progress:
  - user_id (PK)
  - xp_total
  - level
  - current_streak
  - longest_streak
  - coins_balance
  - last_active_date
  - streak_freeze_count

achievements:
  - id (PK)
  - user_id (FK)
  - achievement_type
  - unlocked_at
  - progress (0-100%)

challenges:
  - id (PK)
  - name
  - description
  - start_date
  - end_date
  - goal_type
  - goal_value
  - reward_coins
  - reward_xp

user_challenges:
  - user_id (FK)
  - challenge_id (FK)
  - progress
  - completed_at
```

**Implementation Phases:**
1. Week 1-2: Achievement system + badges UI
2. Week 3: Streak system + daily check-in
3. Week 4: XP + Levels + Progress bars
4. Week 5-6: Challenges + Leaderboards
5. Week 7-8: Virtual shop + Social sharing

---

## Phase 7: Social & Collaboration (Q4 2025)

### 7.1 Family Sharing
**Priority: MEDIUM | Timeline: 2 weeks**

Features:
- Shared wallets
- Family budgets
- Expense splitting
- Approval workflows
- Child accounts with limits

### 7.2 Bill Splitting
**Priority: MEDIUM | Timeline: 1 week**

Features:
- Group expense tracking
- Split by percentage/amount
- Settlement tracking
- Payment reminders
- Integration with payment apps

### 7.3 Financial Goals
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