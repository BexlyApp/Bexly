# Detailed Implementation Plan: SMS Parsing + Notification Listener

> **Goal:** Tự động tạo giao dịch từ SMS ngân hàng và notification từ banking apps sử dụng AI (Gemini) để parse nội dung.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Database Schema](#database-schema)
3. [SMS Parsing Implementation](#sms-parsing-implementation)
4. [Notification Listener Implementation](#notification-listener-implementation)
5. [AI Parsing Service](#ai-parsing-service)
6. [UI/UX Flow](#uiux-flow)
7. [Bank Whitelist Configuration](#bank-whitelist-configuration)
8. [Testing Strategy](#testing-strategy)
9. [Implementation Checklist](#implementation-checklist)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐           ┌─────────────────────────────────┐  │
│  │   SMS Inbox     │           │   NotificationListenerService   │  │
│  │  (Android only) │           │        (Android only)           │  │
│  └────────┬────────┘           └───────────────┬─────────────────┘  │
│           │                                    │                     │
│           ▼                                    ▼                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              BANK WHITELIST FILTER                              ││
│  │   - Filter SMS by sender ID (VCB, TPB, TCB, MB...)              ││
│  │   - Filter notification by package name                         ││
│  └─────────────────────────────────────────────────────────────────┘│
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              AI PARSING SERVICE (Gemini)                        ││
│  │   - Extract: amount, type (debit/credit), merchant, datetime    ││
│  │   - Match category based on merchant                            ││
│  │   - Cost: ~$0.001/message                                       ││
│  └─────────────────────────────────────────────────────────────────┘│
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              PENDING TRANSACTION QUEUE                          ││
│  │   - Store parsed transactions with status: pending              ││
│  │   - Deduplication by hash (amount + datetime + merchant)        ││
│  │   - Auto-approve after X hours (optional)                       ││
│  └─────────────────────────────────────────────────────────────────┘│
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              USER CONFIRMATION UI                               ││
│  │   - Badge on transaction tab showing pending count              ││
│  │   - Swipe to approve/reject                                     ││
│  │   - Edit before confirm                                         ││
│  └─────────────────────────────────────────────────────────────────┘│
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              TRANSACTION DATABASE                               ││
│  │   - Move approved pending → transactions table                  ││
│  │   - Sync to cloud (Firestore)                                   ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### New Table: `pending_transactions`

```sql
CREATE TABLE pending_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cloud_id TEXT,                           -- UUID v7 for cloud sync

  -- Parsed data from AI
  amount REAL NOT NULL,
  transaction_type TEXT NOT NULL,          -- 'expense' | 'income' | 'transfer'
  merchant TEXT,                           -- Extracted merchant name
  description TEXT,                        -- Original SMS/notification text (sanitized)

  -- References
  wallet_id INTEGER NOT NULL,
  category_id INTEGER,

  -- Metadata
  source_type TEXT NOT NULL,               -- 'sms' | 'notification' | 'email'
  source_sender TEXT,                      -- SMS sender ID or app package name
  source_raw_hash TEXT NOT NULL,           -- MD5 hash for deduplication
  transaction_datetime DATETIME NOT NULL,  -- Extracted transaction time

  -- Status
  status TEXT NOT NULL DEFAULT 'pending',  -- 'pending' | 'approved' | 'rejected' | 'auto_approved'
  confidence_score REAL,                   -- AI confidence 0.0 - 1.0

  -- Timestamps
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  processed_at DATETIME,                   -- When user approved/rejected

  FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Index for quick lookup
CREATE INDEX idx_pending_status ON pending_transactions(status);
CREATE INDEX idx_pending_hash ON pending_transactions(source_raw_hash);
CREATE INDEX idx_pending_created ON pending_transactions(created_at);
```

### New Table: `auto_transaction_settings`

```sql
CREATE TABLE auto_transaction_settings (
  id INTEGER PRIMARY KEY,

  -- Feature toggles
  sms_parsing_enabled INTEGER DEFAULT 0,
  notification_listening_enabled INTEGER DEFAULT 0,

  -- Auto-approval settings
  auto_approve_enabled INTEGER DEFAULT 0,
  auto_approve_delay_hours INTEGER DEFAULT 24,  -- Wait X hours before auto-approve
  auto_approve_min_confidence REAL DEFAULT 0.9, -- Only auto-approve if AI confidence >= this

  -- Default wallet for unknown transactions
  default_wallet_id INTEGER,

  -- Timestamps
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (default_wallet_id) REFERENCES wallets(id)
);
```

### Drift Implementation

```dart
// lib/core/database/tables/pending_transactions_table.dart

import 'package:drift/drift.dart';

enum PendingTransactionSource { sms, notification, email }
enum PendingTransactionStatus { pending, approved, rejected, autoApproved }

@DataClassName('PendingTransactionEntry')
class PendingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable()();

  // Parsed data
  RealColumn get amount => real()();
  TextColumn get transactionType => text()(); // expense, income, transfer
  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();

  // References
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();

  // Metadata
  TextColumn get sourceType => textEnum<PendingTransactionSource>()();
  TextColumn get sourceSender => text().nullable()();
  TextColumn get sourceRawHash => text()();
  DateTimeColumn get transactionDatetime => dateTime()();

  // Status
  TextColumn get status => textEnum<PendingTransactionStatus>().withDefault(
    Constant(PendingTransactionStatus.pending.name)
  )();
  RealColumn get confidenceScore => real().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}
```

---

## SMS Parsing Implementation

### Required Packages

```yaml
# pubspec.yaml - add to dependencies
dependencies:
  telephony: ^0.2.0           # For receiving SMS (Android)
  flutter_sms_inbox: ^1.0.5   # For reading existing SMS
  crypto: ^3.0.3              # For MD5 hashing
```

### Android Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- SMS Permissions -->
    <uses-permission android:name="android.permission.READ_SMS"/>
    <uses-permission android:name="android.permission.RECEIVE_SMS"/>

    <!-- For background service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>

    <application>
        <!-- SMS Broadcast Receiver -->
        <receiver android:name="com.shounakmulay.telephony.sms.IncomingSmsReceiver"
            android:permission="android.permission.BROADCAST_SMS"
            android:exported="true">
            <intent-filter>
                <action android:name="android.provider.Telephony.SMS_RECEIVED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### SMS Service Implementation

```dart
// lib/core/services/auto_transaction/sms_transaction_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:bexly/core/services/auto_transaction/ai_transaction_parser.dart';
import 'package:bexly/core/services/auto_transaction/bank_whitelist.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class SmsTransactionService {
  final Telephony _telephony = Telephony.instance;
  final SmsQuery _smsQuery = SmsQuery();
  final AiTransactionParser _aiParser;
  final AppDatabase _db;

  SmsTransactionService({
    required AiTransactionParser aiParser,
    required AppDatabase db,
  }) : _aiParser = aiParser, _db = db;

  /// Initialize SMS listening
  Future<bool> initialize() async {
    // Request permissions
    final permissionGranted = await _telephony.requestSmsPermissions;
    if (permissionGranted != true) {
      Log.w('SMS permission denied', label: 'SmsService');
      return false;
    }

    // Start listening for incoming SMS
    _telephony.listenIncomingSms(
      onNewMessage: _handleIncomingSms,
      onBackgroundMessage: _backgroundMessageHandler,
      listenInBackground: true,
    );

    Log.i('SMS listening initialized', label: 'SmsService');
    return true;
  }

  /// Handle incoming SMS
  void _handleIncomingSms(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    // Check if sender is in bank whitelist
    if (!BankWhitelist.isBankSms(sender)) {
      Log.d('Ignoring non-bank SMS from: $sender', label: 'SmsService');
      return;
    }

    Log.i('Processing bank SMS from: $sender', label: 'SmsService');

    await _processBankMessage(
      sender: sender,
      body: body,
      timestamp: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
      sourceType: PendingTransactionSource.sms,
    );
  }

  /// Scan existing SMS for bank transactions (on first setup)
  Future<int> scanExistingSms({int daysBack = 30}) async {
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 500,
    );

    int processed = 0;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

    for (final message in messages) {
      final sender = message.address ?? '';
      final date = message.date != null
          ? DateTime.fromMillisecondsSinceEpoch(message.date!)
          : DateTime.now();

      // Skip old messages
      if (date.isBefore(cutoffDate)) continue;

      // Skip non-bank SMS
      if (!BankWhitelist.isBankSms(sender)) continue;

      // Check for duplicate
      final hash = _generateHash(message.body ?? '', date.toIso8601String());
      if (await _isDuplicate(hash)) continue;

      await _processBankMessage(
        sender: sender,
        body: message.body ?? '',
        timestamp: date,
        sourceType: PendingTransactionSource.sms,
      );

      processed++;
    }

    Log.i('Scanned $processed bank SMS messages', label: 'SmsService');
    return processed;
  }

  /// Process a bank message and create pending transaction
  Future<void> _processBankMessage({
    required String sender,
    required String body,
    required DateTime timestamp,
    required PendingTransactionSource sourceType,
  }) async {
    // Generate hash for deduplication
    final hash = _generateHash(body, timestamp.toIso8601String());

    // Check duplicate
    if (await _isDuplicate(hash)) {
      Log.d('Duplicate SMS detected, skipping', label: 'SmsService');
      return;
    }

    // Get bank info for better AI context
    final bankInfo = BankWhitelist.getBankInfo(sender);

    // Parse with AI
    final parsed = await _aiParser.parseTransactionMessage(
      message: body,
      bankName: bankInfo?.name,
      bankCode: bankInfo?.code,
    );

    if (parsed == null) {
      Log.w('AI failed to parse SMS: ${body.substring(0, 50)}...', label: 'SmsService');
      return;
    }

    // Create pending transaction
    await _db.pendingTransactionDao.insertPending(
      PendingTransactionEntry(
        amount: parsed.amount,
        transactionType: parsed.type.name,
        merchant: parsed.merchant,
        description: _sanitizeMessage(body),
        walletId: await _getDefaultWalletId(),
        categoryId: parsed.categoryId,
        sourceType: sourceType,
        sourceSender: sender,
        sourceRawHash: hash,
        transactionDatetime: parsed.datetime ?? timestamp,
        status: PendingTransactionStatus.pending,
        confidenceScore: parsed.confidence,
        createdAt: DateTime.now(),
      ),
    );

    Log.i('Created pending transaction: ${parsed.amount} ${parsed.type}', label: 'SmsService');
  }

  /// Generate MD5 hash for deduplication
  String _generateHash(String content, String timestamp) {
    final data = '$content|$timestamp';
    return md5.convert(utf8.encode(data)).toString();
  }

  /// Check if transaction already exists
  Future<bool> _isDuplicate(String hash) async {
    final existing = await _db.pendingTransactionDao.findByHash(hash);
    return existing != null;
  }

  /// Get default wallet ID from settings
  Future<int> _getDefaultWalletId() async {
    // TODO: Get from auto_transaction_settings or defaultWalletIdProvider
    final settings = await _db.autoTransactionSettingsDao.getSettings();
    return settings?.defaultWalletId ?? 1;
  }

  /// Remove sensitive info from message before storing
  String _sanitizeMessage(String message) {
    // Remove account numbers (partial mask)
    final sanitized = message.replaceAllMapped(
      RegExp(r'\d{10,16}'),
      (match) => '****${match.group(0)!.substring(match.group(0)!.length - 4)}',
    );
    return sanitized;
  }
}

/// Background message handler (static function for isolate)
@pragma('vm:entry-point')
void _backgroundMessageHandler(SmsMessage message) async {
  // This runs in background isolate
  // Need to re-initialize dependencies here
  Log.d('Background SMS received: ${message.address}', label: 'SmsService');

  // TODO: Initialize minimal dependencies and process
  // Consider using WorkManager for reliable background processing
}
```

---

## Notification Listener Implementation

### Required Packages

```yaml
# pubspec.yaml - add to dependencies
dependencies:
  flutter_notification_listener: ^0.6.3
```

### Android Configuration

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- Notification Listener -->
    <uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"/>

    <application>
        <service android:name="im.zoe.labs.flutter_notification_listener.NotificationListener"
            android:label="Bexly Notification Listener"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
            android:exported="false">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

### Notification Service Implementation

```dart
// lib/core/services/auto_transaction/notification_transaction_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:bexly/core/services/auto_transaction/ai_transaction_parser.dart';
import 'package:bexly/core/services/auto_transaction/bank_whitelist.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class NotificationTransactionService {
  final AiTransactionParser _aiParser;
  final AppDatabase _db;

  NotificationTransactionService({
    required AiTransactionParser aiParser,
    required AppDatabase db,
  }) : _aiParser = aiParser, _db = db;

  /// Check if notification listener permission is granted
  Future<bool> hasPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  /// Open system settings to grant permission
  Future<void> openPermissionSettings() async {
    await NotificationsListener.openPermissionSettings();
  }

  /// Initialize notification listening
  Future<bool> initialize() async {
    // Check permission first
    if (!await hasPermission()) {
      Log.w('Notification listener permission not granted', label: 'NotificationService');
      return false;
    }

    // Start listening
    NotificationsListener.initialize(
      callbackHandle: _notificationCallbackHandle,
    );

    Log.i('Notification listener initialized', label: 'NotificationService');
    return true;
  }

  /// Start the listener service
  Future<void> startListening() async {
    await NotificationsListener.startService(
      foreground: false,
      title: 'Bexly',
      description: 'Monitoring banking notifications',
    );
  }

  /// Stop the listener service
  Future<void> stopListening() async {
    await NotificationsListener.stopService();
  }

  /// Handle notification callback
  @pragma('vm:entry-point')
  static void _notificationCallbackHandle(NotificationEvent event) {
    // This runs when a notification is received
    Log.d('Notification from: ${event.packageName}', label: 'NotificationService');

    // Check if from banking app
    final packageName = event.packageName ?? '';
    if (!BankWhitelist.isBankingApp(packageName)) {
      return;
    }

    // Extract notification content
    final title = event.title ?? '';
    final text = event.text ?? '';
    final content = '$title\n$text';

    Log.i('Banking notification: $content', label: 'NotificationService');

    // Process in background
    _processNotification(event);
  }

  static Future<void> _processNotification(NotificationEvent event) async {
    // TODO: Initialize minimal dependencies
    // Parse with AI and create pending transaction
    // Similar to SMS processing
  }
}
```

---

## AI Parsing Service

### AI Parser Implementation

```dart
// lib/core/services/auto_transaction/ai_transaction_parser.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bexly/core/utils/logger.dart';

enum ParsedTransactionType { expense, income, transfer }

class ParsedTransaction {
  final double amount;
  final ParsedTransactionType type;
  final String? merchant;
  final DateTime? datetime;
  final int? categoryId;
  final double confidence;

  ParsedTransaction({
    required this.amount,
    required this.type,
    this.merchant,
    this.datetime,
    this.categoryId,
    required this.confidence,
  });
}

class AiTransactionParser {
  final GenerativeModel _model;

  AiTransactionParser({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,  // Low temperature for consistent parsing
            maxOutputTokens: 500,
          ),
        );

  /// Parse a bank SMS/notification message
  Future<ParsedTransaction?> parseTransactionMessage({
    required String message,
    String? bankName,
    String? bankCode,
  }) async {
    final prompt = _buildParsingPrompt(message, bankName, bankCode);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return _parseAiResponse(text);
    } catch (e) {
      Log.e('AI parsing error: $e', label: 'AiParser');
      return null;
    }
  }

  String _buildParsingPrompt(String message, String? bankName, String? bankCode) {
    return '''
You are a transaction parser for Vietnamese banking messages. Parse the following bank message and extract transaction details.

Bank: ${bankName ?? 'Unknown'} (${bankCode ?? 'N/A'})

Message:
"""
$message
"""

Extract and return ONLY a JSON object (no markdown, no explanation) with these fields:
{
  "amount": <number - transaction amount in original currency>,
  "type": "<string - 'expense' for debit/withdrawal, 'income' for credit/deposit, 'transfer' for transfers>",
  "merchant": "<string or null - merchant/recipient name if mentioned>",
  "datetime": "<string or null - ISO 8601 format if date/time mentioned>",
  "balance": <number or null - remaining balance if mentioned>,
  "confidence": <number 0.0-1.0 - your confidence in the parsing>
}

Common Vietnamese banking terms:
- "GD" = Giao dịch (transaction)
- "SD" = Số dư (balance)
- "TK" = Tài khoản (account)
- "CK" = Chuyển khoản (transfer)
- "RUT" = Rút tiền (withdrawal)
- "NAP" = Nạp tiền (deposit)
- "THANH TOAN" = Thanh toán (payment)
- "-" or "trừ" = debit/expense
- "+" or "cộng" = credit/income

Return ONLY the JSON object, nothing else.
''';
  }

  ParsedTransaction? _parseAiResponse(String response) {
    try {
      // Clean response (remove markdown if any)
      var cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final amount = (json['amount'] as num?)?.toDouble();
      final typeStr = json['type'] as String?;
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.5;

      if (amount == null || typeStr == null) {
        Log.w('AI response missing required fields', label: 'AiParser');
        return null;
      }

      final type = switch (typeStr.toLowerCase()) {
        'expense' => ParsedTransactionType.expense,
        'income' => ParsedTransactionType.income,
        'transfer' => ParsedTransactionType.transfer,
        _ => ParsedTransactionType.expense,
      };

      DateTime? datetime;
      if (json['datetime'] != null) {
        try {
          datetime = DateTime.parse(json['datetime'] as String);
        } catch (_) {}
      }

      return ParsedTransaction(
        amount: amount,
        type: type,
        merchant: json['merchant'] as String?,
        datetime: datetime,
        confidence: confidence,
      );
    } catch (e) {
      Log.e('Failed to parse AI response: $e', label: 'AiParser');
      return null;
    }
  }
}
```

### Fallback Template Parser (Offline)

```dart
// lib/core/services/auto_transaction/template_parser.dart

/// Fallback parser using regex templates when AI is unavailable
class TemplateTransactionParser {

  /// Common Vietnamese bank SMS patterns
  static final List<BankSmsTemplate> _templates = [
    // Vietcombank
    BankSmsTemplate(
      bankCode: 'VCB',
      patterns: [
        // GD: -1,000,000 VND TK: ****1234 SD: 5,000,000 VND
        RegExp(r'GD:\s*([+-]?[\d,]+)\s*VND.*SD:\s*([\d,]+)\s*VND'),
        // So du TK 1234567890: 5,000,000 VND. GD: -100,000 VND tai SHOPEE
        RegExp(r'GD:\s*([+-]?[\d,]+)\s*VND\s*tai\s*(.+?)(?:\.|$)'),
      ],
    ),

    // TPBank
    BankSmsTemplate(
      bankCode: 'TPB',
      patterns: [
        // TK 12345678 -500,000d luc 14:30 05/12. SD 1,234,567d
        RegExp(r'TK\s*\d+\s*([+-]?[\d,]+)d\s*luc\s*(\d+:\d+\s*\d+/\d+).*SD\s*([\d,]+)d'),
      ],
    ),

    // Techcombank
    BankSmsTemplate(
      bankCode: 'TCB',
      patterns: [
        RegExp(r'(\d+)\s*VND.*(?:da|duoc)\s*(?:tru|cong).*(?:TK|tai khoan)', caseSensitive: false),
      ],
    ),

    // MBBank
    BankSmsTemplate(
      bankCode: 'MB',
      patterns: [
        RegExp(r'([+-]?[\d,]+)\s*VND.*TK\s*\d+.*SD:\s*([\d,]+)', caseSensitive: false),
      ],
    ),

    // Momo e-wallet
    BankSmsTemplate(
      bankCode: 'MOMO',
      patterns: [
        RegExp(r'(?:Nhan|Chuyen)\s*([\d,]+)d\s*(?:tu|den)\s*(.+?)(?:\.|$)', caseSensitive: false),
      ],
    ),
  ];

  /// Try to parse using templates (fallback when offline)
  static ParsedTransaction? parse(String message, String? bankCode) {
    // Find matching template
    final template = _templates.firstWhere(
      (t) => bankCode?.contains(t.bankCode) ?? false,
      orElse: () => _templates.first,
    );

    for (final pattern in template.patterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        // Extract amount
        final amountStr = match.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '');

        if (amount != null) {
          // Determine type from sign or keywords
          final isExpense = message.contains('-') ||
              message.toLowerCase().contains('tru') ||
              message.toLowerCase().contains('thanh toan');

          return ParsedTransaction(
            amount: amount.abs(),
            type: isExpense ? ParsedTransactionType.expense : ParsedTransactionType.income,
            merchant: match.groupCount >= 2 ? match.group(2) : null,
            confidence: 0.7, // Lower confidence for template parsing
          );
        }
      }
    }

    return null;
  }
}

class BankSmsTemplate {
  final String bankCode;
  final List<RegExp> patterns;

  BankSmsTemplate({required this.bankCode, required this.patterns});
}
```

---

## UI/UX Flow

### Permission Request Flow

```dart
// lib/features/settings/presentation/screens/auto_transaction_settings_screen.dart

class AutoTransactionSettingsScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smsEnabled = useState(false);
    final notificationEnabled = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text('Auto Transaction')),
      body: ListView(
        children: [
          // Feature explanation
          _buildExplanationCard(),

          // SMS Parsing toggle
          SwitchListTile(
            title: Text('SMS Parsing'),
            subtitle: Text('Automatically detect transactions from bank SMS'),
            value: smsEnabled.value,
            onChanged: (value) async {
              if (value) {
                final granted = await _requestSmsPermission(context);
                smsEnabled.value = granted;
              } else {
                smsEnabled.value = false;
              }
            },
          ),

          // Notification Listener toggle
          SwitchListTile(
            title: Text('Notification Listener'),
            subtitle: Text('Detect transactions from banking app notifications'),
            value: notificationEnabled.value,
            onChanged: (value) async {
              if (value) {
                final granted = await _requestNotificationPermission(context);
                notificationEnabled.value = granted;
              } else {
                notificationEnabled.value = false;
              }
            },
          ),

          Divider(),

          // Auto-approve settings
          _buildAutoApproveSection(),

          // Default wallet selection
          _buildDefaultWalletSection(),

          // Bank whitelist management
          _buildBankWhitelistSection(),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 8),
                Text('Smart Transaction Detection',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Bexly can automatically detect and create transactions from your bank SMS and notifications. '
              'Your messages are processed locally on your device and only transaction data is stored.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestSmsPermission(BuildContext context) async {
    // Show explanation dialog first
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SMS Permission'),
        content: Text(
          'Bexly needs access to read SMS messages to detect bank transactions.\n\n'
          '• Only messages from known banks are processed\n'
          '• SMS content is NOT stored permanently\n'
          '• Processing happens on your device',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Allow'),
          ),
        ],
      ),
    );

    if (proceed != true) return false;

    // Request actual permission
    // ...
    return true;
  }
}
```

### Pending Transactions UI

```dart
// lib/features/transaction/presentation/screens/pending_transactions_screen.dart

class PendingTransactionsScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTransactions = ref.watch(pendingTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Transactions'),
        actions: [
          // Bulk actions
          IconButton(
            icon: Icon(Icons.check_circle_outline),
            tooltip: 'Approve All',
            onPressed: () => _approveAll(ref),
          ),
        ],
      ),
      body: pendingTransactions.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _PendingTransactionCard(
                transaction: tx,
                onApprove: () => _approveSingle(ref, tx),
                onReject: () => _rejectSingle(ref, tx),
                onEdit: () => _editTransaction(context, tx),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No pending transactions'),
          SizedBox(height: 8),
          Text(
            'Bank transactions detected from SMS\nwill appear here for confirmation',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PendingTransactionCard extends StatelessWidget {
  final PendingTransactionEntry transaction;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  const _PendingTransactionCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.transactionType == 'expense';

    return Dismissible(
      key: Key('pending_${transaction.id}'),
      background: _buildSwipeBackground(Colors.green, Icons.check, Alignment.centerLeft),
      secondaryBackground: _buildSwipeBackground(Colors.red, Icons.close, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove();
          return true;
        } else {
          onReject();
          return true;
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
          title: Text(
            '${isExpense ? "-" : "+"}${_formatAmount(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.merchant != null)
                Text(transaction.merchant!),
              Row(
                children: [
                  Icon(
                    transaction.sourceType == PendingTransactionSource.sms
                        ? Icons.sms
                        : Icons.notifications,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(transaction.transactionDatetime),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (transaction.confidenceScore != null) ...[
                    SizedBox(width: 8),
                    _buildConfidenceBadge(transaction.confidenceScore!),
                  ],
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          onTap: onEdit,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final color = confidence >= 0.9
        ? Colors.green
        : confidence >= 0.7
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${(confidence * 100).toInt()}%',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

---

## Bank Whitelist Configuration

### Bank Whitelist Data

```dart
// lib/core/services/auto_transaction/bank_whitelist.dart

class BankInfo {
  final String code;       // Bank code (VCB, TPB, etc.)
  final String name;       // Full bank name
  final List<String> smsIds;  // SMS sender IDs
  final List<String> appPackages;  // Android package names

  const BankInfo({
    required this.code,
    required this.name,
    required this.smsIds,
    required this.appPackages,
  });
}

class BankWhitelist {
  /// Vietnam Banks
  static const List<BankInfo> vietnamBanks = [
    // Big 4 State Banks
    BankInfo(
      code: 'VCB',
      name: 'Vietcombank',
      smsIds: ['Vietcombank', 'VCB', 'VIETCOMBANK', '8149'],
      appPackages: ['com.vietcombank.vcb.mobile'],
    ),
    BankInfo(
      code: 'BIDV',
      name: 'BIDV',
      smsIds: ['BIDV', 'bidv', '8069'],
      appPackages: ['com.bidv.smartbanking'],
    ),
    BankInfo(
      code: 'VTB',
      name: 'VietinBank',
      smsIds: ['VietinBank', 'VIETINBANK', 'VTB'],
      appPackages: ['vn.com.vietinbank.ipay'],
    ),
    BankInfo(
      code: 'AGR',
      name: 'Agribank',
      smsIds: ['Agribank', 'AGRIBANK', 'AGR'],
      appPackages: ['com.vnpay.agribankplus'],
    ),

    // Commercial Banks
    BankInfo(
      code: 'TCB',
      name: 'Techcombank',
      smsIds: ['Techcombank', 'TCB', 'TECHCOMBANK', '8069'],
      appPackages: ['com.vn.tcbmobile', 'vn.com.techcombank.bb'],
    ),
    BankInfo(
      code: 'MB',
      name: 'MB Bank',
      smsIds: ['MBBank', 'MB', 'MBBANK', '8179'],
      appPackages: ['com.mbmobile'],
    ),
    BankInfo(
      code: 'ACB',
      name: 'ACB',
      smsIds: ['ACB', 'acb', '8069'],
      appPackages: ['mobile.acb.com.vn'],
    ),
    BankInfo(
      code: 'TPB',
      name: 'TPBank',
      smsIds: ['TPBank', 'TPBANK', 'TPB', '8069'],
      appPackages: ['vn.tpb.mb.gprsandroid'],
    ),
    BankInfo(
      code: 'VPB',
      name: 'VPBank',
      smsIds: ['VPBank', 'VPBANK', 'VPB'],
      appPackages: ['com.vnpay.vpbankonline'],
    ),
    BankInfo(
      code: 'VIB',
      name: 'VIB',
      smsIds: ['VIB', 'vib'],
      appPackages: ['com.vib.MyVIB'],
    ),
    BankInfo(
      code: 'SCB',
      name: 'SCB',
      smsIds: ['SCB', 'scb'],
      appPackages: ['com.scb.phone'],
    ),
    BankInfo(
      code: 'SHB',
      name: 'SHB',
      smsIds: ['SHB', 'shb'],
      appPackages: ['vn.shb.mbanking'],
    ),
    BankInfo(
      code: 'MSB',
      name: 'MSB',
      smsIds: ['MSB', 'msb'],
      appPackages: ['vn.com.msb.mobilebanking'],
    ),
    BankInfo(
      code: 'OCB',
      name: 'OCB',
      smsIds: ['OCB', 'ocb'],
      appPackages: ['com.ocb.omnifinance'],
    ),
    BankInfo(
      code: 'NAB',
      name: 'Nam A Bank',
      smsIds: ['NamABank', 'NAB'],
      appPackages: ['com.vnpay.namabank'],
    ),

    // Digital Banks
    BankInfo(
      code: 'CAKE',
      name: 'CAKE by VPBank',
      smsIds: ['CAKE', 'cake'],
      appPackages: ['com.vn.vpbank.cake'],
    ),
    BankInfo(
      code: 'TNEX',
      name: 'TNEX',
      smsIds: ['TNEX', 'tnex'],
      appPackages: ['com.msb.tnexapp'],
    ),
    BankInfo(
      code: 'UBANK',
      name: 'UBANK',
      smsIds: ['UBANK', 'ubank'],
      appPackages: ['com.ubank.app'],
    ),
  ];

  /// E-Wallets
  static const List<BankInfo> eWallets = [
    BankInfo(
      code: 'MOMO',
      name: 'MoMo',
      smsIds: ['MoMo', 'MOMO', 'Momo'],
      appPackages: ['com.mservice.momotransfer'],
    ),
    BankInfo(
      code: 'ZALOPAY',
      name: 'ZaloPay',
      smsIds: ['ZaloPay', 'ZALOPAY'],
      appPackages: ['vn.com.vng.zalopay'],
    ),
    BankInfo(
      code: 'VNPAY',
      name: 'VNPAY',
      smsIds: ['VNPAY', 'vnpay'],
      appPackages: ['com.vnpay.wallet'],
    ),
    BankInfo(
      code: 'SHOPEEPAY',
      name: 'ShopeePay',
      smsIds: ['ShopeePay', 'SHOPEEPAY'],
      appPackages: ['com.shopee.vn'],
    ),
  ];

  /// All banks and e-wallets combined
  static List<BankInfo> get all => [...vietnamBanks, ...eWallets];

  /// Check if SMS is from a known bank
  static bool isBankSms(String sender) {
    final normalizedSender = sender.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    for (final bank in all) {
      for (final smsId in bank.smsIds) {
        if (normalizedSender.contains(smsId.toUpperCase())) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if package is a banking app
  static bool isBankingApp(String packageName) {
    for (final bank in all) {
      if (bank.appPackages.contains(packageName)) {
        return true;
      }
    }
    return false;
  }

  /// Get bank info from SMS sender
  static BankInfo? getBankInfo(String sender) {
    final normalizedSender = sender.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    for (final bank in all) {
      for (final smsId in bank.smsIds) {
        if (normalizedSender.contains(smsId.toUpperCase())) {
          return bank;
        }
      }
    }
    return null;
  }

  /// Get bank info from package name
  static BankInfo? getBankInfoByPackage(String packageName) {
    for (final bank in all) {
      if (bank.appPackages.contains(packageName)) {
        return bank;
      }
    }
    return null;
  }
}
```

---

## Testing Strategy

### Unit Tests

```dart
// test/services/ai_transaction_parser_test.dart

void main() {
  group('AiTransactionParser', () {
    late AiTransactionParser parser;

    setUp(() {
      parser = AiTransactionParser(apiKey: 'test-key');
    });

    // Note: These are integration tests, mock AI for unit tests

    test('should parse VCB SMS correctly', () async {
      const sms = 'GD: -500,000 VND TK: ****1234 SD: 2,500,000 VND luc 14:30 05/12';
      final result = await parser.parseTransactionMessage(
        message: sms,
        bankCode: 'VCB',
      );

      expect(result?.amount, 500000);
      expect(result?.type, ParsedTransactionType.expense);
    });
  });

  group('TemplateTransactionParser', () {
    test('should parse VCB SMS with template', () {
      const sms = 'GD: -500,000 VND TK: ****1234 SD: 2,500,000 VND';
      final result = TemplateTransactionParser.parse(sms, 'VCB');

      expect(result?.amount, 500000);
      expect(result?.type, ParsedTransactionType.expense);
    });

    test('should parse TPBank SMS with template', () {
      const sms = 'TK 12345678 -1,000,000d luc 14:30 05/12. SD 5,000,000d';
      final result = TemplateTransactionParser.parse(sms, 'TPB');

      expect(result?.amount, 1000000);
      expect(result?.type, ParsedTransactionType.expense);
    });
  });

  group('BankWhitelist', () {
    test('should identify VCB SMS', () {
      expect(BankWhitelist.isBankSms('Vietcombank'), true);
      expect(BankWhitelist.isBankSms('VCB'), true);
      expect(BankWhitelist.isBankSms('8149'), true);
    });

    test('should not identify random SMS', () {
      expect(BankWhitelist.isBankSms('Shopee'), false);
      expect(BankWhitelist.isBankSms('FPT'), false);
    });

    test('should identify banking apps', () {
      expect(BankWhitelist.isBankingApp('com.vietcombank.vcb.mobile'), true);
      expect(BankWhitelist.isBankingApp('com.mservice.momotransfer'), true);
    });
  });
}
```

### Integration Test Scenarios

```markdown
## Manual Testing Checklist

### SMS Permission Flow
- [ ] First time enable: Shows explanation dialog
- [ ] User denies: Shows "go to settings" option
- [ ] User allows: SMS listening starts
- [ ] Toggle off: SMS listening stops

### Notification Permission Flow
- [ ] First time enable: Shows explanation dialog
- [ ] Opens system settings correctly
- [ ] Returns to app after granting permission
- [ ] Service starts after permission granted

### SMS Parsing (Manual)
- [ ] VCB SMS: Correctly parsed
- [ ] TPBank SMS: Correctly parsed
- [ ] Techcombank SMS: Correctly parsed
- [ ] MBBank SMS: Correctly parsed
- [ ] MoMo notification: Correctly parsed
- [ ] Non-bank SMS: Ignored

### Pending Transaction UI
- [ ] Shows badge count on transaction tab
- [ ] Swipe right to approve
- [ ] Swipe left to reject
- [ ] Edit before confirm works
- [ ] Approved transaction appears in history
- [ ] Rejected transaction removed

### Edge Cases
- [ ] Duplicate SMS: Not created twice
- [ ] Offline mode: Template parser works
- [ ] Low confidence: Shows warning
- [ ] Multiple SMS at once: All processed
```

---

## Implementation Checklist

### Phase 1: Foundation (Week 1)

- [ ] **Database Schema**
  - [ ] Create `pending_transactions` table in Drift
  - [ ] Create `auto_transaction_settings` table
  - [ ] Add DAOs for both tables
  - [ ] Run `dart run build_runner build`

- [ ] **Bank Whitelist**
  - [ ] Create `BankWhitelist` class with VN banks
  - [ ] Add SMS sender IDs for major banks
  - [ ] Add package names for banking apps
  - [ ] Write unit tests

- [ ] **AI Parser Service**
  - [ ] Create `AiTransactionParser` class
  - [ ] Design prompt for Gemini
  - [ ] Implement JSON response parsing
  - [ ] Create `TemplateTransactionParser` fallback
  - [ ] Write unit tests

### Phase 2: SMS Parsing (Week 2)

- [ ] **Android Configuration**
  - [ ] Add SMS permissions to AndroidManifest.xml
  - [ ] Add `telephony` and `flutter_sms_inbox` packages
  - [ ] Configure SMS broadcast receiver

- [ ] **SMS Service**
  - [ ] Implement `SmsTransactionService`
  - [ ] Permission request flow
  - [ ] Incoming SMS listener
  - [ ] Existing SMS scanner
  - [ ] Deduplication logic

- [ ] **Integration**
  - [ ] Wire up SMS service with Riverpod
  - [ ] Connect to AI parser
  - [ ] Save to pending_transactions table
  - [ ] Test with real bank SMS

### Phase 3: Notification Listener (Week 3)

- [ ] **Android Configuration**
  - [ ] Add notification listener service to manifest
  - [ ] Add `flutter_notification_listener` package

- [ ] **Notification Service**
  - [ ] Implement `NotificationTransactionService`
  - [ ] Permission request flow (system settings redirect)
  - [ ] Notification callback handler
  - [ ] Package name filtering

- [ ] **Integration**
  - [ ] Wire up notification service
  - [ ] Share AI parser with SMS service
  - [ ] Deduplication between SMS and notifications

### Phase 4: UI/UX (Week 4)

- [ ] **Settings Screen**
  - [ ] Auto Transaction settings page
  - [ ] SMS parsing toggle with permission flow
  - [ ] Notification listening toggle
  - [ ] Auto-approve settings
  - [ ] Default wallet selection

- [ ] **Pending Transactions Screen**
  - [ ] List pending transactions
  - [ ] Swipe to approve/reject
  - [ ] Edit before confirm
  - [ ] Bulk approve/reject
  - [ ] Confidence indicator

- [ ] **Transaction Tab Integration**
  - [ ] Badge showing pending count
  - [ ] Quick access to pending list
  - [ ] Notification when new pending arrives

### Phase 5: Polish & Launch (Week 5)

- [ ] **Testing**
  - [ ] Unit tests for all services
  - [ ] Integration tests with mock data
  - [ ] Manual testing with real bank SMS

- [ ] **Privacy & Security**
  - [ ] Sanitize stored messages
  - [ ] Clear explanation dialogs
  - [ ] Easy disable toggles
  - [ ] Update Privacy Policy

- [ ] **Documentation**
  - [ ] Update CHANGELOG.md
  - [ ] User guide in app
  - [ ] FAQ for common issues

---

## Cost Estimation

| Item | Cost per Unit | Estimated Monthly Usage | Monthly Cost |
|------|---------------|-------------------------|--------------|
| Gemini API (SMS parsing) | ~$0.001/request | 100 SMS/user × 1000 users | $100 |
| Gemini API (Notification) | ~$0.001/request | 50 notifs/user × 1000 users | $50 |
| **Total** | | | **$150/month** |

> Note: With fallback template parsing, AI costs can be reduced by 50-70% for common bank formats.

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Bank changes SMS format | Medium | Template updates + AI fallback |
| User privacy concerns | High | Clear explanations, local processing, no cloud storage of raw messages |
| AI parsing errors | Medium | Confidence score, user confirmation, template fallback |
| Android permission denials | Medium | Clear value proposition, multiple entry points |
| Battery drain from background services | Medium | Optimize with WorkManager, batch processing |

---

## Success Metrics

- **Adoption Rate**: 30% of users enable at least one auto-detection method
- **Accuracy**: 95%+ correct parsing rate (based on user confirmations)
- **Time Saved**: 5+ minutes/week per user on manual entry
- **User Retention**: 20% higher retention for users with auto-detection enabled
