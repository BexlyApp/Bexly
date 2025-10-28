import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/utils/logger.dart';

/// Data structure for sync conflict information
class SyncConflictInfo {
  final int localItemCount;
  final int cloudItemCount;
  final DateTime? localLastUpdate;
  final DateTime? cloudLastUpdate;
  final String? latestLocalTransaction;
  final String? latestCloudTransaction;
  final int localWalletCount;
  final int cloudWalletCount;
  final int localTransactionCount;
  final int cloudTransactionCount;

  SyncConflictInfo({
    required this.localItemCount,
    required this.cloudItemCount,
    this.localLastUpdate,
    this.cloudLastUpdate,
    this.latestLocalTransaction,
    this.latestCloudTransaction,
    required this.localWalletCount,
    required this.cloudWalletCount,
    required this.localTransactionCount,
    required this.cloudTransactionCount,
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
      Log.i('🔍 Querying cloud wallets (limit 1)...', label: 'sync');
      final cloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ Cloud wallets query completed: ${cloudWallets.docs.length} docs', label: 'sync');

      Log.i('🔍 Querying cloud transactions (limit 1)...', label: 'sync');
      final cloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ Cloud transactions query completed: ${cloudTransactions.docs.length} docs', label: 'sync');

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

      // Both local and cloud have data - potential conflict detected!
      Log.w('Potential conflict: both local and cloud have data', label: 'sync');

      // Get cloud data counts and latest updates
      Log.i('🔍 Querying all cloud wallets...', label: 'sync');
      final allCloudWallets = await _userCollection
          .doc('wallets')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ All cloud wallets query completed: ${allCloudWallets.docs.length} docs', label: 'sync');

      // Fetch all cloud transactions and find latest locally (no orderBy to avoid index requirement)
      Log.i('🔍 Querying all cloud transactions...', label: 'sync');
      final allCloudTransactions = await _userCollection
          .doc('transactions')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      Log.i('✓ All cloud transactions query completed: ${allCloudTransactions.docs.length} docs', label: 'sync');

      // AUTO-RESOLVE LOGIC: Check if this is a trivial conflict that can be auto-resolved
      final localWalletCount = localWallets.length;
      final cloudWalletCount = allCloudWallets.docs.length;
      final localTxCount = localTransactions.length;
      final cloudTxCount = allCloudTransactions.docs.length;

      // Rule 1: If both have same counts and ZERO transactions -> Auto-merge (no data loss risk)
      if (localWalletCount == cloudWalletCount && localTxCount == 0 && cloudTxCount == 0) {
        Log.i('✅ Auto-resolve: Same wallet count ($localWalletCount) and no transactions on either side. No conflict needed.', label: 'sync');
        return null; // No conflict dialog needed
      }

      // Rule 2: If one side has ONLY wallets (no transactions) and counts match -> Prefer the side with more recent data or just merge
      if (localTxCount == 0 && cloudTxCount == 0 && localWalletCount == cloudWalletCount) {
        Log.i('✅ Auto-resolve: Both sides have $localWalletCount wallet(s) and 0 transactions. Safe to merge.', label: 'sync');
        return null;
      }

      // If we reach here, it's a real conflict that needs user decision
      Log.w('⚠️ Real conflict detected - user decision required', label: 'sync');

      // Get latest transaction info
      String? latestLocalTx;
      DateTime? localLastUpdate;
      if (localTransactions.isNotEmpty) {
        final latest = localTransactions.reduce((a, b) =>
            a.updatedAt.isAfter(b.updatedAt) ? a : b);
        latestLocalTx = '${latest.title} (${latest.amount})';
        localLastUpdate = latest.updatedAt;
      }

      // Find latest cloud transaction by iterating (instead of using orderBy)
      String? latestCloudTx;
      DateTime? cloudLastUpdate;
      if (allCloudTransactions.docs.isNotEmpty) {
        for (final doc in allCloudTransactions.docs) {
          final data = doc.data();
          final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
          if (updatedAt != null && (cloudLastUpdate == null || updatedAt.isAfter(cloudLastUpdate))) {
            cloudLastUpdate = updatedAt;
            latestCloudTx = '${data['title']} (${data['amount']})';
          }
        }
      }

      return SyncConflictInfo(
        localItemCount: localWallets.length + localTransactions.length,
        cloudItemCount: allCloudWallets.docs.length + allCloudTransactions.docs.length,
        localLastUpdate: localLastUpdate,
        cloudLastUpdate: cloudLastUpdate,
        latestLocalTransaction: latestLocalTx,
        latestCloudTransaction: latestCloudTx,
        localWalletCount: localWallets.length,
        cloudWalletCount: allCloudWallets.docs.length,
        localTransactionCount: localTransactions.length,
        cloudTransactionCount: allCloudTransactions.docs.length,
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
    Log.i('🔍 Downloading cloud wallets...', label: 'sync');
    final walletsSnapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Downloaded ${walletsSnapshot.docs.length} wallets', label: 'sync');

    for (final doc in walletsSnapshot.docs) {
      final data = doc.data();
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
    Log.i('🔍 Downloading cloud transactions...', label: 'sync');
    final transactionsSnapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Downloaded ${transactionsSnapshot.docs.length} transactions', label: 'sync');

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
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

    Log.i('✅ Downloaded ${walletsSnapshot.docs.length} wallets and ${transactionsSnapshot.docs.length} transactions', label: 'sync');
  }

  /// Clear all cloud data
  Future<void> _clearCloudData() async {
    // Delete all wallets
    Log.i('🔍 Fetching cloud wallets to delete...', label: 'sync');
    final walletsSnapshot = await _userCollection
        .doc('wallets')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Fetched ${walletsSnapshot.docs.length} wallets to delete', label: 'sync');

    for (final doc in walletsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all transactions
    Log.i('🔍 Fetching cloud transactions to delete...', label: 'sync');
    final transactionsSnapshot = await _userCollection
        .doc('transactions')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 10));
    Log.i('✓ Fetched ${transactionsSnapshot.docs.length} transactions to delete', label: 'sync');

    for (final doc in transactionsSnapshot.docs) {
      await doc.reference.delete();
    }

    Log.i('✅ Cleared cloud data', label: 'sync');
  }
}
