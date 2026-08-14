import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../people/presentation/people_controller.dart';
import '../domain/share_models.dart';
import 'sharing_controller.dart';

Future<void> showShareWithPeopleSheet(
  BuildContext context,
  WidgetRef ref, {
  required String entityType,
  required String entityId,
  SharePermission defaultPermission = SharePermission.view,
}) async {
  final l10n = AppLocalizations.of(context);
  final people = ref.read(peopleProvider);
  if (people.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noPeople)),
    );
    return;
  }

  final existing = ref
      .read(sharingProvider)
      .where(
        (item) => item.entityType == entityType && item.entityId == entityId,
      )
      .toList();
  final selected = existing.map((item) => item.personId).toSet();
  var permission = existing.isEmpty ? defaultPermission : existing.first.permission;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.shareWithPeople,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SharePermission>(
                initialValue: permission,
                decoration: InputDecoration(labelText: l10n.sharePermission),
                items: SharePermission.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_permissionLabel(l10n, value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => permission = value);
                },
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final person in people)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(person.id),
                        title: Text(person.name),
                        subtitle: person.relationship?.isNotEmpty ?? false
                            ? Text(person.relationship!)
                            : null,
                        onChanged: (value) => setState(() {
                          if (value ?? false) {
                            selected.add(person.id);
                          } else {
                            selected.remove(person.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  ref.read(sharingProvider.notifier).share(
                        entityType: entityType,
                        entityId: entityId,
                        personIds: selected,
                        permission: permission,
                      );
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareQueued)),
                  );
                },
                icon: const Icon(Icons.group_add_rounded),
                label: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _permissionLabel(
  AppLocalizations l10n,
  SharePermission permission,
) =>
    switch (permission) {
      SharePermission.view => l10n.viewOnly,
      SharePermission.check => l10n.canCheckItems,
      SharePermission.edit => l10n.canEdit,
    };
