import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Opens a native database connection for mobile and desktop platforms
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(join(dbFolder.path, 'pockaw.sqlite'));
    if (kDebugMode) {
      // await file.delete(); // Uncomment for fresh DB on every run in debug
    }

    // Enable foreign key constraints in SQLite
    // CRITICAL: Without this, foreign key constraints are ignored!
    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}