import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/home/domain/home_entry.dart';
import 'package:raha_life/features/home/domain/linked_birthdays.dart';
import 'package:raha_life/features/people/domain/person.dart';
import 'package:raha_life/features/people/presentation/people_controller.dart';
import 'package:raha_life/features/cycle/domain/cycle_forecast.dart';
import 'package:raha_life/features/cycle/domain/cycle_log.dart';
import 'package:raha_life/features/cycle/presentation/cycle_controller.dart';
import 'package:raha_life/features/finance/domain/finance_models.dart';
import 'package:raha_life/features/finance/presentation/finance_controller.dart';
import 'package:raha_life/features/notes/presentation/notes_controller.dart';
import 'package:raha_life/core/sync/sync_scope.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  test(
    'birthday follows person edits, removes legacy duplicates and disappears on clear',
    () {
      final people = PeopleNotifier(persistenceEnabled: false);
      final id = people.add(
        name: 'سارا',
        birthDate: DateTime(2000, 3, 21),
        birthCalendar: 'jalali',
      );
      final copies = [
        for (var i = 0; i < 2; i++)
          HomeEntry(
            id: 'old$i',
            type: HomeEntryType.birthday,
            title: 'old',
            personId: id,
            dateTime: DateTime(2000, 1, 1),
          ),
      ];
      expect(withPeopleBirthdays(copies, people.state), hasLength(1));
      people.add(
        id: id,
        name: 'سارا جدید',
        birthDate: DateTime(2000, 4, 1),
        birthCalendar: 'jalali',
      );
      final birthday = withPeopleBirthdays(copies, people.state).single;
      expect(birthday.title, 'سارا جدید');
      expect(birthday.dateTime, DateTime(2000, 4, 1));
      expect(birthday.id, 'old0');
      expect(birthday.calendar, 'jalali');
      people.add(id: id, name: 'سارا جدید');
      expect(withPeopleBirthdays(copies, people.state), isEmpty);
      people.dispose();
    },
  );
  test('Jalali birthday recurs on matching Jalali month and day', () {
    final birthday = withPeopleBirthdays([], [
      Person(
        id: 'p',
        name: 'p',
        birthDate: Jalali(1370, 1, 1).toDateTime(),
        birthCalendar: 'jalali',
      ),
    ]).single;
    expect(birthday.occursOn(Jalali(1405, 1, 1).toDateTime()), isTrue);
    expect(birthday.occursOn(Jalali(1405, 1, 2).toDateTime()), isFalse);
  });
  test('old people preserve Gregorian calendar and accept additive fields', () {
    final old = Person.fromJson({
      'id': 'p',
      'name': 'p',
      'birthDate': '2000-01-02T00:00:00.000',
    });
    expect(old.birthCalendar, 'gregorian');
    expect(Person.fromJson(old.toJson()).birthDate, old.birthDate);
  });
  test('editing existing cycle retains ID and rejects reversed dates', () {
    final c = CycleNotifier(persistenceEnabled: false);
    final first = c.add(
      startDate: DateTime(2026, 1, 1),
      flow: FlowIntensity.light,
      painLevel: 0,
      mood: CycleMood.calm,
    );
    c.add(
      id: first.id,
      startDate: DateTime(2026, 1, 2),
      endDate: DateTime(2026, 1, 6),
      flow: FlowIntensity.medium,
      painLevel: 3,
      mood: CycleMood.low,
      conflictReminders: true,
    );
    expect(c.state, hasLength(1));
    expect(c.state.single.conflictReminders, isTrue);
    expect(
      () => c.add(
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 1, 1),
        flow: FlowIntensity.light,
        painLevel: 0,
        mood: CycleMood.calm,
      ),
      throwsArgumentError,
    );
    c.dispose();
  });
  test(
    'cycle forecast uses inclusive duration and calendar days for overlaps',
    () {
      final f = CycleForecast.fromLogs([
        CycleLog(
          id: '1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 5),
          flow: FlowIntensity.medium,
          painLevel: 0,
          mood: CycleMood.calm,
        ),
      ])!;
      expect(f.start, DateTime(2026, 1, 29));
      expect(f.durationDays, 5);
      expect(f.overlaps(DateTime(2026, 2, 2, 23)), true);
      expect(f.overlaps(DateTime(2026, 2, 3)), false);
      expect(f.samples, 0);
    },
  );
  test(
    'editing transfer applies only the final amount and preserves combined balance',
    () {
      final c = FinanceNotifier(persistenceEnabled: false);
      c.addAccount('a', id: 'a', openingBalance: 100);
      c.addAccount('b', id: 'b');
      final t = c.addTransaction(
        type: FinanceTransactionType.transfer,
        amount: 20,
        dateTime: DateTime(2026),
        accountId: 'a',
        toAccountId: 'b',
      );
      c.addTransaction(
        id: t.id,
        type: t.type,
        amount: 30,
        dateTime: t.dateTime,
        accountId: 'a',
        toAccountId: 'b',
      );
      expect(c.state.transactions, hasLength(1));
      expect(c.state.accountBalanceMinor('a'), 7000);
      expect(c.state.accountBalanceMinor('b'), 3000);
      expect(c.state.balance, 100);
      expect(
        () => c.addAccount('a', id: 'a', currencyCode: 'USD'),
        throwsArgumentError,
      );
      c.dispose();
    },
  );
  test('cross-currency transfers and archived targets are rejected', () {
    final c = FinanceNotifier(persistenceEnabled: false);
    c.addAccount('a', id: 'a');
    c.addAccount('b', id: 'b', currencyCode: 'USD');
    expect(
      () => c.addTransaction(
        type: FinanceTransactionType.transfer,
        amount: 1,
        dateTime: DateTime(2026),
        accountId: 'a',
        toAccountId: 'b',
      ),
      throwsArgumentError,
    );
    c.addAccount('b', id: 'b', archived: true);
    expect(
      () => c.addTransaction(
        type: FinanceTransactionType.transfer,
        amount: 1,
        dateTime: DateTime(2026),
        accountId: 'a',
        toAccountId: 'b',
      ),
      throwsArgumentError,
    );
    c.dispose();
  });
  test('editing note retains rich content and scheduled date', () {
    final c = NotesNotifier(persistenceEnabled: false);
    final n = c.save(
      title: 'a',
      deltaJson: '[{"insert":"hello\\n"}]',
      plainText: 'hello',
      scheduledAt: DateTime(2026, 10, 1),
    );
    c.save(
      id: n.id,
      title: 'b',
      deltaJson: n.deltaJson,
      plainText: n.plainText,
    );
    expect(c.state, hasLength(1));
    expect(c.state.single.scheduledAt, n.scheduledAt);
    expect(c.state.single.deltaJson, n.deltaJson);
    c.dispose();
  });
  test('default selective sync excludes health finance people and events', () {
    final types = syncTypes({'modules': defaultSyncModules.join(',')})!;
    expect(types, contains('shopping_item'));
    for (final type in [
      'cycle_log',
      'finance_transaction',
      'person',
      'home_entry',
    ]) {
      expect(types, isNot(contains(type)));
    }
    expect(syncTypes({'modules': ''}), isEmpty);
    expect(syncTypes({}), isNull);
  });
}
