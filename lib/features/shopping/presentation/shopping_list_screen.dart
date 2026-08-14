import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/entry_details_sheet.dart';
import '../../home/presentation/home_controller.dart';
import '../../people/presentation/people_controller.dart';
import '../../sharing/domain/share_models.dart';
import '../../sharing/presentation/sharing_controller.dart';
import '../domain/shopping_list.dart';
import 'shopping_controller.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({required this.listId, super.key});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(shoppingProvider);
    final matches = lists.where((item) => item.id == listId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noSearchResults)),
      );
    }
    final list = matches.first;
    final sorted = [...list.items]
      ..sort((a, b) => a.checked == b.checked ? 0 : (a.checked ? 1 : -1));
    final entries = ref.watch(homeEntriesProvider);
    final related = list.linkedAffairId == null
        ? null
        : entries.where((item) => item.id == list.linkedAffairId).firstOrNull;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          IconButton(
            tooltip: l10n.shareWithPeople,
            onPressed: () => _shareWithPeople(context, ref, list.id),
            icon: const Icon(Icons.group_add_rounded),
          ),
          IconButton(
            tooltip: l10n.systemShare,
            onPressed: () async {
              final text = _shareText(list.title, sorted);
              final box = context.findRenderObject() as RenderBox?;
              final origin = box == null
                  ? const Rect.fromLTWH(0, 0, 1, 1)
                  : box.localToGlobal(Offset.zero) & box.size;
              try {
                await SharePlus.instance.share(
                  ShareParams(
                    text: text,
                    subject: list.title,
                    sharePositionOrigin: origin,
                  ),
                );
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedForSharing)),
                  );
                }
              }
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                ref.read(shoppingProvider.notifier).deleteList(list.id);
                Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (list.scheduledAt != null ||
              (list.location?.isNotEmpty ?? false) ||
              related != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (list.scheduledAt != null)
                      _InfoLine(
                        icon: Icons.event_rounded,
                        label: l10n.purchaseDate,
                        value:
                            '${compactDualDate(list.scheduledAt!, locale)} · ${localizedTime(list.scheduledAt!, locale)}',
                      ),
                    if (list.location?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      _InfoLine(
                        icon: Icons.location_on_outlined,
                        label: l10n.location,
                        value: list.location!,
                      ),
                    ],
                    if (related != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => showEntryDetails(context, related),
                        icon: const Icon(Icons.link_rounded),
                        label: Text(l10n.openLinkedAffair),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (list.scheduledAt != null ||
              (list.location?.isNotEmpty ?? false) ||
              related != null)
            const SizedBox(height: 12),
          _SharedAccessCard(listId: list.id),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text(l10n.noShoppingItems)),
            )
          else
            ...sorted.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: CheckboxListTile(
                    value: item.checked,
                    onChanged: (_) => ref
                        .read(shoppingProvider.notifier)
                        .toggleItem(list.id, item.id),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        decoration:
                            item.checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    secondary: Icon(
                      item.checked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _addItems(context, ref, list.id),
        child: const Icon(Icons.playlist_add_rounded),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$label: $value'),
          ),
        ],
      );
}

String _shareText(String title, List<ShoppingItemData> items) {
  final buffer = StringBuffer('$title\n');
  for (final item in items) {
    buffer.writeln('${item.checked ? '☑' : '☐'} ${item.title}');
  }
  return buffer.toString();
}

Future<void> _addItems(
  BuildContext context,
  WidgetRef ref,
  String listId,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addShoppingItems,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(hintText: l10n.oneItemPerLine),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(shoppingProvider.notifier)
                  .addItems(listId, controller.text.split('\n'));
              Navigator.pop(sheetContext);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}


class _SharedAccessCard extends ConsumerWidget {
  const _SharedAccessCard({required this.listId});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grants = ref
        .watch(sharingProvider)
        .where((item) => item.entityType == 'shopping' && item.entityId == listId)
        .toList();
    if (grants.isEmpty) return const SizedBox.shrink();
    final people = ref.watch(peopleProvider);
    String personName(String id) {
      for (final person in people) {
        if (person.id == id) return person.name;
      }
      return l10n.people;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sharedShoppingAccess,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _shareWithPeople(context, ref, listId),
                  child: Text(l10n.edit),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grant in grants)
                  Chip(
                    avatar: const Icon(Icons.person_outline_rounded, size: 16),
                    label: Text(
                      '${personName(grant.personId)} · ${_permissionLabel(l10n, grant.permission)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _shareWithPeople(
  BuildContext context,
  WidgetRef ref,
  String listId,
) async {
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
      .where((item) => item.entityType == 'shopping' && item.entityId == listId)
      .toList();
  final selected = existing.map((item) => item.personId).toSet();
  var permission = existing.isEmpty
      ? SharePermission.check
      : existing.first.permission;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
                constraints: const BoxConstraints(maxHeight: 320),
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
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        ref.read(sharingProvider.notifier).share(
                              entityType: 'shopping',
                              entityId: listId,
                              personIds: selected,
                              permission: permission,
                            );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.shareQueued)),
                        );
                      },
                icon: const Icon(Icons.group_add_rounded),
                label: Text(l10n.share),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _permissionLabel(AppLocalizations l10n, SharePermission permission) =>
    switch (permission) {
      SharePermission.view => l10n.viewOnly,
      SharePermission.check => l10n.canCheckItems,
      SharePermission.edit => l10n.canEdit,
    };

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
