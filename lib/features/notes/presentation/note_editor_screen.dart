import '../../files/files_screen.dart';
import '../../../core/persistence/write_status.dart';
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
  String? _savedId;
  bool _metadataOpen = false;
  bool _invalidDocument = false;
  bool _saving = false;
  String? _projectId;
  String? _personId;

  @override
  void initState() {
    super.initState();
    _savedId = widget.noteId;
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
      _invalidDocument = true;
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

  Future<bool> _save() async {
    if (_invalidDocument || _saving) return false;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final saved = ref
        .read(notesProvider.notifier)
        .save(
          id: _savedId,
          title: _titleController.text,
          deltaJson: jsonEncode(_controller.document.toDelta().toJson()),
          plainText: _controller.document.toPlainText(),
          tags: _tagsController.text
              .split(RegExp('[,،]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          projectId: _projectId,
          personId: _personId,
        );
    setState(() => _savedId = saved.id);
    try {
      await WriteStatus.flush();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noteSaved)));
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'fa'
                  ? 'ذخیره تأیید نشد؛ دوباره تلاش کنید.'
                  : 'Save was not confirmed. Please retry.',
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_savedId == null ? l10n.newNote : l10n.editNote),
        actions: [
          IconButton(
            tooltip: Localizations.localeOf(context).languageCode == 'fa'
                ? 'فایل و صدا'
                : 'Files and voice',
            icon: const Icon(Icons.attach_file),
            onPressed: _saving || _invalidDocument
                ? null
                : () async {
                    final saved = await _save();
                    if (!saved || !context.mounted || _savedId == null) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FilesScreen(
                          entityType: 'rich_note',
                          entityId: _savedId,
                        ),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: l10n.systemShare,
            onPressed: () => shareTextFromContext(
              context,
              subject: _titleController.text,
              text:
                  '${_titleController.text}\n\n${_controller.document.toPlainText()}'
                      .trim(),
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          if (_savedId != null)
            IconButton(
              tooltip: l10n.shareWithPeople,
              onPressed: () => showShareWithPeopleSheet(
                context,
                ref,
                entityType: 'note',
                entityId: _savedId!,
              ),
              icon: const Icon(Icons.group_add_rounded),
            ),
          IconButton(
            onPressed: _saving || _invalidDocument ? null : _save,
            tooltip: l10n.save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_invalidDocument)
              MaterialBanner(
                content: Text(
                  Localizations.localeOf(context).languageCode == 'fa'
                      ? 'متن یادداشت قابل خواندن نیست؛ برای حفظ اطلاعات، ذخیره غیرفعال شده است.'
                      : 'The note cannot be read. Saving is disabled to protect its content.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            Flexible(
              flex: _metadataOpen ? 2 : 1,
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(hintText: l10n.noteTitle),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _metadataOpen = !_metadataOpen),
                      icon: Icon(
                        _metadataOpen ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(
                        '${l10n.noteProject} · ${l10n.people} · ${l10n.noteTags}',
                      ),
                    ),
                    if (_metadataOpen) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: projects.any((p) => p.id == _projectId)
                            ? _projectId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.noteProject,
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.none)),
                          ...projects.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _projectId = v),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: people.any((p) => p.id == _personId)
                            ? _personId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l10n.people),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.none)),
                          ...people.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _personId = v),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: l10n.noteTags,
                          prefixIcon: const Icon(Icons.sell_outlined),
                        ),
                      ),
                    ],
                  ],
                ),
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
