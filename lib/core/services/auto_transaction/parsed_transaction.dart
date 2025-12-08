import 'package:bexly/features/transaction/data/model/transaction_model.dart';

/// Represents a parsed transaction from SMS or notification
class ParsedTransaction {
  final double amount;
  final TransactionType type;
  final DateTime dateTime;
  final String? merchant;
  final String? accountNumber;
  final double? balance;
  final String? reference;
  final String rawMessage;
  final String source; // 'sms' or 'notification'
  final String? senderId;
  final String? bankName;

  const ParsedTransaction({
    required this.amount,
    required this.type,
    required this.dateTime,
    this.merchant,
    this.accountNumber,
    this.balance,
    this.reference,
    required this.rawMessage,
    required this.source,
    this.senderId,
    this.bankName,
  });

  /// Generate a unique hash for deduplication
  /// Uses amount + datetime (rounded to minute) + merchant
  String get deduplicationHash {
    final roundedTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
    final key = '${amount.toStringAsFixed(2)}_${roundedTime.millisecondsSinceEpoch}_${merchant ?? 'unknown'}';
    return key;
  }

  /// Generate title for the transaction
  String get title {
    if (merchant != null && merchant!.isNotEmpty) {
      return merchant!;
    }
    return type == TransactionType.income ? 'Received funds' : 'Payment';
  }

  /// Generate notes for the transaction
  String get notes {
    final parts = <String>[];
    if (bankName != null) parts.add('Bank: $bankName');
    if (accountNumber != null) parts.add('Account: $accountNumber');
    if (reference != null) parts.add('Ref: $reference');
    if (balance != null) parts.add('Balance: $balance');
    parts.add('Source: $source');
    return parts.join('\n');
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'type': type.name,
    'dateTime': dateTime.toIso8601String(),
    'merchant': merchant,
    'accountNumber': accountNumber,
    'balance': balance,
    'reference': reference,
    'rawMessage': rawMessage,
    'source': source,
    'senderId': senderId,
    'bankName': bankName,
  };

  @override
  String toString() => 'ParsedTransaction(${type.name}: $amount, merchant: $merchant, date: $dateTime)';
}
