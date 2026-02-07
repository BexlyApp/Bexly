import 'package:flutter/material.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_form.dart';

/// Helper class to open TransactionForm with pending transaction data
/// Replaces the old custom bottom sheet with the standard TransactionForm
class ApproveTransactionSheet {
  /// Navigate to TransactionForm with pending transaction data pre-filled
  static Future<void> show(BuildContext context, PendingTransactionModel pending) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionForm(pendingTransaction: pending),
      ),
    );
  }
}
