import 'package:flutter/material.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../../../core/widgets/retained_popup.dart';
import '../../../core/localization/locale_formatters.dart';
import '../domain/medication_dose.dart';
import '../domain/medication_plan.dart';

String _text(BuildContext c, String fa, String en) =>
    Localizations.localeOf(c).languageCode == 'fa' ? fa : en;

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({required this.plan, super.key});
  final MedicationPlan plan;
  @override
  State<MedicationHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<MedicationHistoryScreen> {
  final repository = DriftEntityRepository();
  late Future<List<Map<String, Object?>>> rows;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    rows = repository.loadAll('medication_dose');
  }

  bool recording = false;
  Future<void> record() async {
    if (recording) return;
    setState(() => recording = true);
    try {
      await _record();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                context,
                'ثبت انجام نشد؛ دوباره تلاش کنید.',
                'Could not save. Please retry.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => recording = false);
    }
  }

  Future<void> _record() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final parts = widget.plan.time.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (time == null || !mounted) return;
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final id = MedicationDose.occurrenceId(widget.plan.id, scheduled);
    final existing = await repository.loadOne('medication_dose', id);
    if (!mounted) return;
    final reason = TextEditingController(
      text: existing?['reason']?.toString() ?? '',
    );
    final outcome = await showRetainedDialog<DoseOutcome>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_text(c, 'ثبت وضعیت نوبت', 'Record dose outcome')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _text(
                c,
                'بدون ثبت، وضعیت این نوبت نامشخص است.',
                'Without a record, this dose remains unknown.',
              ),
            ),
            TextField(
              controller: reason,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _text(c, 'توضیح اختیاری', 'Optional note'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, DoseOutcome.postponed),
            child: Text(_text(c, 'تعویق', 'Snooze')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(_text(c, 'انصراف', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, DoseOutcome.notTaken),
            child: Text(_text(c, 'مصرف نشد', 'Not taken')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, DoseOutcome.taken),
            child: Text(_text(c, 'مصرف شد', 'Taken')),
          ),
        ],
      ),
    );
    final note = reason.text.trim();
    reason.dispose();
    if (outcome == null || !mounted) return;
    DateTime? actual, remindAt;
    if (outcome == DoseOutcome.postponed) {
      final now = DateTime.now();
      final day = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 30)),
      );
      if (day == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          now.add(const Duration(minutes: 30)),
        ),
      );
      if (time == null || !mounted) return;
      remindAt = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      if (!remindAt.isAfter(DateTime.now())) {
        throw StateError('Choose a future time');
      }
    }
    if (outcome == DoseOutcome.taken) {
      final actualDate = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (actualDate == null || !mounted) return;
      final actualTime = await showTimePicker(
        context: context,
        initialTime: time,
      );
      if (actualTime == null || !mounted) return;
      actual = DateTime(
        actualDate.year,
        actualDate.month,
        actualDate.day,
        actualTime.hour,
        actualTime.minute,
      );
      if (actual.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                context,
                'زمان مصرف نمی‌تواند در آینده باشد.',
                'Taken time cannot be in the future.',
              ),
            ),
          ),
        );
        return;
      }
    }
    final dose = MedicationDose(
      id: id,
      planId: widget.plan.id,
      scheduledAt: scheduled,
      outcome: outcome,
      recordedAt: DateTime.now(),
      takenAt: actual,
      remindAt: remindAt,
      reason: note,
    );
    try {
      await repository.db.transaction(() async {
        if (existing == null) {
          if (await repository.loadOne('medication_dose', id) != null) {
            throw StateError('Dose changed');
          }
          await repository.upsert('medication_dose', dose.toJson());
        } else {
          await repository.updateFromSnapshot(
            'medication_dose',
            dose.toJson(),
            existing,
          );
        }
      });
      if (mounted) setState(refresh);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                context,
                'ثبت انجام نشد؛ دوباره تلاش کنید.',
                'Could not save. Please retry.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${_text(c, 'سابقه مصرف', 'Dose history')} · ${widget.plan.name}',
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: recording ? null : record,
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<Map<String, Object?>>>(
      future: rows,
      builder: (c, s) {
        if (s.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(refresh),
              child: Text(_text(c, 'تلاش دوباره', 'Retry')),
            ),
          );
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final doses =
            s.data!
                .where((r) => r['planId'] == widget.plan.id)
                .map(MedicationDose.fromJson)
                .toList()
              ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _text(
                c,
                'ثبت‌نشدن نوبت به معنی مصرف‌نکردن نیست. برای ثبت یا اصلاح، دکمه + و موعد همان نوبت را انتخاب کنید.',
                'An unrecorded dose is unknown, not missed. To record or correct a dose, choose + and its scheduled date and time.',
              ),
            ),
            for (final d in doses)
              Card(
                child: ListTile(
                  leading: Icon(
                    d.outcome == DoseOutcome.taken
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  title: Text(switch (d.outcome) {
                    DoseOutcome.taken => _text(c, 'مصرف شد', 'Taken'),
                    DoseOutcome.notTaken => _text(c, 'مصرف نشد', 'Not taken'),
                    DoseOutcome.postponed => _text(
                      c,
                      'به تعویق افتاد',
                      'Postponed',
                    ),
                  }),
                  subtitle: Text(
                    '${compactDualDate(d.scheduledAt.toLocal(), Localizations.localeOf(c))} · ${TimeOfDay.fromDateTime(d.scheduledAt.toLocal()).format(c)}\n${d.reason ?? ''}${d.takenAt == null ? '' : '\n${_text(c, 'زمان مصرف', 'Taken at')}: ${d.takenAt!.toLocal()}'}',
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
