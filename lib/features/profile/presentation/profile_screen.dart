import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                CircleAvatar(radius: 42, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(user?.name.characters.first ?? '?', style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(height: 14),
                Text(user?.name ?? l10n.guestMode, style: Theme.of(context).textTheme.titleLarge),
                if (user != null) ...[const SizedBox(height: 6), Text(user.email)],
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: () => context.push('/account'), icon: Icon(user == null ? Icons.login_rounded : Icons.manage_accounts_rounded), label: Text(user == null ? l10n.createAccount : l10n.account)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.cloud_sync_rounded), title: Text(l10n.cloudBackup), subtitle: Text(l10n.syncNextVersion)),
              const Divider(),
              ListTile(leading: const Icon(Icons.shield_outlined), title: Text(l10n.privacy), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/coming-soon', extra: l10n.privacy)),
            ]),
          ),
        ],
      ),
    );
  }
}
