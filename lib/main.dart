import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/migration/primary_data_migration.dart';
import 'core/migration/safe_upgrade.dart';
import 'core/notifications/reminder_service.dart';
import 'core/sync/backup/local_backup_service.dart';
import 'core/persistence/write_status.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SafeUpgradeCoordinator.prepare();
  try {
    await LocalBackupService().resumePendingRestore();
    await PrimaryDataMigrationCoordinator.migrateAll();
  } catch (error) {
    WriteStatus.report(error);
  }
  await ReminderService.instance.initialize();
  runApp(const ProviderScope(child: RahaLifeApp()));
}
