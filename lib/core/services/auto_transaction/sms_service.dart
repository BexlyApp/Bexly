import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/auto_transaction/bank_senders.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/auto_transaction/transaction_parser_service.dart';

/// Callback type for when a new transaction is parsed from SMS
typedef OnTransactionParsed = void Function(ParsedTransaction transaction);

/// Service to read and parse bank SMS messages
class SmsService {
  final Telephony _telephony = Telephony.instance;
  final TransactionParserService _parserService;
  final TransactionDeduplicationService _deduplicationService;

  StreamSubscription<SmsMessage>? _smsSubscription;
  OnTransactionParsed? _onTransactionParsed;

  bool _isListening = false;

  SmsService({
    required TransactionParserService parserService,
    TransactionDeduplicationService? deduplicationService,
  })  : _parserService = parserService,
        _deduplicationService = deduplicationService ?? TransactionDeduplicationService();

  /// Check if SMS service is available on this platform
  bool get isAvailable => Platform.isAndroid;

  /// Check if currently listening for SMS
  bool get isListening => _isListening;

  /// Request SMS permissions
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      Log.w('SMS permissions only available on Android', label: 'SmsService');
      return false;
    }

    try {
      // Request READ_SMS permission
      final readStatus = await Permission.sms.request();
      Log.d('READ_SMS permission status: $readStatus', label: 'SmsService');

      if (!readStatus.isGranted) {
        Log.w('SMS read permission not granted', label: 'SmsService');
        return false;
      }

      return true;
    } catch (e) {
      Log.e('Error requesting SMS permissions: $e', label: 'SmsService');
      return false;
    }
  }

  /// Check if SMS permissions are granted
  Future<bool> hasPermissions() async {
    if (!Platform.isAndroid) return false;

    final readStatus = await Permission.sms.status;
    return readStatus.isGranted;
  }

  /// Start listening for incoming SMS messages
  Future<bool> startListening({
    required OnTransactionParsed onTransactionParsed,
  }) async {
    if (!Platform.isAndroid) {
      Log.w('SMS listening only available on Android', label: 'SmsService');
      return false;
    }

    if (_isListening) {
      Log.d('Already listening for SMS', label: 'SmsService');
      return true;
    }

    final hasPerms = await hasPermissions();
    if (!hasPerms) {
      Log.w('SMS permissions not granted', label: 'SmsService');
      return false;
    }

    _onTransactionParsed = onTransactionParsed;

    try {
      // Listen for incoming SMS using telephony package
      _telephony.listenIncomingSms(
        onNewMessage: _handleIncomingSms,
        onBackgroundMessage: _backgroundMessageHandler,
        listenInBackground: true,
      );

      _isListening = true;
      Log.d('Started listening for SMS', label: 'SmsService');
      return true;
    } catch (e) {
      Log.e('Error starting SMS listener: $e', label: 'SmsService');
      return false;
    }
  }

  /// Stop listening for SMS
  void stopListening() {
    _smsSubscription?.cancel();
    _smsSubscription = null;
    _onTransactionParsed = null;
    _isListening = false;
    Log.d('Stopped listening for SMS', label: 'SmsService');
  }

  /// Handle incoming SMS message
  void _handleIncomingSms(SmsMessage message) async {
    Log.d('Received SMS from: ${message.address}', label: 'SmsService');

    final sender = message.address ?? '';
    final body = message.body ?? '';

    if (sender.isEmpty || body.isEmpty) {
      Log.d('Empty sender or body, ignoring', label: 'SmsService');
      return;
    }

    // Check if sender is a known bank
    final bankSender = findBankSender(sender);
    if (bankSender == null) {
      Log.d('Sender $sender is not a known bank, ignoring', label: 'SmsService');
      return;
    }

    Log.d('Bank SMS detected from ${bankSender.bankName}', label: 'SmsService');

    // Parse the message
    final parsed = await _parserService.parseMessage(
      message: body,
      source: 'sms',
      senderId: sender,
      bankName: bankSender.bankName,
      messageTime: message.date != null
          ? DateTime.fromMillisecondsSinceEpoch(message.date!)
          : DateTime.now(),
    );

    if (parsed == null) {
      Log.d('Could not parse transaction from SMS', label: 'SmsService');
      return;
    }

    // Check for duplicates
    final isDuplicate = await _deduplicationService.isDuplicate(parsed);
    if (isDuplicate) {
      Log.d('Duplicate transaction detected, ignoring', label: 'SmsService');
      return;
    }

    // Mark as processed
    await _deduplicationService.markProcessed(parsed);

    // Notify callback
    Log.d('New transaction parsed: $parsed', label: 'SmsService');
    _onTransactionParsed?.call(parsed);
  }

  /// Read existing SMS messages from inbox (for initial scan)
  Future<List<ParsedTransaction>> scanExistingMessages({
    int limit = 100,
    Duration? maxAge,
  }) async {
    if (!Platform.isAndroid) return [];

    final hasPerms = await hasPermissions();
    if (!hasPerms) {
      Log.w('SMS permissions not granted for scanning', label: 'SmsService');
      return [];
    }

    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      Log.d('Found ${messages.length} SMS messages', label: 'SmsService');

      final cutoffTime = maxAge != null
          ? DateTime.now().subtract(maxAge).millisecondsSinceEpoch
          : 0;

      final results = <ParsedTransaction>[];

      for (final message in messages.take(limit)) {
        final sender = message.address ?? '';
        final body = message.body ?? '';
        final date = message.date;

        // Skip if too old
        if (date != null && date < cutoffTime) {
          continue;
        }

        // Check if sender is a known bank
        final bankSender = findBankSender(sender);
        if (bankSender == null) continue;

        // Parse the message
        final parsed = await _parserService.parseMessage(
          message: body,
          source: 'sms',
          senderId: sender,
          bankName: bankSender.bankName,
          messageTime: date != null ? DateTime.fromMillisecondsSinceEpoch(date) : DateTime.now(),
        );

        if (parsed == null) continue;

        // Check for duplicates
        final isDuplicate = await _deduplicationService.isDuplicate(parsed);
        if (isDuplicate) continue;

        results.add(parsed);

        // Add small delay to avoid rate limiting AI API
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Log.d('Parsed ${results.length} transactions from existing SMS', label: 'SmsService');
      return results;
    } catch (e) {
      Log.e('Error scanning existing SMS: $e', label: 'SmsService');
      return [];
    }
  }

  /// Scan SMS inbox and return results grouped by bank sender
  /// This is used for the initial setup flow to show user which banks were found
  Future<List<SmsScanResult>> scanForBankSenders({
    int limit = 500,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async {
    if (!Platform.isAndroid) return [];

    final hasPerms = await hasPermissions();
    if (!hasPerms) {
      Log.w('SMS permissions not granted for scanning', label: 'SmsService');
      return [];
    }

    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      Log.d('Found ${messages.length} SMS messages to scan', label: 'SmsService');

      final cutoffTime = maxAge != null
          ? DateTime.now().subtract(maxAge).millisecondsSinceEpoch
          : 0;

      // Group messages by bank sender
      final Map<String, _BankScanData> bankMessages = {};

      int processed = 0;
      final total = messages.take(limit).length;

      for (final message in messages.take(limit)) {
        processed++;
        onProgress?.call(processed, total);

        final sender = message.address ?? '';
        final body = message.body ?? '';
        final date = message.date;

        // Skip if too old
        if (date != null && date < cutoffTime) {
          continue;
        }

        // Check if sender is a known bank
        final bankSender = findBankSender(sender);
        if (bankSender == null) continue;

        // Group by bank code (use senderId if bankCode is null)
        final key = bankSender.bankCode ?? bankSender.senderId;
        if (!bankMessages.containsKey(key)) {
          bankMessages[key] = _BankScanData(
            sender: bankSender,
            messages: [],
          );
        }

        bankMessages[key]!.messages.add(_RawSmsData(
          body: body,
          date: date != null ? DateTime.fromMillisecondsSinceEpoch(date) : DateTime.now(),
        ));
      }

      Log.d('Found ${bankMessages.length} bank senders', label: 'SmsService');

      // Convert to SmsScanResult with currency detection
      final results = <SmsScanResult>[];

      for (final entry in bankMessages.entries) {
        final data = entry.value;
        final currency = _detectCurrency(data.messages.map((m) => m.body).toList());

        results.add(SmsScanResult(
          senderId: data.sender.senderId,
          bankName: data.sender.bankName,
          bankCode: data.sender.bankCode ?? data.sender.senderId,
          country: data.sender.country,
          messageCount: data.messages.length,
          detectedCurrency: currency,
          transactions: [], // Will be populated when user selects to import
        ));
      }

      // Sort by message count descending
      results.sort((a, b) => b.messageCount.compareTo(a.messageCount));

      return results;
    } catch (e) {
      Log.e('Error scanning for bank senders: $e', label: 'SmsService');
      return [];
    }
  }

  /// Parse transactions for a specific bank sender
  Future<List<ParsedTransaction>> parseTransactionsForSender({
    required String bankCode,
    int limit = 100,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async {
    if (!Platform.isAndroid) return [];

    final hasPerms = await hasPermissions();
    if (!hasPerms) return [];

    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final cutoffTime = maxAge != null
          ? DateTime.now().subtract(maxAge).millisecondsSinceEpoch
          : 0;

      // Filter messages for this bank
      final bankMessages = <SmsMessage>[];
      for (final message in messages) {
        final sender = message.address ?? '';
        final bankSender = findBankSender(sender);
        if (bankSender != null &&
            (bankSender.bankCode ?? bankSender.senderId) == bankCode) {
          final date = message.date;
          if (date == null || date >= cutoffTime) {
            bankMessages.add(message);
          }
        }
      }

      Log.d('Found ${bankMessages.length} messages for $bankCode', label: 'SmsService');

      final results = <ParsedTransaction>[];
      int processed = 0;
      final total = bankMessages.take(limit).length;

      for (final message in bankMessages.take(limit)) {
        processed++;
        onProgress?.call(processed, total);

        final sender = message.address ?? '';
        final body = message.body ?? '';
        final bankSender = findBankSender(sender);

        if (bankSender == null) continue;

        // Parse the message
        final parsed = await _parserService.parseMessage(
          message: body,
          source: 'sms',
          senderId: sender,
          bankName: bankSender.bankName,
          messageTime: message.date != null
              ? DateTime.fromMillisecondsSinceEpoch(message.date!)
              : DateTime.now(),
        );

        if (parsed != null) {
          results.add(parsed);
        }

        // Add small delay to avoid rate limiting AI API
        await Future.delayed(const Duration(milliseconds: 50));
      }

      return results;
    } catch (e) {
      Log.e('Error parsing transactions for sender: $e', label: 'SmsService');
      return [];
    }
  }

  /// Detect currency from SMS messages
  String _detectCurrency(List<String> messages) {
    final currencyPatterns = {
      'VND': RegExp(r'VND|đ|đồng', caseSensitive: false),
      'USD': RegExp(r'USD|\$|dollars?', caseSensitive: false),
      'EUR': RegExp(r'EUR|€|euros?', caseSensitive: false),
      'THB': RegExp(r'THB|฿|baht', caseSensitive: false),
      'SGD': RegExp(r'SGD|S\$', caseSensitive: false),
      'IDR': RegExp(r'IDR|Rp|rupiah', caseSensitive: false),
      'MYR': RegExp(r'MYR|RM|ringgit', caseSensitive: false),
    };

    final counts = <String, int>{};

    for (final message in messages) {
      for (final entry in currencyPatterns.entries) {
        if (entry.value.hasMatch(message)) {
          counts[entry.key] = (counts[entry.key] ?? 0) + 1;
        }
      }
    }

    if (counts.isEmpty) return 'VND'; // Default

    // Return currency with most matches
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Internal class for grouping scan data
class _BankScanData {
  final BankSender sender;
  final List<_RawSmsData> messages;

  _BankScanData({required this.sender, required this.messages});
}

/// Internal class for raw SMS data
class _RawSmsData {
  final String body;
  final DateTime date;

  _RawSmsData({required this.body, required this.date});
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
void _backgroundMessageHandler(SmsMessage message) async {
  // Background handling is limited - we'll process it when app comes to foreground
  // Store in SharedPreferences for later processing
  try {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getStringList('pending_sms_messages') ?? [];

    final messageData = {
      'address': message.address,
      'body': message.body,
      'date': message.date,
    };

    pendingJson.add(messageData.toString());

    // Keep only last 50 pending messages
    if (pendingJson.length > 50) {
      pendingJson.removeRange(0, pendingJson.length - 50);
    }

    await prefs.setStringList('pending_sms_messages', pendingJson);
  } catch (e) {
    debugPrint('Error storing background SMS: $e');
  }
}
