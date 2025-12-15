import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Opens a web database connection using WebAssembly SQLite
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    try {
      debugPrint('🌐 [WebDB] Opening web database with WasmDatabase...');

      final result = await WasmDatabase.open(
        databaseName: 'bexly_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        debugPrint('🌐 [WebDB] Using ${result.chosenImplementation} due to unsupported features: ${result.missingFeatures}');
      } else {
        debugPrint('🌐 [WebDB] Successfully opened with ${result.chosenImplementation}');
      }

      return result.resolvedExecutor;
    } catch (e, stack) {
      debugPrint('❌ [WebDB] Error opening WasmDatabase: $e');
      debugPrint('❌ [WebDB] Stack: $stack');

      // Re-throw the error so we can see it in console
      // The app should handle this gracefully
      rethrow;
    }
  });
}