import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../people/presentation/people_controller.dart';
import 'messages_controller.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(authProvider).user;
    final people = ref.watch(peopleProvider);
    final messages = ref.watch(messagesProvider);
    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.messagesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 64),
                const SizedBox(height: 14),
                Text(l10n.createAccount, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l10n.messageOfflineHint, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/account'),
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text(l10n.account),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      body: people.isEmpty
          ? Center(child: Text(l10n.noPeople))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final person = people[index];
                final thread = messages.where((item) => item.personId == person.id).toList();
                final last = thread.isEmpty ? null : thread.last;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(person.name.characters.first)),
                    title: Text(person.name),
                    subtitle: Text(
                      last == null || last.body.isEmpty ? l10n.newConversation : last.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: last != null && last.syncStatus.name == 'pending'
                        ? const Icon(Icons.cloud_upload_outlined, size: 18)
                        : null,
                    onTap: () => context.push('/messages/${person.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: people.isEmpty
          ? null
          : FloatingActionButton.small(
              onPressed: () => _choosePerson(context, people.map((e) => MapEntry(e.id, e.name)).toList()),
              child: const Icon(Icons.add_comment_rounded),
            ),
    );
  }

  Future<void> _choosePerson(BuildContext context, List<MapEntry<String, String>> people) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.selectPersonToMessage, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final person in people)
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(person.value),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/messages/${person.key}');
              },
            ),
        ],
      ),
    );
  }
}
