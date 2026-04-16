import 'dart:async';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/auto_transaction/bank_senders.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/auto_transaction/transaction_parser_service.dart';

// SMS feature disabled for hackathon submission (no READ_SMS/RECEIVE_SMS permissions).
// All methods return false/empty. Re-enable by restoring from git history.

/// Callback type for when a new transaction is parsed from SMS
typedef OnTransactionParsed = void Function(ParsedTransaction transaction);

/// SMS scan result for bank sender discovery
class SmsScanResult {
  final String senderId;
  final String bankName;
  final String bankCode;
  final String country;
  final int messageCount;
  final String detectedCurrency;
  final List<ParsedTransaction> transactions;

  SmsScanResult({
    required this.senderId,
    required this.bankName,
    required this.bankCode,
    required this.country,
    required this.messageCount,
    required this.detectedCurrency,
    required this.transactions,
  });
}

/// Stub SMS service - all methods return false/empty (SMS disabled)
class SmsService {
  final TransactionParserService _parserService;

  SmsService({
    required TransactionParserService parserService,
    TransactionDeduplicationService? deduplicationService,
  }) : _parserService = parserService;

  bool get isAvailable => false;
  bool get isListening => false;

  Future<bool> requestPermissions() async {
    Log.w('SMS feature disabled for this build', label: 'SmsService');
    return false;
  }

  Future<bool> hasPermissions() async => false;

  Future<bool> startListening({
    required OnTransactionParsed onTransactionParsed,
  }) async {
    Log.w('SMS feature disabled for this build', label: 'SmsService');
    return false;
  }

  void stopListening() {}

  Future<List<ParsedTransaction>> scanExistingMessages({
    int limit = 100,
    Duration? maxAge,
  }) async => [];

  Future<List<SmsScanResult>> scanForBankSenders({
    int limit = 500,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async => [];

  Future<List<ParsedTransaction>> parseTransactionsForSender({
    required String bankCode,
    int limit = 100,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async => [];
}
