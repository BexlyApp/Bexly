# Email Transaction Sync - Implementation Plan

## Overview
Automatically sync banking transactions from user's email inbox using Gmail API and AI parsing.

**Status:** 📋 PLANNED
**Priority:** 4 (after SMS parsing)
**Timeline:** 3-4 weeks
**Platform:** All (iOS, Android, Web, Desktop)

---

## Why This Feature?

### Problem
- iOS users can't use SMS parsing (no API access)
- Open Banking APIs have limited coverage in Vietnam/SEA
- Manual transaction entry is tedious

### Solution
Email sync works on ALL platforms and with ALL banks that send email notifications.

### Comparison with Other Methods

| Method | iOS | Android | VN Coverage | Global Coverage |
|--------|-----|---------|-------------|-----------------|
| SMS Parsing | ❌ | ✅ | High | Medium |
| Apple FinanceKit | ✅ | ❌ | ❌ | US only |
| Open Banking | ✅ | ✅ | 2027+ | Region-specific |
| **Email Sync** | ✅ | ✅ | High | High |

---

## Architecture

### High-Level Flow

```
User Device                  Firebase                      External
    │                           │                             │
    │  1. Connect Gmail         │                             │
    │ ─────────────────────────▶│                             │
    │                           │  2. OAuth                   │
    │                           │────────────────────────────▶│ Google OAuth
    │                           │◀────────────────────────────│
    │                           │                             │
    │                           │  3. Store refresh token     │
    │                           │  (encrypted in Firestore)   │
    │                           │                             │
    │                           │  4. Scheduled scan (15min)  │
    │                           │────────────────────────────▶│ Gmail API
    │                           │◀────────────────────────────│
    │                           │                             │
    │                           │  5. Parse with AI           │
    │                           │────────────────────────────▶│ Gemini
    │                           │◀────────────────────────────│
    │                           │                             │
    │  6. Sync transactions     │                             │
    │◀─────────────────────────│                             │
    │                           │                             │
```

### Components

1. **Flutter App**
   - Gmail OAuth UI
   - Email sync settings screen
   - Transaction review screen

2. **Cloud Functions**
   - Scheduled email scanner (every 15 min)
   - AI parsing function
   - Token refresh handler

3. **Firestore**
   - User email sync settings
   - Encrypted refresh tokens
   - Parsed transaction queue

4. **External APIs**
   - Gmail API (read-only)
   - Gemini 1.5 Flash (parsing)

---

## Implementation Phases

### Phase 1: Gmail OAuth Integration (Week 1)

#### 1.1 Google Cloud Setup
- [ ] Create OAuth consent screen in Google Cloud Console
- [ ] Add `gmail.readonly` scope
- [ ] Configure authorized domains
- [ ] Generate OAuth 2.0 credentials (Web + Android + iOS)

#### 1.2 Flutter OAuth Flow
```dart
// New files to create:
lib/features/email_sync/
├── services/
│   └── gmail_auth_service.dart
├── presentation/
│   ├── screens/
│   │   └── email_sync_settings_screen.dart
│   └── components/
│       ├── gmail_connect_button.dart
│       └── email_sync_status_card.dart
└── riverpod/
    └── email_sync_provider.dart
```

**Key Implementation:**
```dart
class GmailAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/gmail.readonly'],
    serverClientId: Environment.webClientId,
  );

  Future<EmailSyncResult> connectGmail() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return EmailSyncResult.cancelled();

      // Get server auth code for Cloud Function
      final serverAuthCode = await account.serverAuthCode;

      // Send to Cloud Function to exchange for refresh token
      await _storeAuthCode(serverAuthCode);

      return EmailSyncResult.success(account.email);
    } catch (e) {
      return EmailSyncResult.error(e.toString());
    }
  }
}
```

#### 1.3 Firestore Security Rules
```javascript
// firestore.rules
match /users/{userId}/emailSync/{doc} {
  allow read, write: if request.auth.uid == userId;
}
```

---

### Phase 2: Cloud Function - Email Scanner (Week 2)

