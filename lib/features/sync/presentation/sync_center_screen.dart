import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/sync_settings.dart';
import 'sync_controller.dart';

class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(syncSettingsProvider);
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncCenter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.syncProvider, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CloudSyncProvider>(
                    initialValue: state.provider,
                    items: CloudSyncProvider.values
                        .map(
                          (provider) => DropdownMenuItem(
                            value: provider,
                            child: Text(_providerLabel(l10n, provider)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(syncSettingsProvider.notifier).setProvider(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<SyncMode>(
                    segments: [
                      ButtonSegment(value: SyncMode.allDevices, label: Text(l10n.syncAllDevices), icon: const Icon(Icons.devices_rounded)),
                      ButtonSegment(value: SyncMode.backupOnly, label: Text(l10n.backupOnly), icon: const Icon(Icons.cloud_upload_outlined)),
                    ],
                    selected: {state.mode},
                    onSelectionChanged: (values) => ref.read(syncSettingsProvider.notifier).setMode(values.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.devices, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.devices_rounded)),
                    title: Text('${l10n.thisDevice} • ${_platformLabel(l10n)}'),
                    subtitle: Text(state.deviceId.isEmpty ? '…' : state.deviceId.substring(0, 8)),
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PlatformChip(label: l10n.androidPlatform),
                      _PlatformChip(label: l10n.iosPlatform),
                      _PlatformChip(label: l10n.windowsPlatform),
                      _PlatformChip(label: l10n.macosPlatform),
                      _PlatformChip(label: l10n.linuxPlatform),
                      _PlatformChip(label: l10n.webPlatform),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sync_rounded),
                    title: Text(l10n.lastSync),
                    subtitle: Text(
                      state.lastSyncAt == null
                          ? l10n.neverSynced
                          : '${compactDualDate(state.lastSyncAt!.toLocal(), locale)} • ${localizedTime(state.lastSyncAt!.toLocal(), locale)}',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: _CountTile(label: l10n.pendingChanges, value: state.pendingChanges)),
                      const SizedBox(width: 8),
                      Expanded(child: _CountTile(label: l10n.conflicts, value: state.conflicts)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(syncSettingsProvider.notifier).markLocalCheckpoint();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.localCheckpointSaved)));
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(l10n.saveSyncCheckpoint),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.info_outline_rounded,
            title: l10n.syncStatus,
            body: l10n.syncPrototypeNote,
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.cloud_done_outlined,
            title: l10n.rahaCloud,
            body: l10n.syncNeedsServer,
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.cloud_outlined,
            title: '${l10n.googleDrive} • ${l10n.dropbox} • ${l10n.oneDrive}',
            body: l10n.personalCloudHint,
          ),
        ],
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizeDigits(value.toString(), Localizations.localeOf(context)),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon),
          title: Text(title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(body),
          ),
        ),
      );
}

String _providerLabel(AppLocalizations l10n, CloudSyncProvider provider) => switch (provider) {
      CloudSyncProvider.rahaCloud => l10n.rahaCloud,
      CloudSyncProvider.googleDrive => l10n.googleDrive,
      CloudSyncProvider.dropbox => l10n.dropbox,
      CloudSyncProvider.oneDrive => l10n.oneDrive,
      CloudSyncProvider.localBackup => l10n.localBackup,
    };

String _platformLabel(AppLocalizations l10n) {
  if (kIsWeb) return l10n.webPlatform;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => l10n.androidPlatform,
    TargetPlatform.iOS => l10n.iosPlatform,
    TargetPlatform.windows => l10n.windowsPlatform,
    TargetPlatform.macOS => l10n.macosPlatform,
    TargetPlatform.linux => l10n.linuxPlatform,
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}
