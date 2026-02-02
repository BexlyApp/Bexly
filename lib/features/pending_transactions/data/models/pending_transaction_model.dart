import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/pending_transaction_dao.dart';

part 'pending_transaction_model.freezed.dart';
part 'pending_transaction_model.g.dart';

/// Source of the pending transaction
enum PendingTxSource {
  @JsonValue('email')
  email,
  @JsonValue('bank')
  bank,
  @JsonValue('sms')
  sms,
  @JsonValue('notification')
  notification,
}

/// Status of the pending transaction
enum PendingTxStatus {
  @JsonValue('pending_review')
  pendingReview,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('imported')
  imported,
}

/// Extension to convert enum to/from string
extension PendingTxSourceExt on PendingTxSource {
  String get value {
    switch (this) {
      case PendingTxSource.email:
        return PendingSource.email;
      case PendingTxSource.bank:
        return PendingSource.bank;
      case PendingTxSource.sms:
        return PendingSource.sms;
      case PendingTxSource.notification:
        return PendingSource.notification;
    }
  }

  static PendingTxSource fromString(String value) {
    switch (value) {
      case PendingSource.email:
        return PendingTxSource.email;
      case PendingSource.bank:
        return PendingTxSource.bank;
      case PendingSource.sms:
        return PendingTxSource.sms;
      case PendingSource.notification:
        return PendingTxSource.notification;
      default:
        return PendingTxSource.notification;
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case PendingTxSource.email:
        return 'Email';
      case PendingTxSource.bank:
        return 'Bank';
      case PendingTxSource.sms:
        return 'SMS';
      case PendingTxSource.notification:
        return 'Notification';
    }
  }
}

extension PendingTxStatusExt on PendingTxStatus {
  String get value {
    switch (this) {
      case PendingTxStatus.pendingReview:
        return PendingStatus.pendingReview;
      case PendingTxStatus.approved:
        return PendingStatus.approved;
      case PendingTxStatus.rejected:
        return PendingStatus.rejected;
      case PendingTxStatus.imported:
        return PendingStatus.imported;
    }
  }

  static PendingTxStatus fromString(String value) {
    switch (value) {
      case PendingStatus.pendingReview:
        return PendingTxStatus.pendingReview;
      case PendingStatus.approved:
        return PendingTxStatus.approved;
      case PendingStatus.rejected:
        return PendingTxStatus.rejected;
      case PendingStatus.imported:
        return PendingTxStatus.imported;
      default:
        return PendingTxStatus.pendingReview;
    }
  }
}

@freezed
abstract class PendingTransactionModel with _$PendingTransactionModel {
  const PendingTransactionModel._();

  const factory PendingTransactionModel({
    int? id,
    String? cloudId,
    required PendingTxSource source,
    required String sourceId,
    required double amount,
    @Default('VND') String currency,
    required String transactionType, // 'income' or 'expense'
    required String title,
    String? merchant,
    required DateTime transactionDate,
    @Default(0.8) double confidence,
    String? categoryHint,
    required String sourceDisplayName,
    String? sourceIconUrl,
    String? accountIdentifier,
    @Default(PendingTxStatus.pendingReview) PendingTxStatus status,
    int? importedTransactionId,
    int? targetWalletId,
    int? selectedCategoryId,
    String? userNotes,
    String? rawSourceData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PendingTransactionModel;

  factory PendingTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionModelFromJson(json);

  /// Create from Drift entity
  factory PendingTransactionModel.fromEntity(PendingTransaction entity) {
    return PendingTransactionModel(
      id: entity.id,
      cloudId: entity.cloudId,
      source: PendingTxSourceExt.fromString(entity.source),
      sourceId: entity.sourceId,
      amount: entity.amount,
      currency: entity.currency,
      transactionType: entity.transactionType,
      title: entity.title,
      merchant: entity.merchant,
      transactionDate: entity.transactionDate,
      confidence: entity.confidence,
      categoryHint: entity.categoryHint,
      sourceDisplayName: entity.sourceDisplayName,
      sourceIconUrl: entity.sourceIconUrl,
      accountIdentifier: entity.accountIdentifier,
      status: PendingTxStatusExt.fromString(entity.status),
      importedTransactionId: entity.importedTransactionId,
      targetWalletId: entity.targetWalletId,
      selectedCategoryId: entity.selectedCategoryId,
      userNotes: entity.userNotes,
      rawSourceData: entity.rawSourceData,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Whether this is an income transaction
  bool get isIncome => transactionType == 'income';

  /// Whether this is an expense transaction
  bool get isExpense => transactionType == 'expense';

  /// Whether this transaction is pending review
  bool get isPendingReview => status == PendingTxStatus.pendingReview;

  /// Get formatted amount with sign
  String get formattedAmount {
    final sign = isIncome ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0)}';
  }
}