#### 2.1 Token Exchange Function
```typescript
// functions/src/emailSync/exchangeAuthCode.ts

export const exchangeGmailAuthCode = onCall(async (request) => {
  const { authCode } = request.data;
  const userId = request.auth?.uid;

  // Exchange auth code for tokens
  const oauth2Client = new google.auth.OAuth2(
    process.env.WEB_CLIENT_ID,
    process.env.WEB_CLIENT_SECRET,
    'postmessage'
  );

  const { tokens } = await oauth2Client.getToken(authCode);

  // Encrypt and store refresh token
  const encryptedToken = await encrypt(tokens.refresh_token);
  await db.doc(`users/${userId}/emailSync/settings`).set({
    encryptedRefreshToken: encryptedToken,
    gmailEmail: await getEmailFromToken(tokens),
    isEnabled: true,
    lastSyncTime: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { success: true };
});
```

#### 2.2 Scheduled Scanner Function
```typescript
// functions/src/emailSync/scanBankingEmails.ts

export const scanBankingEmails = onSchedule({
  schedule: 'every 15 minutes',
  timeZone: 'Asia/Ho_Chi_Minh',
  retryCount: 3,
}, async () => {
  const usersSnapshot = await db
    .collectionGroup('emailSync')
    .where('isEnabled', '==', true)
    .get();

  const promises = usersSnapshot.docs.map(async (doc) => {
    const userId = doc.ref.parent.parent?.id;
    if (!userId) return;

    try {
      await processSingleUser(userId, doc.data());
    } catch (error) {
      logger.error(`Email sync failed for user ${userId}`, error);
    }
  });

  await Promise.allSettled(promises);
});

async function processSingleUser(userId: string, settings: EmailSyncSettings) {
  const gmail = await getGmailClient(settings.encryptedRefreshToken);
  const lastSync = settings.lastSyncTime?.toDate() ?? new Date(Date.now() - 24 * 60 * 60 * 1000);

  const emails = await fetchBankingEmails(gmail, lastSync);

  for (const email of emails) {
    const transaction = await parseEmailWithAI(email);
    if (transaction && transaction.confidence >= 0.7) {
      await saveTransaction(userId, transaction);
    }
  }

  // Update last sync time
  await db.doc(`users/${userId}/emailSync/settings`).update({
    lastSyncTime: FieldValue.serverTimestamp(),
  });
}
```

#### 2.3 Bank Domain List
```typescript
// functions/src/emailSync/bankDomains.ts

export const BANK_DOMAINS = {
  // Vietnam - Major banks
  vietnam: [
    'vietcombank.com.vn',
    'alert.vietcombank.com.vn',
    'bidv.com.vn',
    'notification.bidv.com.vn',
    'techcombank.com.vn',
    'vpbank.com.vn',
    'mbbank.com.vn',
    'acb.com.vn',
    'tpb.vn',
    'tpbank.vn',
    'sacombank.com.vn',
    'hdbank.com.vn',
    'vib.com.vn',
    'msb.com.vn',
    'seabank.com.vn',
    'lpbank.com.vn',
    'namabank.com.vn',
    'ocb.com.vn',
  ],
  // US/International
  international: [
    'chase.com',
    'alerts.chase.com',
    'citi.com',
    'notifications.citi.com',
    'email.capitalone.com',
    'alerts.bankofamerica.com',
    'wellsfargo.com',
    'hsbc.com',
    'americanexpress.com',
    'discover.com',
  ],
  // E-wallets (Vietnam)
  ewallets: [
    'momo.vn',
    'zalopay.vn',
    'vnpay.vn',
    'shopeepay.vn',
  ],
};

export function buildGmailQuery(since: Date): string {
  const allDomains = [
    ...BANK_DOMAINS.vietnam,
    ...BANK_DOMAINS.international,
    ...BANK_DOMAINS.ewallets,
  ];

  const fromQuery = allDomains.map(d => `from:${d}`).join(' OR ');
  const dateQuery = `after:${formatDateForGmail(since)}`;

  return `(${fromQuery}) ${dateQuery}`;
}
```

---

