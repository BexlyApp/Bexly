import 'package:drift/drift.dart';

// Conditional imports for different platforms
import 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart' as impl;

/// Opens a database connection based on the current platform
LazyDatabase openConnection() {
  return impl.openConnection();
}