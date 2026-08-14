import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/projects_controller.dart';
import 'notes_controller.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(notesProvider).where((item) => !item.archived).toList();
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalNotes)),
      body: notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.noNotes),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/notes/edit'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.newNote),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = notes[index];
                final project = note.projectId == null
                    ? null
                    : _projectById(projects, note.projectId!);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      note.pinned ? Icons.push_pin_rounded : Icons.notes_rounded,
                    ),
                    title: Text(
                      note.title.isEmpty ? l10n.notes : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          note.plainText.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project != null) ...[
                          const SizedBox(height: 7),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.workspaces_rounded, size: 16),
                            label: Text(project.title),
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'pin') {
                          ref.read(notesProvider.notifier).togglePinned(note.id);
                        } else if (value == 'archive') {
                          ref.read(notesProvider.notifier).archive(note.id);
                        } else if (value == 'delete') {
                          ref.read(notesProvider.notifier).delete(note.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(note.pinned ? l10n.unpinNote : l10n.pinNote),
                        ),
                        PopupMenuItem(value: 'archive', child: Text(l10n.archiveNote)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                    onTap: () => context.push('/notes/edit', extra: note.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/notes/edit'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}


ProjectData? _projectById(Iterable<ProjectData> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}
