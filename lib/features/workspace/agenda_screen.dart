import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/agenda.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/localization/locale_formatters.dart';
import 'record_editor.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final values = ref.watch(agendaProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(c, 'موعدها و یادآورها', 'Agenda & reminders')),
      ),
      body: values.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(e.toString())),
        data: (all) {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final items = all
              .where((e) => !e.at.isBefore(start) && !e.done)
              .toList();
          return Column(
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: ReminderService.instance.lastError,
                builder: (c, error, _) => error == null
                    ? const SizedBox.shrink()
                    : MaterialBanner(
                        content: Text(error),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              final granted = await ReminderService.instance
                                  .requestPermissions();
                              if (granted) {
                                ReminderService.instance.lastError.value = null;
                                ref.invalidate(agendaProvider);
                              }
                            },
                            child: Text(
                              tr(c, 'بررسی مجوزها', 'Check permissions'),
                            ),
                          ),
                        ],
                      ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr(c, 'موعدی در انتظار نیست', 'No upcoming items'),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (c, i) {
                    final e = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          e.plan.enabled
                              ? Icons.notifications_active_outlined
                              : Icons.event_outlined,
                        ),
                        title: Text(e.title),
                        subtitle: Text(
                          '${compactDualDate(e.at, Localizations.localeOf(c))} · ${localizedTime(e.at, Localizations.localeOf(c))}',
                        ),
                        onTap: () => c.push(e.route),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
