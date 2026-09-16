import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openRahaDatabaseConnection() => DatabaseConnection.delayed(
  Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'raha_life',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  }),
);
