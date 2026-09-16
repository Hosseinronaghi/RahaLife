import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> createNativeDatabaseSafetyCopy() async {
  final directory = await getApplicationSupportDirectory();
  final databasePath = p.join(directory.path, 'raha_life.sqlite');
  final source = File(databasePath);
  if (!await source.exists()) return;

  final backup = File(p.join(directory.path, 'raha_life.pre-v0.7.sqlite.bak'));
  if (!await backup.exists()) {
    await source.copy(backup.path);
  }

  // SQLite can leave committed pages in WAL until checkpointing. The previous
  // app process is normally closed during an update, but preserving sidecars
  // too makes the pre-migration recovery artifact safer.
  for (final suffix in const <String>['-wal', '-shm']) {
    final sidecar = File('$databasePath$suffix');
    if (!await sidecar.exists()) continue;
    final sidecarBackup = File('${backup.path}$suffix');
    if (!await sidecarBackup.exists()) {
      await sidecar.copy(sidecarBackup.path);
    }
  }
}
