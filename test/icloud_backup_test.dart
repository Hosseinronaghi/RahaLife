import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/providers/backup_target.dart';
import 'package:raha_life/core/sync/providers/icloud_backup_target.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.raha.icloud');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('iCloud reports signed-container unavailability as a failed connection', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'icloud_unavailable');
    });
    final target = ICloudBackupTarget(channel: channel);
    expect((await target.testConnection()).success, isFalse);
  });

  test('iCloud channel carries unchanged encrypted backup bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'check') return true;
      if (call.method == 'upload') {
        expect(call.arguments, bytes);
        return null;
      }
      return {'bytes': bytes, 'fileName': 'saved.rahabackup', 'createdAtMillis': 5};
    });
    final target = ICloudBackupTarget(channel: channel);
    expect((await target.testConnection()).success, isTrue);
    await target.upload(BackupObject(bytes: bytes, fileName: 'local.rahabackup', createdAtUtc: DateTime.utc(2026)));
    final restored = await target.downloadLatest();
    expect(restored!.bytes, bytes);
    expect(restored.createdAtUtc.millisecondsSinceEpoch, 5);
  });
}
