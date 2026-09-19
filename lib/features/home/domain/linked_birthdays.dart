import 'home_entry.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../people/domain/person.dart';

/// People are the source of truth. Old linked copies are projected, never duplicated.
List<HomeEntry> withPeopleBirthdays(
  Iterable<HomeEntry> entries,
  Iterable<Person> people,
) {
  final originals = entries.toList();
  final result = originals
      .where((e) => e.type != HomeEntryType.birthday || e.personId == null)
      .toList();
  for (final person in people) {
    if (person.birthDate == null) continue;
    final old = originals
        .where(
          (e) => e.type == HomeEntryType.birthday && e.personId == person.id,
        )
        .firstOrNull;
    result.add(
      HomeEntry(
        id: old?.id ?? 'person-birthday:${person.id}',
        type: HomeEntryType.birthday,
        title: person.name,
        dateTime: person.birthDate!,
        details: person.relationship,
        personId: person.id,
        calendar: person.birthCalendar,
        reminder: old?.reminder ?? const ReminderPlan(),
      ),
    );
  }
  return result;
}
