import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../people/presentation/people_controller.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../projects/presentation/projects_controller.dart';
import '../../shopping/presentation/shopping_controller.dart';
import 'messages_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.personId});
  final String personId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    String personName = l10n.people;
    for (final person in people) {
      if (person.id == widget.personId) personName = person.name;
    }
    final messages = ref.watch(messagesProvider).where((item) => item.personId == widget.personId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(personName)),
      body: Column(
        children: [
          MaterialBanner(
            content: Text(l10n.messageOfflineHint),
            leading: const Icon(Icons.cloud_sync_outlined),
            actions: const [SizedBox.shrink()],
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text(l10n.noMessages))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final message = messages[index];
                      return Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.body.isNotEmpty) Text(message.body),
                              if (message.sharedEntityId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Chip(
                                    avatar: const Icon(Icons.ios_share_rounded, size: 16),
                                    label: Text('${message.sharedEntityType}: ${message.sharedEntityId}'),
                                  ),
                                ),
                              if (message.attachmentName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Chip(
                                    avatar: const Icon(Icons.attach_file_rounded, size: 16),
                                    label: Text(message.attachmentName!),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${localizedTime(message.createdAt.toLocal(), Localizations.localeOf(context))} • ${l10n.pendingSync}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.shareItemInMessage,
                    onPressed: _shareAppItem,
                    icon: const Icon(Icons.add_link_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.addAttachment,
                    onPressed: _attach,
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: l10n.typeMessage),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.send,
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _shareAppItem() async {
    final l10n = AppLocalizations.of(context);
    final projects = ref.read(projectsProvider);
    final notes = ref.read(notesProvider).where((item) => !item.archived).toList();
    final shopping = ref.read(shoppingProvider);
    final options = <({String type, String id, String title, IconData icon})>[
      for (final project in projects)
        (type: 'project', id: project.id, title: project.title, icon: Icons.workspaces_rounded),
      for (final note in notes)
        (type: 'note', id: note.id, title: note.title.isEmpty ? l10n.notes : note.title, icon: Icons.edit_note_rounded),
      for (final list in shopping)
        (type: 'shopping', id: list.id, title: list.title, icon: Icons.shopping_basket_rounded),
    ];
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noItems)),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.shareItemInMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final option in options)
            ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              onTap: () {
                ref.read(messagesProvider.notifier).send(
                      personId: widget.personId,
                      body: option.title,
                      entityType: option.type,
                      entityId: option.id,
                    );
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _attach() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    ref.read(messagesProvider.notifier).send(
          personId: widget.personId,
          body: _controller.text,
          attachmentName: file.name,
          attachmentPath: file.path,
        );
    _controller.clear();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(messagesProvider.notifier).send(personId: widget.personId, body: text);
    _controller.clear();
  }
}
