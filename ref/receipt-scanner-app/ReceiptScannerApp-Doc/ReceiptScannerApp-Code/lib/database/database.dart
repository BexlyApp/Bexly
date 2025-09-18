import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'receipt_expense_tracker.db';
  static const _databaseVersion = 1;

  // Receipt table constants
  static const table = 'receipt_history';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnImagePath = 'image_path';
  static const columnResult = 'result';
  static const columnTimestamp = 'timestamp';
  static const columnAmount = 'amount';
  static const columnCategory = 'category';
  static const columnDate = 'expense_date';
  static const columnMerchant = 'merchant';
  static const columnPaymentMethod = 'payment_method';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnImagePath TEXT NOT NULL,
        $columnResult TEXT NOT NULL,
        $columnTimestamp INTEGER NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnDate TEXT,
        $columnMerchant TEXT,
        $columnPaymentMethod TEXT
      )
    ''');
  }

  Future<int> insertReceipt(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await database;
    final results = await db.query(
      table,
      columns: [
        columnId,
        columnTitle,
        columnResult,  // Make sure this is included
        columnAmount,
        columnCategory,
        columnTimestamp,
        columnDate,
        columnMerchant,
        columnPaymentMethod
      ],
      orderBy: '$columnTimestamp DESC',
    );

    // Ensure all fields have values
    return results.map((row) {
      return {
        columnId: row[columnId],
        columnTitle: row[columnTitle] ?? 'No Title',
        columnResult: row[columnResult] ?? '{}', // Ensure result exists
        columnAmount: row[columnAmount] ?? 0.0,
        columnCategory: row[columnCategory] ?? 'Uncategorized',
        columnTimestamp: row[columnTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
        columnDate: row[columnDate],
        columnMerchant: row[columnMerchant],
        columnPaymentMethod: row[columnPaymentMethod],
      };
    }).toList();
  }
  Future<Uint8List?> getReceiptImage(int id) async {
    final db = await database;
    final result = await db.query(
      table,
      columns: [columnImagePath],
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final imagePath = result.first[columnImagePath] as String;
      if (imagePath.isNotEmpty) {
        return await File(imagePath).readAsBytes();
      }
    }
    return null;
  }

  Future<int> deleteReceipt(int id) async {
    final db = await database;
    // First get the image path to delete the file
    final result = await db.query(
      table,
      columns: [columnImagePath],
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final imagePath = result.first[columnImagePath] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          await File(imagePath).delete();
        } catch (e) {
          debugPrint('Error deleting image file: $e');
        }
      }
    }

    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}