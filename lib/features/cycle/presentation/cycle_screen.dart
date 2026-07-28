import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/cycle_log.dart';
import 'cycle_controller.dart';

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logs = ref.watch(cycleProvider);
    final predicted = ref.read(cycleProvider.notifier).predictedNextStart;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cycle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [const Icon(Icons.lock_outline_rounded), const SizedBox(width: 10), Expanded(child: Text(l10n.cyclePrivacyTitle, style: Theme.of(context).textTheme.titleMedium))]),
                const SizedBox(height: 8),
                Text(l10n.cyclePrivacyText),
              ]),
            ),
          ),
          if (predicted != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_repeat_rounded),
                title: Text(l10n.estimatedNextCycle),
                subtitle: Text(compactDualDate(predicted, Localizations.localeOf(context))),
                trailing: Tooltip(message: l10n.estimateOnly, child: const Icon(Icons.info_outline_rounded)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (logs.isEmpty)
            Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(l10n.noCycleRecords)))
          else
            ...logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(localizeDigits(log.painLevel.toString(), Localizations.localeOf(context)))),
                      title: Text(compactDualDate(log.startDate, Localizations.localeOf(context))),
                      subtitle: Text('${_flowLabel(l10n, log.flow)} • ${_moodLabel(l10n, log.mood)}'),
                      trailing: IconButton(onPressed: () => ref.read(cycleProvider.notifier).delete(log.id), icon: const Icon(Icons.delete_outline_rounded)),
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(onPressed: () => _showCycleForm(context, ref), child: const Icon(Icons.add_rounded)),
    );
  }
}

String _flowLabel(AppLocalizations l10n, FlowIntensity flow) => switch (flow) {
  FlowIntensity.light => l10n.flowLight,
  FlowIntensity.medium => l10n.flowMedium,
  FlowIntensity.heavy => l10n.flowHeavy,
};
String _moodLabel(AppLocalizations l10n, CycleMood mood) => switch (mood) {
  CycleMood.calm => l10n.moodCalm,
  CycleMood.sensitive => l10n.moodSensitive,
  CycleMood.low => l10n.moodLow,
  CycleMood.energetic => l10n.moodEnergetic,
  CycleMood.irritable => l10n.moodIrritable,
  CycleMood.other => l10n.other,
};

Future<void> _showCycleForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  var start = DateTime.now();
  DateTime? end;
  var flow = FlowIntensity.medium;
  var pain = 0.0;
  var mood = CycleMood.calm;
  final notes = TextEditingController();
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (sheetContext) => StatefulBuilder(builder: (context, setState) => Padding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.addCycleRecord, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () async { final value = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2120), initialDate: start); if (value != null) setState(() => start = value); }, icon: const Icon(Icons.play_arrow_rounded), label: Text('${l10n.startDate}: ${compactDualDate(start, Localizations.localeOf(context))}')), const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { final value = await showDatePicker(context: context, firstDate: start, lastDate: DateTime(2120), initialDate: end ?? start); if (value != null) setState(() => end = value); }, icon: const Icon(Icons.stop_rounded), label: Text(end == null ? l10n.endDateOptional : '${l10n.endDate}: ${compactDualDate(end!, Localizations.localeOf(context))}')), const SizedBox(height: 10),
      DropdownButtonFormField<FlowIntensity>(initialValue: flow, decoration: InputDecoration(labelText: l10n.flowIntensity), items: FlowIntensity.values.map((value) => DropdownMenuItem(value: value, child: Text(_flowLabel(l10n, value)))).toList(), onChanged: (value) { if (value != null) setState(() => flow = value); }), const SizedBox(height: 12),
      Text('${l10n.painLevel}: ${localizeDigits(pain.round().toString(), Localizations.localeOf(context))}'), Slider(value: pain, max: 10, divisions: 10, onChanged: (value) => setState(() => pain = value)),
      DropdownButtonFormField<CycleMood>(initialValue: mood, decoration: InputDecoration(labelText: l10n.mood), items: CycleMood.values.map((value) => DropdownMenuItem(value: value, child: Text(_moodLabel(l10n, value)))).toList(), onChanged: (value) { if (value != null) setState(() => mood = value); }), const SizedBox(height: 10),
      TextField(controller: notes, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l10n.notes)), const SizedBox(height: 18),
      FilledButton(onPressed: () { ref.read(cycleProvider.notifier).add(startDate: start, endDate: end, flow: flow, painLevel: pain.round(), mood: mood, notes: notes.text); Navigator.pop(sheetContext); }, child: Text(l10n.save)),
    ])),
  )));
  notes.dispose();
}
