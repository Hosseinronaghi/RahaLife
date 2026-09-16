import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openRahaDatabaseConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final file = File(p.join(directory.path, 'raha_life.sqlite'));
  return NativeDatabase.createInBackground(file);
});
