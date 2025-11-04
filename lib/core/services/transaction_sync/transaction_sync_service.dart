import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';

class TransactionSyncService {
  final firestore.FirebaseFirestore _firestore;

  TransactionSyncService({firestore.FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? firestore.FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly");

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
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }..removeWhere((key, value) => value == null);

    if (isCreate) {
      data['createdAt'] = firestore.FieldValue.serverTimestamp();
    }

    final docRef = _firestore.collection('transactions').doc('$transactionId');

    Log.i({'id': transactionId, 'data': data}, label: 'firestore upsert');
    await docRef.set(data, firestore.SetOptions(merge: true));
  }
}



