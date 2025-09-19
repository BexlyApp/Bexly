import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens a web database connection using IndexedDB
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    return WebDatabase.withStorage(
      DriftWebStorage.indexedDb('pockaw_db',
        migrateFromLocalStorage: false,
        inWebWorker: false,
      ),
      logStatements: true,
    );
  });
}