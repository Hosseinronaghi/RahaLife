import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/sync/backup/local_backup_service.dart';
import 'package:raha_life/core/sync/backup/logical_drift_snapshot.dart';
import 'package:raha_life/core/sync/backup/sync_crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'federation.outbox': 'old-message',
      'federation.outbox.encrypted.v1': 'device-only-ciphertext',
      'theme.mode': 'dark',
    });
  });
  test(
    'portable backups exclude both old and encrypted device outboxes',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final crypto = SyncCryptoService();
      final service = LocalBackupService(
        crypto: crypto,
        logicalSnapshot: LogicalDriftSnapshotService(database: db),
      );
      final backup = await service.createEncryptedBackup();
      final payload =
          jsonDecode(utf8.decode(await crypto.decrypt(backup.bytes))) as Map;
      expect(payload['preferences'], {'theme.mode': 'dark'});
    },
  );
  test(
    'restoring an older backup does not replace this devices queue',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final crypto = SyncCryptoService();
      final service = LocalBackupService(
        crypto: crypto,
        logicalSnapshot: LogicalDriftSnapshotService(database: db),
      );
      final bytes = await crypto.encrypt(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'format': 'raha-life-backup',
              'payloadVersion': 2,
              'entities': [],
              'preferences': {
                'federation.outbox': 'foreign-old-message',
                'federation.outbox.encrypted.v1': 'foreign-key-ciphertext',
                'theme.mode': 'light',
              },
            }),
          ),
        ),
      );
      await service.restoreEncryptedBackup(bytes);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('federation.outbox'), 'old-message');
      expect(
        prefs.getString('federation.outbox.encrypted.v1'),
        'device-only-ciphertext',
      );
      expect(prefs.getString('theme.mode'), 'light');
    },
  );
}
