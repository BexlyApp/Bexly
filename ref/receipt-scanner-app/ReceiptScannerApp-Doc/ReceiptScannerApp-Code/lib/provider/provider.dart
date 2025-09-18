import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

class ReceiptScanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> get scanHistory => _scanHistory;

  ReceiptScanProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final rawHistory = await _dbHelper.getAllReceipts();
      _scanHistory = rawHistory.map((entry) {
        // Ensure all required fields exist
        return {
          DatabaseHelper.columnId: entry[DatabaseHelper.columnId],
          DatabaseHelper.columnResult: entry[DatabaseHelper.columnResult] ?? '{}',
          DatabaseHelper.columnTimestamp: entry[DatabaseHelper.columnTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
          // Include all other fields with null checks
          DatabaseHelper.columnAmount: entry[DatabaseHelper.columnAmount] ?? 0.0,
          DatabaseHelper.columnCategory: entry[DatabaseHelper.columnCategory] ?? 'Uncategorized',
          DatabaseHelper.columnDate: entry[DatabaseHelper.columnDate],
          DatabaseHelper.columnMerchant: entry[DatabaseHelper.columnMerchant],
          DatabaseHelper.columnPaymentMethod: entry[DatabaseHelper.columnPaymentMethod],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
      _scanHistory = [];
      notifyListeners();
    }
  }
  Future<void> saveScan(
      String title,
      Uint8List image,
      String result, {
        required double amount,
        required String category,
        String? date,
        String? merchant,
        String? paymentMethod,
      }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imagePath).writeAsBytes(image);

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _dbHelper.insertReceipt({
        DatabaseHelper.columnTitle: title,
        DatabaseHelper.columnImagePath: imagePath,
        DatabaseHelper.columnResult: result,
        DatabaseHelper.columnTimestamp: timestamp,
        DatabaseHelper.columnAmount: amount,
        DatabaseHelper.columnCategory: category,
        DatabaseHelper.columnDate: date,
        DatabaseHelper.columnMerchant: merchant,
        DatabaseHelper.columnPaymentMethod: paymentMethod,
      });

      _scanHistory = await _dbHelper.getAllReceipts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving scan: $e');
      rethrow;
    }
  }

  Future<Uint8List?> getScanImage(int id) async {
    return await _dbHelper.getReceiptImage(id);
  }

  Future<void> deleteScan(int id) async {
    await _dbHelper.deleteReceipt(id);
    await loadHistory();
  }

  Map<String, double> getSpendingByCategory() {
    final categoryTotals = <String, double>{};

    for (final entry in _scanHistory) {
      final category = entry[DatabaseHelper.columnCategory] as String? ?? 'Uncategorized';
      final amount = entry[DatabaseHelper.columnAmount] as double? ?? 0.0;
      categoryTotals.update(category, (total) => total + amount, ifAbsent: () => amount);
    }

    return categoryTotals;
  }

  Map<String, double> getMonthlySpending() {
    final monthlyTotals = <String, double>{};
    final _ = DateTime.now();

    for (final entry in _scanHistory) {
      final timestamp = entry[DatabaseHelper.columnTimestamp] as int?;
      if (timestamp == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = entry[DatabaseHelper.columnAmount] as double? ?? 0.0;

      monthlyTotals.update(monthKey, (total) => total + amount, ifAbsent: () => amount);
    }

    return monthlyTotals;
  }

  double getTotalSpending() {
    return _scanHistory.fold(0.0, (sum, entry) {
      final amount = entry[DatabaseHelper.columnAmount] as double? ?? 0.0;
      return sum + amount;
    });
  }
}