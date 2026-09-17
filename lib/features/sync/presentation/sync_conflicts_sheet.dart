import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_conflict_repository.dart';
import 'sync_controller.dart';
import 'synced_feature_refresh.dart';

Future<void> showSyncConflictsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SyncConflictsSheet(parentRef: ref),
  );
}

class _SyncConflictsSheet extends StatefulWidget {
  const _SyncConflictsSheet({required this.parentRef});

  final WidgetRef parentRef;

  @override
  State<_SyncConflictsSheet> createState() => _SyncConflictsSheetState();
}

class _SyncConflictsSheetState extends State<_SyncConflictsSheet> {
  final _repository = SyncConflictRepository();
  String? _busyId;

  bool get _fa => Localizations.localeOf(context).languageCode == 'fa';
  String _t(String fa, String en) => _fa ? fa : en;

  Future<void> _resolve(
    SyncConflictRecord conflict,
    SyncConflictResolution resolution,
  ) async {
    setState(() => _busyId = conflict.id);
    try {
      await _repository.resolve(conflict.id, resolution);
      invalidateSyncedFeatureProviders(widget.parentRef);
      await widget.parentRef
          .read(syncSettingsProvider.notifier)
          .refreshSyncMetrics();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) => StreamBuilder<List<SyncConflictRecord>>(
        stream: _repository.watchUnresolved(),
        builder: (context, snapshot) {
          final conflicts = snapshot.data ?? const <SyncConflictRecord>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.merge_type_rounded,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('حل تعارض همگام‌سازی', 'Resolve sync conflicts'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _t(
                              'هیچ نسخه‌ای بدون انتخاب شما بازنویسی نمی‌شود.',
                              'No version is overwritten without your choice.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: conflicts.isEmpty
                    ? _ConflictEmptyState(
                        title: _t('تعارضی باقی نمانده', 'No conflicts remain'),
                        body: _t(
                          'همه تغییرات قابل ادغام هستند یا قبلاً تعیین تکلیف شده‌اند.',
                          'All changes can merge or have already been resolved.',
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: conflicts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final conflict = conflicts[index];
                          return _ConflictCard(
                            conflict: conflict,
                            busy: _busyId == conflict.id,
                            fa: _fa,
                            onKeepLocal: () => _resolve(
                              conflict,
                              SyncConflictResolution.keepLocal,
                            ),
                            onUseRemote: () => _resolve(
                              conflict,
                              SyncConflictResolution.useRemote,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.busy,
    required this.fa,
    required this.onKeepLocal,
    required this.onUseRemote,
  });

  final SyncConflictRecord conflict;
  final bool busy;
  final bool fa;
  final VoidCallback onKeepLocal;
  final VoidCallback onUseRemote;

  String _t(String faText, String enText) => fa ? faText : enText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _entityLabel(conflict.entityType, fa),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conflict.entityId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    _t(
                      'نسخه ${conflict.local.version}',
                      'Revision ${conflict.local.version}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VersionBox(
                    title: _t('این دستگاه', 'This device'),
                    deviceId: conflict.local.deviceId,
                    payload: conflict.local.payload,
                    tint: scheme.primaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _VersionBox(
                    title: _t('دستگاه دیگر', 'Other device'),
                    deviceId: conflict.remote.deviceId,
                    payload: conflict.remote.payload,
                    tint: scheme.tertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onKeepLocal,
                    icon: const Icon(Icons.phone_android_rounded),
                    label: Text(_t('نگه‌داشتن محلی', 'Keep local')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onUseRemote,
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: Text(_t('استفاده از دریافتی', 'Use remote')),
                  ),
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionBox extends StatelessWidget {
  const _VersionBox({
    required this.title,
    required this.deviceId,
    required this.payload,
    required this.tint,
  });

  final String title;
  final String deviceId;
  final Map<String, Object?> payload;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(
          deviceId.length > 10 ? deviceId.substring(0, 10) : deviceId,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _compactPayload(payload),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _ConflictEmptyState extends StatelessWidget {
  const _ConflictEmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 54),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

String _entityLabel(String entityType, bool fa) {
  const faLabels = <String, String>{
    'home_entry': 'مورد صفحه اصلی',
    'shopping_list': 'فهرست خرید',
    'shopping_item': 'قلم خرید',
    'person': 'فرد',
    'rich_note': 'یادداشت',
    'project': 'پروژه',
    'medication_plan': 'دارو',
    'cycle_log': 'چرخه',
    'finance_account': 'حساب مالی',
    'finance_transaction': 'تراکنش مالی',
    'message': 'پیام',
  };
  const enLabels = <String, String>{
    'home_entry': 'Home item',
    'shopping_list': 'Shopping list',
    'shopping_item': 'Shopping item',
    'person': 'Person',
    'rich_note': 'Note',
    'project': 'Project',
    'medication_plan': 'Medication',
    'cycle_log': 'Cycle log',
    'finance_account': 'Finance account',
    'finance_transaction': 'Finance transaction',
    'message': 'Message',
  };
  return (fa ? faLabels : enLabels)[entityType] ?? entityType;
}

String _compactPayload(Map<String, Object?> payload) {
  final preferred = <String>['title', 'name', 'text', 'body', 'amount', 'note'];
  final parts = <String>[];
  for (final key in preferred) {
    final value = payload[key];
    if (value == null || value.toString().trim().isEmpty) continue;
    parts.add('$key: $value');
    if (parts.length >= 3) break;
  }
  if (parts.isNotEmpty) return parts.join('\n');
  final raw = jsonEncode(payload);
  return raw.length > 240 ? '${raw.substring(0, 240)}…' : raw;
}
