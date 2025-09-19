import 'package:flutter/foundation.dart';

abstract class DatabaseInterface {
  Future<void> initialize();

  // Wallet operations
  Future<List<Map<String, dynamic>>> getAllWallets();
  Future<Map<String, dynamic>?> getWallet(String id);
  Future<String> createWallet(Map<String, dynamic> wallet);
  Future<void> updateWallet(String id, Map<String, dynamic> wallet);
  Future<void> deleteWallet(String id);

  // Transaction operations
  Future<List<Map<String, dynamic>>> getAllTransactions(String walletId);
  Future<Map<String, dynamic>?> getTransaction(String id);
  Future<String> createTransaction(Map<String, dynamic> transaction);
  Future<void> updateTransaction(String id, Map<String, dynamic> transaction);
  Future<void> deleteTransaction(String id);

  // Category operations
  Future<List<Map<String, dynamic>>> getAllCategories();
  Future<Map<String, dynamic>?> getCategory(String id);
  Future<String> createCategory(Map<String, dynamic> category);
  Future<void> updateCategory(String id, Map<String, dynamic> category);
  Future<void> deleteCategory(String id);

  // Budget operations
  Future<List<Map<String, dynamic>>> getAllBudgets(String walletId);
  Future<Map<String, dynamic>?> getBudget(String id);
  Future<String> createBudget(Map<String, dynamic> budget);
  Future<void> updateBudget(String id, Map<String, dynamic> budget);
  Future<void> deleteBudget(String id);
}

// Factory function to get the appropriate database implementation
DatabaseInterface getDatabaseImplementation() {
  if (kIsWeb) {
    // Web will use Firestore
    throw UnimplementedError('Web database not yet implemented');
  } else {
    // Mobile/Desktop will use Drift
    throw UnimplementedError('Native database wrapper not yet implemented');
  }
}