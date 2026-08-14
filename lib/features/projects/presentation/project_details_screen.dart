import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/sharing/system_share.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../finance/presentation/finance_controller.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../home/presentation/home_controller.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../people/presentation/people_controller.dart';
import '../../sharing/presentation/share_with_people_sheet.dart';
import '../domain/project.dart';
import 'projects_controller.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ProjectData? project;
    for (final item in ref.watch(projectsProvider)) {
      if (item.id == projectId) project = item;
    }
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.projects)),
        body: Center(child: Text(l10n.noProjects)),
      );
    }

    final value = project;
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(value.title),
          actions: [
            IconButton(
              tooltip: l10n.systemShare,
              onPressed: () => shareTextFromContext(
                context,
                subject: value.title,
                text: [
                  value.title,
                  if (value.description?.isNotEmpty ?? false) value.description!,
                  '${l10n.projectProgress}: ${localizeDigits((value.checklistProgress * 100).round().toString(), Localizations.localeOf(context))}٪',
                ].join('\n'),
              ),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              tooltip: l10n.shareWithPeople,
              onPressed: () => showShareWithPeopleSheet(
                context,
                ref,
                entityType: 'project',
                entityId: value.id,
              ),
              icon: const Icon(Icons.group_add_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.projectOverview),
              Tab(text: l10n.projectAffairs),
              Tab(text: l10n.projectNotes),
              Tab(text: l10n.projectChecklist),
              Tab(text: l10n.projectFiles),
              Tab(text: l10n.projectPeople),
              Tab(text: l10n.projectFinance),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Overview(project: value),
            _Affairs(project: value),
            _Notes(project: value),
            _Checklist(project: value),
            _Files(project: value),
            _People(project: value),
            _Finance(project: value),
          ],
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final progress = project.checklistProgress;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F766E).withValues(alpha: 0.16),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.title, style: Theme.of(context).textTheme.headlineSmall),
              if (project.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(project.description!),
              ],
              const SizedBox(height: 18),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                '${l10n.projectProgress}: ${localizeDigits((progress * 100).round().toString(), locale)}٪',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                if (project.startDate != null)
                  _Meta(icon: Icons.flag_outlined, label: l10n.projectStart, value: compactDualDate(project.startDate!, locale)),
                if (project.dueDate != null)
                  _Meta(icon: Icons.event_available_outlined, label: l10n.projectDue, value: compactDualDate(project.dueDate!, locale)),
                _Meta(icon: Icons.checklist_rounded, label: l10n.projectChecklist, value: localizeDigits(project.checklist.length.toString(), locale)),
                _Meta(icon: Icons.attach_file_rounded, label: l10n.projectFiles, value: localizeDigits(project.attachments.length.toString(), locale)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text('$label: $value'),
        ],
      );
}

class _Affairs extends ConsumerWidget {
  const _Affairs({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(homeEntriesProvider).where((item) => item.projectId == project.id).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => context.push('/module/affair', extra: project.id),
            icon: const Icon(Icons.add_task_rounded),
            label: Text(l10n.addTask),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text(l10n.noItems))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: Icon(entries[index].completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                    title: Text(entries[index].title),
                    subtitle: Text(compactDualDate(entries[index].dateTime, Localizations.localeOf(context))),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Notes extends ConsumerWidget {
  const _Notes({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(notesProvider).where((item) => item.projectId == project.id && !item.archived).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => context.push('/notes/edit', extra: {'projectId': project.id}),
            icon: const Icon(Icons.note_add_rounded),
            label: Text(l10n.newNote),
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? Center(child: Text(l10n.noNotes))
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.notes_rounded),
                    title: Text(notes[index].title),
                    subtitle: Text(notes[index].plainText, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => context.push('/notes/edit', extra: notes[index].id),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Checklist extends ConsumerWidget {
  const _Checklist({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: l10n.addChecklistItem),
                onSubmitted: (value) {
                  ref.read(projectsProvider.notifier).addChecklist(project.id, value);
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {
                ref.read(projectsProvider.notifier).addChecklist(project.id, controller.text);
                controller.clear();
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in project.checklist)
          CheckboxListTile(
            value: item.done,
            title: Text(item.title),
            onChanged: (_) => ref.read(projectsProvider.notifier).toggleChecklist(project.id, item.id),
          ),
      ],
    );
  }
}

class _Files extends ConsumerWidget {
  const _Files({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final file = await FilePicker.pickFile();
            if (file == null) return;
            final fileSize = await file.length();
            ref.read(projectsProvider.notifier).addAttachment(
                  project.id,
                  ProjectAttachment(
                    id: const Uuid().v4(),
                    name: file.name,
                    size: fileSize,
                    path: file.path,
                  ),
                );
          },
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(l10n.addAttachment),
        ),
        const SizedBox(height: 12),
        for (final attachment in project.attachments)
          ListTile(
            leading: const Icon(Icons.insert_drive_file_rounded),
            title: Text(attachment.name),
            subtitle: Text('${localizeDigits((attachment.size / 1024).ceil().toString(), Localizations.localeOf(context))} ${l10n.kilobytes}'),
            trailing: IconButton(
              tooltip: l10n.removeAttachment,
              onPressed: () => ref.read(projectsProvider.notifier).removeAttachment(project.id, attachment.id),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
      ],
    );
  }
}

class _People extends ConsumerWidget {
  const _People({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).where((item) => project.personIds.contains(item.id)).toList();
    final l10n = AppLocalizations.of(context);
    return people.isEmpty
        ? Center(child: Text(l10n.noPeople))
        : ListView.builder(
            itemCount: people.length,
            itemBuilder: (_, index) => ListTile(
              leading: CircleAvatar(child: Text(people[index].name.characters.first)),
              title: Text(people[index].name),
              subtitle: Text(people[index].relationship ?? ''),
            ),
          );
  }
}

class _Finance extends ConsumerWidget {
  const _Finance({required this.project});
  final ProjectData project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final transactions = ref.watch(financeProvider).transactions.where((item) => item.projectId == project.id).toList();
    final total = transactions.fold<double>(0, (sum, item) => sum + item.amount);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: () => showFinanceForm(context, ref, projectId: project.id),
            icon: const Icon(Icons.add_card_rounded),
            label: Text(l10n.addFinance),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: Text(l10n.projectFinance),
            subtitle: Text(localizeDigits(total.toStringAsFixed(0), Localizations.localeOf(context))),
          ),
        ),
        for (final item in transactions)
          ListTile(
            title: Text(item.note?.isNotEmpty ?? false ? item.note! : item.type.name),
            trailing: Text(localizeDigits(item.amount.toStringAsFixed(0), Localizations.localeOf(context))),
          ),
      ],
    );
  }
}
