import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:raha_life/core/notifications/reminder_service.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/domain/money.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/core/persistence/write_status.dart';
import 'package:raha_life/core/sync/backup/logical_drift_snapshot.dart';
import 'package:raha_life/core/sync/drift_sync_store.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';
import 'package:raha_life/features/home/domain/home_entry.dart';
import 'package:raha_life/features/workspace/collaboration_outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'sync.device.v1': 'phone'});
    WriteStatus.resetForReload();
  });
  test(
    'decimal input rounds halves exactly and rejects invalid or overflowing values',
    () {
      expect(Money.parse('0.575').minorUnits, 58);
      expect(Money.parse('-0.575').minorUnits, -58);
      expect(Money.parse('۱۲۳٫۴۵۵').minorUnits, 12346);
      expect(Money.parse('5.75e-1').minorUnits, 58);
      expect(Money.parse('0.004').minorUnits, 0);
      expect(() => Money.parse('NaN'), throwsFormatException);
      expect(() => Money.parse('90071992547409.92'), throwsFormatException);
      expect(Money.readMinor(9007199254740991, null), 9007199254740991);
      final account = FinanceAccount.fromJson({
        'id': 'a',
        'name': 'A',
        'openingBalanceMinor': 9007199254740991,
      });
      expect(account.toJson()['openingBalanceMinor'], 9007199254740991);
      final state = FinanceState(
        accounts: [
          account,
          const FinanceAccount(id: 'b', name: 'B', currencyCode: 'USD'),
        ],
        transactions: [],
      );
      expect(() => state.balance, throwsStateError);
      expect(state.balanceByCurrency['IRT'], 9007199254740991);
    },
  );
  test(
    'large delta is retained separately; later edits and other records still sync',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final repo = DriftEntityRepository(database: db);
        await repo.upsert('rich_note', {
          'id': 'big',
          'text': List.filled(7 * 1024 * 1024, 'x').join(),
        });
        await repo.upsert('person', {'id': 'p', 'name': 'Person'});
        final store = DriftSyncStore(providerId: 'server', database: db);
        final first = await store.pendingChanges();
        expect(first.single.entityId, 'p');
        expect(await store.quarantinedCount(), 1);
        await store.markUploaded([first.single.changeId!]);
        await repo.upsert('rich_note', {'id': 'big', 'text': 'Reduced'});
        final next = await store.pendingChanges();
        expect(next.single.payload['text'], 'Reduced');
        expect(await db.select(db.syncChanges).get(), hasLength(3));
        final scoped = DriftSyncStore(
          providerId: 'server',
          database: db,
          entityTypes: {'person'},
        );
        expect(await scoped.pendingCount(), 0);
        expect(await scoped.quarantinedCount(), 0);
        expect(await store.pendingCount(), 1);
      } finally {
        await db.close();
      }
    },
  );
  test(
    'outer transaction rollback also restores repository observation baselines',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final repository = DriftEntityRepository(database: db);
        final values = [
          <String, Object?>{'id': 'p', 'name': 'Keep'},
        ];
        await expectLater(
          repository.atomic(() async {
            await repository.replaceAll('person', values);
            throw StateError('later transaction failed');
          }),
          throwsStateError,
        );
        expect(await db.select(db.entityDocuments).get(), isEmpty);
        await repository.atomic(() async {
          await repository.replaceAll('person', values);
        });
        expect((await repository.loadOne('person', 'p'))?['name'], 'Keep');
      } finally {
        await db.close();
      }
    },
  );
  test(
    'causally newer restore applies once, older restore keeps local, concurrent restore conflicts',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await DriftEntityRepository(
          database: db,
        ).upsert('person', {'id': 'p', 'name': 'Original'});
        final service = LogicalDriftSnapshotService(database: db);
        final original = (await service.exportEntities()).single;
        final newer = {
          ...original,
          'payload': {'id': 'p', 'name': 'New'},
          'clock': {'phone': 2},
          'version': 2,
        };
        expect(await service.mergeEntities([newer]), 1);
        expect(await service.mergeEntities([newer]), 0);
        expect(await service.mergeEntities([original]), 0);
        expect(
          jsonDecode(
            (await db.select(db.entityDocuments).getSingle()).payloadJson,
          )['name'],
          'New',
        );
        expect(await db.select(db.syncConflicts).get(), isEmpty);
        expect(
          await service.mergeEntities([
            {
              ...newer,
              'clock': {'other': 3},
              'payload': {'id': 'p', 'name': 'Concurrent'},
            },
          ]),
          0,
        );
        expect(await db.select(db.syncConflicts).get(), hasLength(1));
        final deleted = {
          ...newer,
          'clock': {'phone': 3},
          'deletedAtUtc': DateTime.now().toUtc().toIso8601String(),
        };
        expect(await service.mergeEntities([deleted]), 1);
        expect(
          (await db.select(db.entityDocuments).getSingle()).deletedAt,
          isNotNull,
        );
      } finally {
        await db.close();
      }
    },
  );
  test(
    'a failed save retries before flush; another successful operation cannot erase its error',
    () async {
      var attempts = 0;
      Future<void> save() async {
        if (++attempts == 1) throw StateError('temporary');
      }

      WriteStatus.track(save(), retry: save);
      await Future<void>.delayed(Duration.zero);
      expect(WriteStatus.error.value, isNotNull);
      WriteStatus.track(Future<void>.value());
      await Future<void>.delayed(Duration.zero);
      expect(WriteStatus.error.value, isNotNull);
      await WriteStatus.flush();
      expect(attempts, 2);
      expect(WriteStatus.error.value, isNull);
    },
  );
  test(
    'persistent save failure still blocks flush without dropping the failed operation',
    () async {
      Future<void> save() async => throw StateError('disk');
      WriteStatus.track(save(), retry: save);
      await expectLater(WriteStatus.flush(), throwsStateError);
      expect(WriteStatus.error.value, contains('disk'));
    },
  );
  test(
    'timezone refresh follows changed device zone and retains the known zone on failure',
    () async {
      final service = ReminderService.instance;
      await service.refreshTimezone(lookup: () async => 'Asia/Tehran');
      expect(tz.local.name, 'Asia/Tehran');
      expect(
        await service.refreshTimezone(lookup: () async => 'Europe/Berlin'),
        true,
      );
      expect(tz.local.name, 'Europe/Berlin');
      expect(
        await service.refreshTimezone(
          lookup: () async => throw StateError('unavailable'),
        ),
        false,
      );
      expect(tz.local.name, 'Europe/Berlin');
    },
  );
  test('non-leap birthdays fall on the last day of the original month', () {
    final gregorian = HomeEntry(
      id: 'g',
      title: 'G',
      type: HomeEntryType.birthday,
      dateTime: DateTime(2024, 2, 29),
    );
    expect(gregorian.occursOn(DateTime(2025, 2, 28)), true);
    expect(gregorian.occursOn(DateTime(2025, 3, 1)), false);
    expect(gregorian.occursOn(DateTime(2024, 2, 29)), true);
    final jalali = HomeEntry(
      id: 'j',
      title: 'J',
      type: HomeEntryType.birthday,
      dateTime: Jalali(1399, 12, 30).toDateTime(),
      calendar: 'jalali',
    );
    expect(jalali.occursOn(Jalali(1400, 12, 29).toDateTime()), true);
    expect(jalali.occursOn(Jalali(1403, 12, 30).toDateTime()), true);
  });
  test(
    'enqueue during send remains after acknowledging the earlier message',
    () async {
      final queue = CollaborationOutbox('https://server', 'alice');
      final first = await queue.enqueue('bob', 'first');
      final sending = Completer<void>(), release = Completer<void>();
      final run = queue.retry((_) async {
        sending.complete();
        await release.future;
      });
      await sending.future;
      final second = await queue.enqueue('bob', 'second');
      release.complete();
      await run;
      expect((await queue.read('outbox')).map((e) => e['id']), [second['id']]);
      expect(first['id'], isNot(second['id']));
    },
  );
}
