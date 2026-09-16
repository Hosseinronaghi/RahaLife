import 'dart:typed_data';

import 'database_snapshot_stub.dart'
    if (dart.library.io) 'database_snapshot_io.dart'
    as implementation;

Future<Uint8List?> readDatabaseSnapshot() =>
    implementation.readDatabaseSnapshot();

Future<void> restoreDatabaseSnapshot(Uint8List bytes) =>
    implementation.restoreDatabaseSnapshot(bytes);
