import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/migration/primary_data_migration.dart';
import 'core/migration/safe_upgrade.dart';
import 'core/notifications/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SafeUpgradeCoordinator.prepare();
  await PrimaryDataMigrationCoordinator.migrateAll();
  await ReminderService.instance.initialize();
  runApp(const ProviderScope(child: RahaLifeApp()));
}
