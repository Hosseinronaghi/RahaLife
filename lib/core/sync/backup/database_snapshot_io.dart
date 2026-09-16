import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _databaseFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(p.join(directory.path, 'raha_life.sqlite'));
}

Future<Uint8List?> readDatabaseSnapshot() async {
  final file = await _databaseFile();
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> restoreDatabaseSnapshot(Uint8List bytes) async {
  throw UnsupportedError(
    'Use logical merge restore; active SQLite files cannot be replaced.',
  );
}
