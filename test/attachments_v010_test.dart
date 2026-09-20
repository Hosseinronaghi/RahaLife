import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/attachments.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/sync/backup/logical_drift_snapshot.dart';
import 'package:raha_life/features/files/voice_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'sync.device.v1': 'attachment-tests',
    }),
  );
  test(
    'multi-chunk file survives backup and restore on fresh database',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final restored = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      addTearDown(restored.close);
      final store = AttachmentStore(
        repository: DriftEntityRepository(database: db),
      );
      final bytes = Uint8List.fromList(List.generate(100000, (i) => i % 251));
      final item = await store.put(bytes, '../image.bin');
      expect(item['name'], 'image.bin');
      expect(await store.read(item['path'] as String), bytes);
      final snapshot = await LogicalDriftSnapshotService(
        database: db,
      ).exportEntities();
      expect(
        snapshot.where((e) => e['entityType'] == 'attachment_chunk'),
        hasLength(4),
      );
      await LogicalDriftSnapshotService(
        database: restored,
      ).mergeEntities(snapshot);
      final other = AttachmentStore(
        repository: DriftEntityRepository(database: restored),
      );
      expect(await other.read(item['path'] as String), bytes);
    },
  );
  test('corrupted chunk fails integrity validation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftEntityRepository(database: db);
    final store = AttachmentStore(repository: repo);
    final item = await store.put(Uint8List.fromList([1, 2, 3]), 'file.bin');
    final chunk = await repo.loadOne('attachment_chunk', '${item['id']}:0');
    await repo.upsert('attachment_chunk', {
      ...chunk!,
      'bytes': base64Encode([4, 5, 6]),
    });
    await expectLater(store.read(item['path'] as String), throwsStateError);
  });
  test(
    'reattaching repairs missing chunks without duplicating metadata',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftEntityRepository(database: db);
      final store = AttachmentStore(repository: repo);
      final bytes = Uint8List.fromList(List.generate(70000, (i) => i % 199));
      final id = sha256.convert(bytes).toString();
      await repo.upsert('attachment_blob', {
        'id': id,
        'name': 'original.bin',
        'size': bytes.length,
        'chunks': 3,
      });
      await expectLater(store.read('raha-attachment:$id'), throwsStateError);
      await store.put(bytes, 'renamed.bin');
      expect(await store.read('raha-attachment:$id'), bytes);
      expect(
        (await store.metadata('raha-attachment:$id'))['name'],
        'original.bin',
      );
    },
  );
  test('old inline attachment stays readable', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftEntityRepository(database: db);
    final bytes = Uint8List.fromList([4, 8, 12]);
    final id = sha256.convert(bytes).toString();
    await repo.upsert('attachment_blob', {
      'id': id,
      'name': 'legacy.bin',
      'size': 3,
      'bytes': base64Encode(bytes),
    });
    expect(
      await AttachmentStore(repository: repo).read('raha-attachment:$id'),
      bytes,
    );
  });
  test('PCM recording produces a correctly sized mono WAVE header', () {
    final wave = pcmToWave(Uint8List.fromList([1, 2, 3, 4]));
    expect(ascii.decode(wave.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wave.sublist(8, 12)), 'WAVE');
    final header = ByteData.sublistView(wave);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), 16000);
    expect(header.getUint32(40, Endian.little), 4);
    expect(wave.length, 48);
  });
}
