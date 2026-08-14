import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/home_controller.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../projects/presentation/projects_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';
import 'inbox_controller.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inbox)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _CaptureBox(
              hint: l10n.captureHint,
              onAdd: (value) => ref.read(inboxProvider.notifier).add(value),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(l10n.noInbox))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.inbox_rounded),
                          title: Text(item.text),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _convert(context, ref, item.id, item.text, value),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'affair', child: Text('${l10n.convertTo}: ${l10n.tasks}')),
                              PopupMenuItem(value: 'appointment', child: Text('${l10n.convertTo}: ${l10n.appointments}')),
                              PopupMenuItem(value: 'note', child: Text('${l10n.convertTo}: ${l10n.notes}')),
                              PopupMenuItem(value: 'shopping', child: Text('${l10n.convertTo}: ${l10n.shopping}')),
                              PopupMenuItem(value: 'project', child: Text('${l10n.convertTo}: ${l10n.projects}')),
                              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _convert(BuildContext context, WidgetRef ref, String id, String text, String target) {
    if (target == 'delete') {
      ref.read(inboxProvider.notifier).remove(id);
      return;
    }
    if (target == 'affair' || target == 'appointment') {
      ref.read(homeEntriesProvider.notifier).add(
            type: target == 'affair' ? HomeEntryType.affair : HomeEntryType.appointment,
            title: text,
            dateTime: DateTime.now(),
          );
    } else if (target == 'note') {
      ref.read(notesProvider.notifier).save(
            title: text,
            deltaJson: jsonEncode([
              {'insert': '$text\n'}
            ]),
            plainText: text,
          );
    } else if (target == 'shopping') {
      ref.read(shoppingProvider.notifier).addList(text, [text]);
    } else if (target == 'project') {
      ref.read(projectsProvider.notifier).add(title: text);
    }
    ref.read(inboxProvider.notifier).remove(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).convertDone)));
  }
}

class _CaptureBox extends StatefulWidget {
  const _CaptureBox({required this.hint, required this.onAdd});
  final String hint;
  final ValueChanged<String> onAdd;

  @override
  State<_CaptureBox> createState() => _CaptureBoxState();
}

class _CaptureBoxState extends State<_CaptureBox> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.bolt_rounded),
          suffixIcon: IconButton(
            onPressed: () {
              widget.onAdd(controller.text);
              controller.clear();
            },
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ),
        onSubmitted: (value) {
          widget.onAdd(value);
          controller.clear();
        },
      );
}
