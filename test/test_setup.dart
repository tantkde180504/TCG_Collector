import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize SQLite for testing
void setupTestDatabase() {
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
