import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/utils/logger.dart';

/// Represents a mapping between a bank sender and a wallet
class BankWalletMapping {
  final String senderId;
  final String bankName;
  final String bankCode;
  final int walletId;
  final DateTime createdAt;

  BankWalletMapping({
    required this.senderId,
    required this.bankName,
    required this.bankCode,
    required this.walletId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'bankName': bankName,
        'bankCode': bankCode,
        'walletId': walletId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BankWalletMapping.fromJson(Map<String, dynamic> json) {
    return BankWalletMapping(
      senderId: json['senderId'] as String,
      bankName: json['bankName'] as String,
      bankCode: json['bankCode'] as String,
      walletId: json['walletId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'BankWalletMapping($bankName -> walletId: $walletId)';
}

/// Result of scanning SMS for bank senders
class SmsScanResult {
  final String senderId;
  final String bankName;
  final String bankCode;
  final String country;
  final int messageCount;
  final String? detectedCurrency;
  final List<ScannedTransaction> transactions;

  SmsScanResult({
    required this.senderId,
    required this.bankName,
    required this.bankCode,
    required this.country,
    required this.messageCount,
    this.detectedCurrency,
    this.transactions = const [],
  });

  @override
  String toString() => 'SmsScanResult($bankName: $messageCount messages)';
}

/// A scanned transaction before being imported
class ScannedTransaction {
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime dateTime;
  final String? merchant;
  final String? description;
  final String rawMessage;
  final String currency;

  ScannedTransaction({
    required this.amount,
    required this.type,
    required this.dateTime,
    this.merchant,
    this.description,
    required this.rawMessage,
    this.currency = 'VND',
  });
}

/// Service to manage bank-wallet mappings
class BankWalletMappingService {
  static const String _storageKey = 'bank_wallet_mappings';

  /// Get all mappings
  Future<List<BankWalletMapping>> getMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      return jsonList.map((json) {
        return BankWalletMapping.fromJson(jsonDecode(json));
      }).toList();
    } catch (e) {
      Log.e('Error loading bank wallet mappings: $e', label: 'BankWalletMapping');
      return [];
    }
  }

  /// Get wallet ID for a sender
  Future<int?> getWalletIdForSender(String senderId) async {
    final mappings = await getMappings();
    final normalizedSender = senderId.toLowerCase().trim();

    for (final mapping in mappings) {
      if (mapping.senderId.toLowerCase() == normalizedSender ||
          mapping.bankName.toLowerCase() == normalizedSender ||
          normalizedSender.contains(mapping.senderId.toLowerCase()) ||
          normalizedSender.contains(mapping.bankName.toLowerCase())) {
        return mapping.walletId;
      }
    }
    return null;
  }

  /// Add a new mapping
  Future<void> addMapping(BankWalletMapping mapping) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      // Remove existing mapping for this sender if any
      jsonList.removeWhere((json) {
        final existing = BankWalletMapping.fromJson(jsonDecode(json));
        return existing.senderId.toLowerCase() == mapping.senderId.toLowerCase();
      });

      jsonList.add(jsonEncode(mapping.toJson()));
      await prefs.setStringList(_storageKey, jsonList);

      Log.d('Added mapping: $mapping', label: 'BankWalletMapping');
    } catch (e) {
      Log.e('Error adding bank wallet mapping: $e', label: 'BankWalletMapping');
    }
  }

  /// Add multiple mappings
  Future<void> addMappings(List<BankWalletMapping> mappings) async {
    for (final mapping in mappings) {
      await addMapping(mapping);
    }
  }

  /// Remove a mapping by sender ID
  Future<void> removeMapping(String senderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      jsonList.removeWhere((json) {
        final mapping = BankWalletMapping.fromJson(jsonDecode(json));
        return mapping.senderId.toLowerCase() == senderId.toLowerCase();
      });

      await prefs.setStringList(_storageKey, jsonList);
      Log.d('Removed mapping for sender: $senderId', label: 'BankWalletMapping');
    } catch (e) {
      Log.e('Error removing bank wallet mapping: $e', label: 'BankWalletMapping');
    }
  }

  /// Remove mapping by wallet ID (when wallet is deleted)
  Future<void> removeMappingByWalletId(int walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      jsonList.removeWhere((json) {
        final mapping = BankWalletMapping.fromJson(jsonDecode(json));
        return mapping.walletId == walletId;
      });

      await prefs.setStringList(_storageKey, jsonList);
      Log.d('Removed mapping for wallet: $walletId', label: 'BankWalletMapping');
    } catch (e) {
      Log.e('Error removing bank wallet mapping: $e', label: 'BankWalletMapping');
    }
  }

  /// Check if a sender already has a mapping
  Future<bool> hasMappingForSender(String senderId) async {
    final walletId = await getWalletIdForSender(senderId);
    return walletId != null;
  }

  /// Clear all mappings
  Future<void> clearAllMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      Log.d('Cleared all bank wallet mappings', label: 'BankWalletMapping');
    } catch (e) {
      Log.e('Error clearing bank wallet mappings: $e', label: 'BankWalletMapping');
    }
  }
}
