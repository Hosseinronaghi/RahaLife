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
  String _tags = '';
  String? _savedId;
  bool _invalidDocument = false;
  bool _saving = false;
  bool _waitingForNote = false;
  String? _loadedSnapshot;
  String? _projectId;
  String? _personId;

  @override
  void initState() {
    super.initState();
    _savedId = widget.noteId;
    final note = widget.noteId == null
        ? null
        : _noteById(ref.read(notesProvider), widget.noteId!);
    _titleController = TextEditingController();
    _controller = QuillController.basic();
    _waitingForNote = widget.noteId != null && note == null;
    _loadEditor(note);
    ref.listenManual(notesProvider, (_, notes) {
      if (!_waitingForNote) return;
      final loaded = _noteById(notes, widget.noteId!);
      if (loaded == null) return;
      setState(() {
        _loadEditor(loaded);
        _waitingForNote = false;
      });
    });
  }

  void _loadEditor(RichNote? note) {
    _titleController.text = note?.title ?? '';
    _tags = (note?.tags ?? const <String>[]).join(', ');
    _projectId = note?.projectId ?? widget.initialProjectId;
    _personId = note?.personId;
    _invalidDocument = false;
    if (note == null) return;
    _loadedSnapshot = jsonEncode(note.toJson());
    try {
      final delta = jsonDecode(note.deltaJson) as List<dynamic>;
      final controller = QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller.dispose();
      _controller = controller;
    } catch (_) {
      _invalidDocument = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (_waitingForNote || _invalidDocument || _saving) return false;
    final id = _savedId;
    if (id != null) {
      final current = _noteById(ref.read(notesProvider), id);
      if (current == null) {
        _showMissingNote();
        return false;
      }
      if (jsonEncode(current.toJson()) != _loadedSnapshot) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'fa'
                  ? 'یادداشت جای دیگری تغییر کرده است. متن این پنجره را کپی کنید و یادداشت را دوباره باز کنید.'
                  : 'The note changed elsewhere. Copy your draft and reopen the note before saving.',
            ),
          ),
        );
        return false;
      }
    }
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final saved = ref
          .read(notesProvider.notifier)
          .save(
            id: _savedId,
            title: _titleController.text,
            deltaJson: jsonEncode(_controller.document.toDelta().toJson()),
            plainText: _controller.document.toPlainText(),
            tags: _tags
                .split(RegExp('[,،]'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false),
            projectId: _projectId,
            personId: _personId,
          );
      setState(() {
        _savedId = saved.id;
        _loadedSnapshot = jsonEncode(saved.toJson());
      });
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

  String get _missingNoteMessage =>
      Localizations.localeOf(context).languageCode == 'fa'
      ? 'یادداشت هنوز بارگذاری نشده یا دیگر در دسترس نیست.'
      : 'The note is still loading or is no longer available.';

  void _showMissingNote() => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(_missingNoteMessage)));

  Future<void> _editDetails() async {
    final l10n = AppLocalizations.of(context);
    final projects = ref.read(projectsProvider);
    final people = ref.read(peopleProvider);
    final details = await showDialog<
      ({String? project, String? person, String tags})
    >(
      context: context,
      builder: (context) {
        var project = _projectId;
        var person = _personId;
        var tags = _tags;
        return AlertDialog(
          scrollable: true,
          title: Text(l10n.details),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: projects.any((p) => p.id == project)
                      ? project
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.noteProject),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.none)),
                    for (final item in projects)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.title, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => project = value,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: people.any((p) => p.id == person)
                      ? person
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.people),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.none)),
                    for (final item in people)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => person = value,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: tags,
                  onChanged: (value) => tags = value,
                  decoration: InputDecoration(
                    labelText: l10n.noteTags,
                    prefixIcon: const Icon(Icons.sell_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                (project: project, person: person, tags: tags),
              ),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if (!mounted || details == null) return;
    setState(() {
      _projectId = details.project;
      _personId = details.person;
      _tags = details.tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_waitingForNote) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editNote)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_missingNoteMessage, textAlign: TextAlign.center),
          ),
        ),
      );
    }
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
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: Theme.of(context).textTheme.titleLarge,
                      minLines: 1,
                      maxLines: 2,
                      decoration: InputDecoration(hintText: l10n.noteTitle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.details,
                    onPressed: _editDetails,
                    icon: const Icon(Icons.tune_rounded),
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
