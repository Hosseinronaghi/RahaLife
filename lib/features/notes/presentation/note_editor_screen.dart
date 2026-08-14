import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sharing/system_share.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../people/presentation/people_controller.dart';
import '../../projects/presentation/projects_controller.dart';
import '../../sharing/presentation/share_with_people_sheet.dart';
import '../domain/rich_note.dart';
import 'notes_controller.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId, this.initialProjectId});
  final String? noteId;
  final String? initialProjectId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late QuillController _controller;
  final _tagsController = TextEditingController();
  String? _projectId;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final note = widget.noteId == null
        ? null
        : _noteById(ref.read(notesProvider), widget.noteId!);
    _titleController = TextEditingController(text: note?.title ?? '');
    _tagsController.text = (note?.tags ?? const <String>[]).join(', ');
    _projectId = note?.projectId ?? widget.initialProjectId;
    _personId = note?.personId;
    try {
      final delta = note == null
          ? null
          : jsonDecode(note.deltaJson) as List<dynamic>;
      _controller = delta == null
          ? QuillController.basic()
          : QuillController(
              document: Document.fromJson(delta),
              selection: const TextSelection.collapsed(offset: 0),
            );
    } catch (_) {
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    ref.read(notesProvider.notifier).save(
          id: widget.noteId,
          title: _titleController.text,
          deltaJson: jsonEncode(_controller.document.toDelta().toJson()),
          plainText: _controller.document.toPlainText(),
          tags: _tagsController.text
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          projectId: _projectId,
          personId: _personId,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noteSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? l10n.newNote : l10n.editNote),
        actions: [
          IconButton(
            tooltip: l10n.systemShare,
            onPressed: () => shareTextFromContext(
              context,
              subject: _titleController.text,
              text: '${_titleController.text}\n\n${_controller.document.toPlainText()}'.trim(),
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          if (widget.noteId != null)
            IconButton(
              tooltip: l10n.shareWithPeople,
              onPressed: () => showShareWithPeopleSheet(
                context,
                ref,
                entityType: 'note',
                entityId: widget.noteId!,
              ),
              icon: const Icon(Icons.group_add_rounded),
            ),
          IconButton(
            onPressed: _save,
            tooltip: l10n.save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: l10n.noteTitle,
                      border: InputBorder.none,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _projectId,
                          decoration: InputDecoration(labelText: l10n.noteProject),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.none),
                            ),
                            ...projects.map(
                              (project) => DropdownMenuItem<String?>(
                                value: project.id,
                                child: Text(project.title),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _projectId = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _personId,
                          decoration: InputDecoration(labelText: l10n.people),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.none),
                            ),
                            ...people.map(
                              (person) => DropdownMenuItem<String?>(
                                value: person.id,
                                child: Text(person.name),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _personId = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: l10n.noteTags,
                      prefixIcon: const Icon(Icons.sell_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: QuillSimpleToolbar(
                controller: _controller,
                config: const QuillSimpleToolbarConfig(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QuillEditor.basic(
                  controller: _controller,
                  config: const QuillEditorConfig(
                    placeholder: '…',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


RichNote? _noteById(Iterable<RichNote> notes, String id) {
  for (final note in notes) {
    if (note.id == id) return note;
  }
  return null;
}
