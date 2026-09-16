import 'dart:typed_data';

Future<Uint8List?> readDatabaseSnapshot() async => null;

Future<void> restoreDatabaseSnapshot(Uint8List bytes) async {
  // Web primary-domain data is restored through LogicalDriftSnapshotService.
  // Raw SQLite replacement is intentionally unsupported in a running browser.
}