### Phase 3: AI Email Parsing (Week 2-3)

#### 3.1 Parsing Prompt Design
```typescript
// functions/src/emailSync/parseEmailWithAI.ts

const SYSTEM_PROMPT = `You are a financial transaction parser. Extract transaction data from banking emails.

Rules:
1. Only extract if this is clearly a transaction notification
2. Identify the transaction type: expense, income, or transfer
3. Extract amounts with correct currency (VND, USD, etc.)
4. Identify merchant/sender name
5. Parse date and time accurately
6. Suggest a category based on merchant name
7. Rate your confidence 0-1

Common Vietnamese bank formats:
- VCB: "So tien: 150,000 VND" means amount is 150,000 VND
- TCB: "Giao dich: -500,000 VND" means expense of 500,000 VND
- MB: "PS: +1,000,000 VND" means income of 1,000,000 VND

Return JSON only, no explanation.`;

const USER_PROMPT = `Parse this banking email:

Subject: {SUBJECT}
From: {FROM}
Date: {DATE}

Body:
{BODY}

Return JSON:
{
  "is_transaction": boolean,
  "amount": number (positive for income, negative for expense),
  "currency": "VND" | "USD" | etc,
  "merchant": string,
  "date": "YYYY-MM-DD HH:mm:ss",
  "type": "expense" | "income" | "transfer",
  "category_hint": string,
  "account_last4": string | null,
  "balance_after": number | null,
  "confidence": number (0-1),
  "raw_amount_text": string
}`;
```

#### 3.2 Parsing Function
```typescript
async function parseEmailWithAI(email: gmail_v1.Schema$Message): Promise<ParsedTransaction | null> {
  const vertexai = new VertexAI({ project: 'bexly-app' });
  const model = vertexai.getGenerativeModel({
    model: 'gemini-1.5-flash',
    generationConfig: {
      temperature: 0.1, // Low temp for consistent parsing
      maxOutputTokens: 1000,
    },
  });

  const { subject, from, body, date } = extractEmailParts(email);

  const prompt = USER_PROMPT
    .replace('{SUBJECT}', subject)
    .replace('{FROM}', from)
    .replace('{DATE}', date)
    .replace('{BODY}', body.substring(0, 3000)); // Limit body size

  const result = await model.generateContent({
    systemInstruction: SYSTEM_PROMPT,
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });

  try {
    const jsonStr = result.response.text();
    const parsed = JSON.parse(jsonStr);

    if (!parsed.is_transaction || parsed.confidence < 0.7) {
      logger.info('Email not a transaction or low confidence', { emailId: email.id });
      return null;
    }

    return {
      ...parsed,
      sourceEmailId: email.id,
      sourceEmail: from,
      rawSubject: subject,
    };
  } catch (error) {
    logger.error('Failed to parse AI response', { error, emailId: email.id });
    return null;
  }
}
```

#### 3.3 Transaction Deduplication
```typescript
async function saveTransaction(userId: string, parsed: ParsedTransaction): Promise<void> {
  // Check for duplicates based on amount, date, and merchant
  const duplicateCheck = await db
    .collection(`users/${userId}/data/transactions/items`)
    .where('amount', '==', parsed.amount)
    .where('date', '==', parsed.date)
    .where('merchantName', '==', parsed.merchant)
    .limit(1)
    .get();

  if (!duplicateCheck.empty) {
    logger.info('Duplicate transaction found, skipping', { parsed });
    return;
  }

  // Also check by email ID to prevent re-processing
  const emailIdCheck = await db
    .collection(`users/${userId}/data/transactions/items`)
    .where('sourceEmailId', '==', parsed.sourceEmailId)
    .limit(1)
    .get();

  if (!emailIdCheck.empty) {
    return;
  }

  // Save new transaction
  await db.collection(`users/${userId}/data/transactions/items`).add({
    cloudId: generateUUIDv7(),
    amount: parsed.amount,
    currencyCode: parsed.currency,
    merchantName: parsed.merchant,
    date: Timestamp.fromDate(new Date(parsed.date)),
    type: parsed.type === 'income' ? 'income' : 'expense',
    categoryHint: parsed.category_hint,
    source: 'email',
    sourceEmailId: parsed.sourceEmailId,
    isAutoImported: true,
    needsReview: true, // User should review auto-imported
    confidence: parsed.confidence,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}
```

