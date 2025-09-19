import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pockaw/core/utils/logger.dart';
import 'package:pockaw/features/transaction/data/model/transaction_model.dart';

class TransactionSyncService {
  final FirebaseFirestore _firestore;

  TransactionSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> upsertTransaction({
    required String userId,
    required int transactionId,
    required TransactionModel transaction,
    String? receiptUrl,
    String? receiptStoragePath,
    required bool isCreate,
  }) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'amount': transaction.amount,
      'date': transaction.date,
      'title': transaction.title,
      'notes': transaction.notes,
      'transactionType': transaction.transactionType.name,
      'categoryId': transaction.category.id,
      'walletId': transaction.wallet.id,
      'receiptUrl': receiptUrl,
      'receiptStoragePath': receiptStoragePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((key, value) => value == null);

    if (isCreate) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    final docRef = _firestore.collection('transactions').doc('$transactionId');

    Log.i({'id': transactionId, 'data': data}, label: 'firestore upsert');
    await docRef.set(data, SetOptions(merge: true));
  }
}



