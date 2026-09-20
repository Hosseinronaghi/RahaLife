import '../../features/medication/domain/medication_dose.dart';
import '../../features/cycle/domain/cycle_forecast.dart';
import '../../features/people/domain/person.dart';
import '../../features/home/domain/linked_birthdays.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../../features/home/domain/home_entry.dart';
import '../../features/medication/domain/medication_plan.dart';
import '../../features/cycle/domain/cycle_log.dart';
import 'reminder_models.dart';

class AgendaItem {
  const AgendaItem(
    this.key,
    this.title,
    this.at,
    this.route,
    this.plan, {
    this.done = false,
    this.type = 'affair',
    this.entityId,
    this.entityType,
  });
  final String key, title, route, type;
  final String? entityId, entityType;
  final DateTime at;
  final ReminderPlan plan;
  final bool done;
}

final agendaProvider = StreamProvider<List<AgendaItem>>(
  (ref) =>
      (appDatabase.select(appDatabase.entityDocuments)..where(
            (r) => r.entityType.isIn([
              'home_entry',
              'person',
              'medication_plan',
              'medication_dose',
              'entertainment',
              'shopping_list',
              'finance_transaction',
              'rich_note',
              'project',
              'cycle_log',
            ]),
          ))
          .watch()
          .map((rows) {
            final result = <AgendaItem>[], cycles = <CycleLog>[];
            final now = DateTime.now();
            final day = DateTime(now.year, now.month, now.day);
            final people = <Person>[];
            final home = <HomeEntry>[];
            final doses = <String, MedicationDose>{};
            for (final row in rows) {
              if (row.deletedAt != null) continue;
              try {
                final data = Map<String, Object?>.from(
                  jsonDecode(row.payloadJson) as Map,
                );
                if (data['archived'] == true) continue;
                if (row.entityType == 'medication_dose') {
                  final dose = MedicationDose.fromJson(data);
                  doses[dose.id] = dose;
                }
                if (row.entityType == 'person') {
                  people.add(Person.fromJson(data));
                }
                if (row.entityType == 'home_entry') {
                  home.add(HomeEntry.fromJson(data));
                }
              } catch (_) {
                /* Isolate malformed records. */
              }
            }
            for (final entry in withPeopleBirthdays(home, people)) {
              for (
                var i = entry.recurring ? -365 : 0;
                i < (entry.recurring ? 366 : 1);
                i++
              ) {
                final date = entry.recurring
                    ? DateTime(day.year, day.month, day.day + i)
                    : entry.dateTime;
                if (entry.recurring && !entry.occursOn(date)) continue;
                result.add(
                  AgendaItem(
                    'home:${entry.id}:${date.year}-${date.month}-${date.day}',
                    entry.title,
                    DateTime(
                      date.year,
                      date.month,
                      date.day,
                      entry.dateTime.hour,
                      entry.dateTime.minute,
                    ),
                    '/module/${entry.type.name}',
                    entry.reminder,
                    done: entry.completedOn(date),
                    type:
                        entry.type == HomeEntryType.affair &&
                            entry.subtype == 'call'
                        ? 'call'
                        : entry.type.name,
                    entityId: entry.id,
                    entityType: 'home_entry',
                  ),
                );
              }
            }
            for (final row in rows) {
              if (row.deletedAt != null) {
                continue;
              }
              try {
                final data = Map<String, Object?>.from(
                  jsonDecode(row.payloadJson) as Map,
                );
                if (data['archived'] == true) {
                  continue;
                }
                if (row.entityType == 'cycle_log') {
                  cycles.add(CycleLog.fromJson(data));
                  continue;
                }
                if (row.entityType == 'home_entry' ||
                    row.entityType == 'person') {
                  continue;
                }
                if (row.entityType == 'entertainment') {
                  final at = DateTime.tryParse(
                    data['plannedAt']?.toString() ?? '',
                  );
                  if (at != null) {
                    result.add(
                      AgendaItem(
                        'entertainment:${row.id}',
                        data['title']?.toString() ?? '',
                        at.toLocal(),
                        '/entertainment',
                        ReminderPlan(enabled: data['remind'] == true),
                        done: data['status'] == 'done',
                        type: 'entertainment',
                      ),
                    );
                  }
                  continue;
                }
                if (row.entityType == 'medication_plan') {
                  final medicine = MedicationPlan.fromJson(data);
                  if (!medicine.active ||
                      medicine.courseType == MedicationCourseType.asNeeded) {
                    continue;
                  }
                  for (final dose in doses.values.where(
                    (d) =>
                        d.planId == medicine.id &&
                        d.outcome == DoseOutcome.postponed &&
                        d.remindAt != null,
                  )) {
                    result.add(
                      AgendaItem(
                        'dose-snooze:${dose.id}',
                        medicine.name,
                        dose.remindAt!.toLocal(),
                        '/medication',
                        ReminderPlan(
                          enabled: true,
                          kind: medicine.reminder.kind,
                        ),
                        type: 'medication',
                      ),
                    );
                  }
                  final next = medicine.nextDoseDateTime(
                    now.subtract(const Duration(days: 1)),
                  );
                  for (var i = 0; i < 31; i++) {
                    final date = DateTime(
                      next.year,
                      next.month,
                      next.day + i,
                      next.hour,
                      next.minute,
                    );
                    if (medicine.isCourseFinished(date)) {
                      break;
                    }
                    result.add(
                      AgendaItem(
                        'medication:${row.id}:${date.year}-${date.month}-${date.day}',
                        medicine.name,
                        date,
                        '/medication',
                        medicine.reminder,
                        done: doses.containsKey(
                          MedicationDose.occurrenceId(medicine.id, date),
                        ),
                        type: 'medication',
                      ),
                    );
                  }
                } else {
                  final field = switch (row.entityType) {
                    'shopping_list' => 'scheduledAt',
                    'finance_transaction' => 'dueDate',
                    'rich_note' => 'scheduledAt',
                    'project' => 'dueDate',
                    _ => '',
                  };
                  final at = DateTime.tryParse(data[field]?.toString() ?? '');
                  if (at == null ||
                      data['paid'] == true ||
                      data['completed'] == true) {
                    continue;
                  }
                  final route = switch (row.entityType) {
                    'shopping_list' => '/shopping/${row.id}',
                    'finance_transaction' => '/finance',
                    'rich_note' => '/notes',
                    _ => '/projects/${row.id}',
                  };
                  result.add(
                    AgendaItem(
                      '${row.entityType}:${row.id}',
                      (data['title'] ??
                              data['note'] ??
                              data['billType'] ??
                              row.entityType)
                          .toString(),
                      at,
                      route,
                      ReminderPlan.fromJson(
                        data['reminder'] is Map
                            ? Map<String, Object?>.from(data['reminder'] as Map)
                            : null,
                      ),
                      type: row.entityType,
                    ),
                  );
                }
              } catch (_) {
                /* Other valid records remain visible if one record needs repair. */
              }
            }
            cycles.sort((a, b) => a.startDate.compareTo(b.startDate));
            if (cycles.isNotEmpty) {
              final forecast = CycleForecast.fromLogs(cycles)!;
              final last = cycles.last, predicted = forecast.start;
              if (last.conflictReminders) {
                final conflicts = result
                    .where(
                      (e) =>
                          !e.done &&
                          e.type != 'birthday' &&
                          e.type != 'medication' &&
                          forecast.overlaps(e.at),
                    )
                    .toList();
                for (final event in conflicts) {
                  result.add(
                    AgendaItem(
                      'cycle-conflict:${event.key}',
                      'مدیریت زندگی رها',
                      event.at,
                      '/cycle',
                      const ReminderPlan(enabled: true, minutesBefore: 1440),
                      type: 'cycle_conflict',
                    ),
                  );
                }
              }
              final parts = last.predictionReminderTime.split(':');
              result.add(
                AgendaItem(
                  'cycle:${last.id}',
                  'Raha Life',
                  DateTime(
                    predicted.year,
                    predicted.month,
                    predicted.day,
                    int.tryParse(parts.first) ?? 9,
                    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                  ),
                  '/cycle',
                  last.predictionReminder,
                  type: 'cycle',
                ),
              );
            }
            result.sort((a, b) => a.at.compareTo(b.at));
            return result;
          }),
);