---

### Phase 4: Flutter UI (Week 3-4)

#### 4.1 Email Sync Settings Screen
```dart
// lib/features/email_sync/presentation/screens/email_sync_settings_screen.dart

class EmailSyncSettingsScreen extends ConsumerWidget {
  const EmailSyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(emailSyncProvider);

    return CustomScaffold(
      context: context,
      title: 'Email Sync',
      body: syncState.when(
        data: (settings) => _buildContent(context, ref, settings),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorWidget(error: e),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, EmailSyncSettings? settings) {
    final isConnected = settings?.isEnabled ?? false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      children: [
        // Connection status
        EmailConnectionCard(
          isConnected: isConnected,
          email: settings?.gmailEmail,
          onConnect: () => _connectGmail(context, ref),
          onDisconnect: () => _showDisconnectDialog(context, ref),
        ),

        if (isConnected) ...[
          const Gap(AppSpacing.spacing16),

          // Sync statistics
          SyncStatsCard(
            lastSync: settings?.lastSyncTime,
            transactionsImported: settings?.totalImported ?? 0,
            pendingReview: settings?.pendingReview ?? 0,
          ),

          const Gap(AppSpacing.spacing16),

          // Bank filters
          BankFilterSection(
            enabledBanks: settings?.enabledBanks ?? [],
            onToggle: (bank, enabled) => _toggleBank(ref, bank, enabled),
          ),

          const Gap(AppSpacing.spacing16),

          // Manual sync button
          PrimaryButton(
            label: 'Sync Now',
            icon: HugeIcons.strokeRoundedRefresh,
            onPressed: () => _triggerSync(ref),
          ),

          const Gap(AppSpacing.spacing16),

          // Privacy info
          const PrivacyInfoCard(),
        ],
      ],
    );
  }

  Future<void> _connectGmail(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(emailSyncProvider.notifier).connectGmail();

    result.when(
      success: (email) {
        context.showSuccessToast('Connected to $email');
      },
      cancelled: () {
        // User cancelled, do nothing
      },
      error: (message) {
        context.showErrorToast('Failed to connect: $message');
      },
    );
  }
}
```

#### 4.2 Transaction Review Screen
```dart
// lib/features/email_sync/presentation/screens/pending_review_screen.dart

class PendingReviewScreen extends ConsumerWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTransactions = ref.watch(pendingEmailTransactionsProvider);

    return CustomScaffold(
      context: context,
      title: 'Review Imported Transactions',
      body: pendingTransactions.when(
        data: (transactions) => ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return TransactionReviewCard(
              transaction: tx,
              onApprove: () => _approveTransaction(ref, tx),
              onReject: () => _rejectTransaction(ref, tx),
              onEdit: () => _editTransaction(context, tx),
            );
          },
        ),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorWidget(error: e),
      ),
    );
  }
}
```

#### 4.3 Add to Settings Screen
```dart
// In settings_data_group.dart or similar

MenuTileButton(
  label: 'Email Sync',
  icon: HugeIcons.strokeRoundedMail01,
  trailing: ref.watch(emailSyncStatusProvider).maybeWhen(
    data: (s) => s?.isEnabled == true
      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
      : null,
    orElse: () => null,
  ),
  onTap: () => context.push(Routes.emailSync),
),
```

---

## Database Schema

### Firestore Structure
```
users/{userId}/
├── emailSync/
│   └── settings/
│       ├── encryptedRefreshToken: string
│       ├── gmailEmail: string
│       ├── isEnabled: boolean
│       ├── lastSyncTime: timestamp
│       ├── enabledBanks: string[] (domain list)
│       ├── totalImported: number
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
└── data/
    └── transactions/
        └── items/{transactionId}/
            ├── ... (existing fields)
            ├── source: 'manual' | 'sms' | 'email' | 'api'
            ├── sourceEmailId: string | null
            ├── isAutoImported: boolean
            ├── needsReview: boolean
            └── confidence: number | null
```

