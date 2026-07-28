import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.guestMode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text('${l10n.syncStatus}: ${l10n.notConnected}'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/coming-soon',
                      extra: l10n.accountAndSync,
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(l10n.signIn),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded),
                  title: Text(l10n.cloudBackup),
                  subtitle: Text(l10n.comingSoon),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '/coming-soon',
                    extra: l10n.cloudBackup,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.privacy),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '/coming-soon',
                    extra: l10n.privacy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
