import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../people/presentation/people_controller.dart';
import 'projects_controller.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projects)),
      body: projects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspaces_outline,
                      size: 74,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.noProjects),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showProjectForm(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addProject),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final project = projects[index];
                final progress = project.checklistProgress;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/projects/${project.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.workspaces_rounded,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    if (project.dueDate != null)
                                      Text(
                                        '${l10n.projectDue}: ${compactDualDate(project.dueDate!, Localizations.localeOf(context))}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    ref.read(projectsProvider.notifier).delete(project.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(value: progress),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${l10n.projectProgress}: ${localizeDigits((progress * 100).round().toString(), Localizations.localeOf(context))}٪',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showProjectForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

Future<void> showProjectForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  DateTime? startDate;
  DateTime? dueDate;
  final selectedPeople = <String>{};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final people = ref.watch(peopleProvider);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.addProject, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: title,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.projectName),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: l10n.projectDescription),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2120),
                              initialDate: startDate ?? DateTime.now(),
                            );
                            if (value != null) setState(() => startDate = value);
                          },
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(startDate == null
                              ? l10n.projectStart
                              : compactDualDate(startDate!, Localizations.localeOf(context))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await showDatePicker(
                              context: context,
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime(2120),
                              initialDate: dueDate ?? startDate ?? DateTime.now(),
                            );
                            if (value != null) setState(() => dueDate = value);
                          },
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(dueDate == null
                              ? l10n.projectDue
                              : compactDualDate(dueDate!, Localizations.localeOf(context))),
                        ),
                      ),
                    ],
                  ),
                  if (people.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(l10n.projectPeople, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final person in people)
                          FilterChip(
                            selected: selectedPeople.contains(person.id),
                            label: Text(person.name),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                selectedPeople.add(person.id);
                              } else {
                                selectedPeople.remove(person.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final project = ref.read(projectsProvider.notifier).add(
                            title: title.text,
                            description: description.text,
                            startDate: startDate,
                            dueDate: dueDate,
                            personIds: selectedPeople.toList(growable: false),
                          );
                      Navigator.pop(sheetContext);
                      context.push('/projects/${project.id}');
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  title.dispose();
  description.dispose();
}