### Local Database (Drift)
```dart
// New table: email_sync_settings
class EmailSyncSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gmailEmail => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  TextColumn get enabledBanks => text().withDefault(const Constant('[]'))();
  IntColumn get totalImported => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// Modify transactions table - add columns:
// source, sourceEmailId, isAutoImported, needsReview, confidence
```

---

## Security Considerations

### OAuth Security
- Use PKCE flow for mobile apps
- Store refresh tokens encrypted with user-specific key
- Token encryption key derived from Firebase Auth UID
- Never store access tokens (short-lived, regenerated from refresh)

### Data Privacy
- Only request `gmail.readonly` scope
- Never store email content, only extracted transaction data
- User can revoke access anytime
- Clear all data on disconnect

### Rate Limiting
- Gmail API: 25 quota units/second/user
- Implement exponential backoff
- Batch requests where possible

---

## Testing Plan

### Unit Tests
- [ ] Email parsing with sample emails from each bank
- [ ] Deduplication logic
- [ ] Currency parsing (VND, USD, etc.)
- [ ] Date/time parsing (various formats)

### Integration Tests
- [ ] OAuth flow (happy path, cancellation, error)
- [ ] Cloud Function scheduling
- [ ] Firestore security rules
- [ ] End-to-end sync flow

### Sample Test Emails
Create fixtures for:
- Vietcombank transaction notification
- Techcombank transaction alert
- MB Bank debit/credit
- Chase purchase alert
- E-wallet (MoMo, ZaloPay)

---

## Rollout Plan

### Phase 1: Internal Testing
- Enable for development accounts only
- Test with real banking emails
- Validate parsing accuracy

### Phase 2: Beta
- Release to beta users
- Monitor error rates
- Collect feedback on missed banks

### Phase 3: GA
- Enable in settings for all users
- Add onboarding prompt for iOS users
- Monitor Cloud Function costs

---

## Cost Monitoring

### Expected Costs (1000 users)
| Service | Estimated | Notes |
|---------|-----------|-------|
| Gmail API | $0 | 1M requests/day free |
| Cloud Functions | $5-10/mo | 2M invocations free |
| Gemini Flash | $10-20/mo | ~$0.075/1M tokens |
| Firestore | $5/mo | Depends on storage |
| **Total** | **$20-40/mo** | |

### Cost Alerts
- Set up Cloud Billing alerts at $25, $50, $100
- Monitor Gemini token usage
- Implement caching for repeated parsing patterns

---

## File Structure

```
lib/features/email_sync/
├── data/
│   ├── models/
│   │   ├── email_sync_settings.dart
│   │   └── parsed_transaction.dart
│   └── repositories/
│       └── email_sync_repository.dart
├── domain/
│   └── services/
│       └── gmail_auth_service.dart
├── presentation/
│   ├── screens/
│   │   ├── email_sync_settings_screen.dart
│   │   └── pending_review_screen.dart
│   └── components/
│       ├── email_connection_card.dart
│       ├── sync_stats_card.dart
│       ├── bank_filter_section.dart
│       ├── privacy_info_card.dart
│       └── transaction_review_card.dart
└── riverpod/
    ├── email_sync_provider.dart
    └── pending_transactions_provider.dart

functions/src/emailSync/
├── index.ts
├── exchangeAuthCode.ts
├── scanBankingEmails.ts
├── parseEmailWithAI.ts
├── bankDomains.ts
└── utils/
    ├── encryption.ts
    └── gmailClient.ts
```

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Parsing accuracy | > 90% |
| User adoption (iOS) | > 30% of active users |
| Average sync latency | < 20 minutes |
| False positive rate | < 5% |
| User review rate | > 80% approve without edit |

---

## References

- [Gmail API Documentation](https://developers.google.com/gmail/api)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Vertex AI for Firebase](https://firebase.google.com/docs/vertex-ai)
- [Firebase Cloud Functions v2](https://firebase.google.com/docs/functions)
