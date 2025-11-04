import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'database_interface.dart';

class FirestoreDatabase implements DatabaseInterface {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instanceFor(app: FirebaseInitService.bexlyApp, databaseId: "bexly");
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  firestore.CollectionReference get _userCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  @override
  Future<void> initialize() async {
    // Note: enablePersistence is only for web, not needed on mobile
    // Firestore on mobile has offline persistence enabled by default
  }

  // Wallet operations
  @override
  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final snapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getWallet(String id) async {
    final doc = await _userCollection
        .doc('wallets')
        .collection('items')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  @override
  Future<String> createWallet(Map<String, dynamic> wallet) async {
    final doc = await _userCollection
        .doc('wallets')
        .collection('items')
        .add({
      ...wallet,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<void> updateWallet(String id, Map<String, dynamic> wallet) async {
    await _userCollection
        .doc('wallets')
        .collection('items')
        .doc(id)
        .update({
      ...wallet,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteWallet(String id) async {
    // Delete wallet and all associated transactions
    final batch = _firestore.batch();

    // Delete wallet
    batch.delete(_userCollection.doc('wallets').collection('items').doc(id));

    // Delete associated transactions
    final transactions = await _userCollection
        .doc('transactions')
        .collection('items')
        .where('walletId', isEqualTo: id)
        .get();

    for (final doc in transactions.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Transaction operations
  @override
  Future<List<Map<String, dynamic>>> getAllTransactions(String walletId) async {
    final snapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .where('walletId', isEqualTo: walletId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    final doc = await _userCollection
        .doc('transactions')
        .collection('items')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  @override
  Future<String> createTransaction(Map<String, dynamic> transaction) async {
    final doc = await _userCollection
        .doc('transactions')
        .collection('items')
        .add({
      ...transaction,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<void> updateTransaction(String id, Map<String, dynamic> transaction) async {
    await _userCollection
        .doc('transactions')
        .collection('items')
        .doc(id)
        .update({
      ...transaction,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _userCollection
        .doc('transactions')
        .collection('items')
        .doc(id)
        .delete();
  }

  // Category operations
  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final snapshot = await _userCollection
        .doc('categories')
        .collection('items')
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getCategory(String id) async {
    final doc = await _userCollection
        .doc('categories')
        .collection('items')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  @override
  Future<String> createCategory(Map<String, dynamic> category) async {
    final doc = await _userCollection
        .doc('categories')
        .collection('items')
        .add({
      ...category,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<void> updateCategory(String id, Map<String, dynamic> category) async {
    await _userCollection
        .doc('categories')
        .collection('items')
        .doc(id)
        .update({
      ...category,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _userCollection
        .doc('categories')
        .collection('items')
        .doc(id)
        .delete();
  }

  // Budget operations
  @override
  Future<List<Map<String, dynamic>>> getAllBudgets(String walletId) async {
    final snapshot = await _userCollection
        .doc('budgets')
        .collection('items')
        .where('walletId', isEqualTo: walletId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getBudget(String id) async {
    final doc = await _userCollection
        .doc('budgets')
        .collection('items')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  @override
  Future<String> createBudget(Map<String, dynamic> budget) async {
    final doc = await _userCollection
        .doc('budgets')
        .collection('items')
        .add({
      ...budget,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<void> updateBudget(String id, Map<String, dynamic> budget) async {
    await _userCollection
        .doc('budgets')
        .collection('items')
        .doc(id)
        .update({
      ...budget,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _userCollection
        .doc('budgets')
        .collection('items')
        .doc(id)
        .delete();
  }
}