import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart';
import 'package:bexly/core/database/pockaw_database.dart';
import 'package:bexly/core/utils/logger.dart';

/// Data structure for sync conflict information
class SyncConflictInfo {
  final int localItemCount;
  final int cloudItemCount;
  final DateTime? localLastUpdate;
  final DateTime? cloudLastUpdate;
  final String? latestLocalTransaction;
  final String? latestCloudTransaction;

  SyncConflictInfo({
    required this.localItemCount,
    required this.cloudItemCount,
    this.localLastUpdate,
    this.cloudLastUpdate,
    this.latestLocalTransaction,
    this.latestCloudTransaction,
  });
}

/// Service to handle conflict detection and resolution
class ConflictResolutionService {
  final AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final String _userId;

  ConflictResolutionService({
    required AppDatabase localDb,
    required FirebaseFirestore firestore,
    required String userId,
  })  : _localDb = localDb,
        _firestore = firestore,
        _userId = userId;

  /// Get user's data collection reference
  CollectionReference get _userCollection {
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  /// Check if there's a conflict between local and cloud data
  Future<SyncConflictInfo?> detectConflict() async {
    try {
      // Check if cloud data exists
      final cloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .limit(1)
          .get();

      final cloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .limit(1)
          .get();

      // If no cloud data exists, no conflict
      if (cloudWallets.docs.isEmpty && cloudTransactions.docs.isEmpty) {
        Log.i('No cloud data found, no conflict', label: 'sync');
        return null;
      }

      // Get local data counts
      final localWallets = await _localDb.walletDao.getAllWallets();
      final localTransactions = await _localDb.transactionDao.getAllTransactions();

      // If no local data, no conflict (can safely download cloud data)
      if (localWallets.isEmpty && localTransactions.isEmpty) {
        Log.i('No local data found, no conflict', label: 'sync');
        return null;
      }

      // Both local and cloud have data - conflict detected!
      Log.w('Conflict detected: both local and cloud have data', label: 'sync');

      // Get cloud data counts and latest updates
      final allCloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .get();

      final allCloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      // Get latest transaction info
      String? latestLocalTx;
      DateTime? localLastUpdate;
      if (localTransactions.isNotEmpty) {
        final latest = localTransactions.reduce((a, b) =>
            a.updatedAt.isAfter(b.updatedAt) ? a : b);
        latestLocalTx = '${latest.title} (${latest.amount})';
        localLastUpdate = latest.updatedAt;
      }

      String? latestCloudTx;
      DateTime? cloudLastUpdate;
      if (allCloudTransactions.docs.isNotEmpty) {
        final latestDoc = allCloudTransactions.docs.first;
        final data = latestDoc.data() as Map<String, dynamic>;
        latestCloudTx = '${data['title']} (${data['amount']})';
        cloudLastUpdate = (data['updatedAt'] as Timestamp).toDate();
      }

      return SyncConflictInfo(
        localItemCount: localWallets.length + localTransactions.length,
        cloudItemCount: allCloudWallets.docs.length + allCloudTransactions.docs.length,
        localLastUpdate: localLastUpdate,
        cloudLastUpdate: cloudLastUpdate,
        latestLocalTransaction: latestLocalTx,
        latestCloudTransaction: latestCloudTx,
      );
    } catch (e) {
      Log.e('Error detecting conflict: $e', label: 'sync');
      return null;
    }
  }

  /// Replace local data with cloud data
  Future<void> useCloudData() async {
    try {
      Log.i('Using cloud data, clearing local data...', label: 'sync');

      // Clear all local data
      await _localDb.transaction(() async {
        await _localDb.delete(_localDb.transactions).go();
        await _localDb.delete(_localDb.wallets).go();
        await _localDb.delete(_localDb.categories).go();
        await _localDb.delete(_localDb.budgets).go();
        await _localDb.delete(_localDb.goals).go();
        await _localDb.delete(_localDb.checklistItems).go();
      });

      // Download cloud data
      await _downloadCloudData();

      Log.i('✅ Successfully replaced local data with cloud data', label: 'sync');
    } catch (e) {
      Log.e('❌ Failed to use cloud data: $e', label: 'sync');
      rethrow;
    }
  }

  /// Keep local data and upload to cloud (overwrite cloud)
  Future<void> useLocalData() async {
    try {
      Log.i('Using local data, will upload to cloud...', label: 'sync');

      // Clear cloud data first
      await _clearCloudData();

      // This will be handled by normal sync flow
      // The caller should trigger fullSync() after this

      Log.i('✅ Cleared cloud data, ready for local upload', label: 'sync');
    } catch (e) {
      Log.e('❌ Failed to use local data: $e', label: 'sync');
      rethrow;
    }
  }

  /// Download all cloud data to local database
  Future<void> _downloadCloudData() async {
    // Download wallets
    final walletsSnapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .get();

    for (final doc in walletsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      await _localDb.into(_localDb.wallets).insert(
        WalletsCompanion(
          cloudId: Value(doc.id),
          name: Value(data['name'] as String),
          balance: Value(data['balance'] as double),
          currency: Value(data['currency'] as String),
          iconName: Value(data['iconName'] as String?),
          colorHex: Value(data['colorHex'] as String?),
          createdAt: Value((data['createdAt'] as Timestamp).toDate()),
          updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
        ),
      );
    }

    // Download transactions
    final transactionsSnapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .get();

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      await (_localDb.into(_localDb.transactions)).insert(
        TransactionsCompanion.insert(
          transactionType: data['transactionType'] as int,
          amount: data['amount'] as double,
          date: (data['date'] as Timestamp).toDate(),
          title: data['title'] as String,
          categoryId: data['categoryId'] as int,
          walletId: data['walletId'] as int,
          cloudId: Value(doc.id),
          notes: Value(data['notes'] as String?),
          imagePath: Value(data['imagePath'] as String?),
          isRecurring: Value(data['isRecurring'] as bool?),
          createdAt: Value((data['createdAt'] as Timestamp).toDate()),
          updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
        ),
      );
    }

    Log.i('Downloaded ${walletsSnapshot.docs.length} wallets and ${transactionsSnapshot.docs.length} transactions', label: 'sync');
  }

  /// Clear all cloud data
  Future<void> _clearCloudData() async {
    // Delete all wallets
    final walletsSnapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .get();

    for (final doc in walletsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all transactions
    final transactionsSnapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .get();

    for (final doc in transactionsSnapshot.docs) {
      await doc.reference.delete();
    }

    Log.i('Cleared cloud data', label: 'sync');
  }
}
