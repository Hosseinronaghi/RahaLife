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
  });
  final String key, title, route, type;
  final DateTime at;
  final ReminderPlan plan;
  final bool done;
}

final agendaProvider = StreamProvider<List<AgendaItem>>(
  (ref) =>
      (appDatabase.select(appDatabase.entityDocuments)..where(
            (r) => r.entityType.isIn([
              'home_entry',
              'medication_plan',
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
                if (row.entityType == 'home_entry') {
                  final entry = HomeEntry.fromJson(data);
                  void add(DateTime date) {
                    result.add(
                      AgendaItem(
                        'home:${row.id}:${date.year}-${date.month}-${date.day}',
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
                        type: entry.type.name,
                      ),
                    );
                  }

                  if (!entry.recurring) {
                    add(entry.dateTime);
                  } else {
                    for (var i = -365; i < 366; i++) {
                      final date = DateTime(day.year, day.month, day.day + i);
                      if (entry.occursOn(date)) {
                        add(date);
                      }
                    }
                  }
                } else if (row.entityType == 'medication_plan') {
                  final medicine = MedicationPlan.fromJson(data);
                  if (!medicine.active ||
                      medicine.courseType == MedicationCourseType.asNeeded) {
                    continue;
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
              var days = 28;
              if (cycles.length > 1) {
                var total = 0;
                for (var i = 1; i < cycles.length; i++) {
                  total += cycles[i].startDate
                      .difference(cycles[i - 1].startDate)
                      .inDays;
                }
                days = (total / (cycles.length - 1))
                    .round()
                    .clamp(21, 45)
                    .toInt();
              }
              final last = cycles.last,
                  predicted = last.startDate.add(Duration(days: days));
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
