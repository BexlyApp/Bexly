import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_email_transaction_model.freezed.dart';
part 'parsed_email_transaction_model.g.dart';

/// Status of a parsed email transaction
enum ParsedTransactionStatus {
  /// Pending user review
  pendingReview,

  /// Approved by user, ready to import
  approved,

  /// Rejected by user
  rejected,

  /// Already imported to transactions
  imported,
}

/// Model for a transaction parsed from email
@freezed
abstract class ParsedEmailTransactionModel with _$ParsedEmailTransactionModel {
  const factory ParsedEmailTransactionModel({
    /// Unique ID (local)
    int? id,

    /// Cloud ID (for sync)
    String? cloudId,

    /// Gmail message ID (for deduplication)
    required String emailId,

    /// Email subject
    required String emailSubject,

    /// Sender email address
    required String fromEmail,

    /// Transaction amount (always positive)
    required double amount,

    /// Currency code (VND, USD, etc.)
    @Default('VND') String currency,

    /// Transaction type: 'income' or 'expense'
    required String transactionType,

    /// Merchant or payee name
    String? merchant,

    /// Last 4 digits of account number
    String? accountLast4,

    /// Balance after transaction
    double? balanceAfter,

    /// Date of the transaction
    required DateTime transactionDate,

    /// Date the email was received
    required DateTime emailDate,

    /// Confidence score (0-1)
    @Default(0.8) double confidence,

    /// Raw amount text from email
    required String rawAmountText,

    /// Suggested category
    String? categoryHint,

    /// Bank or e-wallet name
    required String bankName,

    /// Status of the parsed transaction
    @Default(ParsedTransactionStatus.pendingReview) ParsedTransactionStatus status,

    /// ID of the imported transaction (if imported)
    String? importedTransactionId,

    /// User's wallet ID to import to
    String? targetWalletCloudId,

    /// User's selected category ID
    String? selectedCategoryCloudId,

    /// User's notes/edits
    String? userNotes,

    /// Created timestamp
    DateTime? createdAt,

    /// Updated timestamp
    DateTime? updatedAt,
  }) = _ParsedEmailTransactionModel;

  factory ParsedEmailTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$ParsedEmailTransactionModelFromJson(json);
}

/// Extension methods for ParsedEmailTransactionModel
extension ParsedEmailTransactionModelX on ParsedEmailTransactionModel {
  /// Check if transaction is income
  bool get isIncome => transactionType == 'income';

  /// Check if transaction is expense
  bool get isExpense => transactionType == 'expense';

  /// Check if pending review
  bool get isPending => status == ParsedTransactionStatus.pendingReview;

  /// Check if approved
  bool get isApproved => status == ParsedTransactionStatus.approved;

  /// Check if imported
  bool get isImported => status == ParsedTransactionStatus.imported;

  /// Display amount with sign
  String get displayAmount {
    final sign = isIncome ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0)} $currency';
  }

  /// Confidence percentage
  int get confidencePercent => (confidence * 100).round();

  /// Short description for display
  String get shortDescription {
    if (merchant != null && merchant!.isNotEmpty) {
      return merchant!;
    }
    return emailSubject.length > 50
        ? '${emailSubject.substring(0, 50)}...'
        : emailSubject;
  }
}
