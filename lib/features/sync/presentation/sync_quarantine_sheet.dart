import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/persistence/drift_entity_repository.dart';
import '../../../core/sync/sync_scope.dart';
import '../../workspace/record_editor.dart';
import 'sync_controller.dart';

Future<void> showSyncQuarantineSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final profile = ref.read(syncSettingsProvider).primaryConnection;
  final types = profile == null ? null : syncTypes(profile.config);
  final rows = await appDatabase
      .customSelect(
        'SELECT c.entity_type,c.entity_id,MAX(q.bytes) AS bytes FROM sync_quarantine q JOIN sync_changes c ON c.change_id=q.change_id WHERE c.uploaded=0 GROUP BY c.entity_type,c.entity_id',
      )
      .get();
  final items =
      <({String type, String id, int bytes, Map<String, Object?>? current})>[];
  final repository = DriftEntityRepository();
  for (final row in rows) {
    final type = row.read<String>('entity_type'),
        id = row.read<String>('entity_id');
    if (types != null && !types.contains(type)) continue;
    items.add((
      type: type,
      id: id,
      bytes: row.read<int>('bytes'),
      current: await repository.loadOne(type, id),
    ));
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => FractionallySizedBox(
      heightFactor: .75,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr(sheet, 'تغییرهای بیش‌ازحد بزرگ', 'Oversized changes'),
            style: Theme.of(sheet).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              sheet,
              'محتوای رکورد را کم کنید و دوباره ذخیره کنید. تغییر جدید ارسال می‌شود؛ نسخهٔ بزرگ در تاریخچهٔ محلی باقی می‌ماند.',
              'Reduce the record and save it again. The new change can sync; the oversized revision remains in local history.',
            ),
          ),
          for (final item in items)
            ListTile(
              title: Text(
                (item.current?['title'] ?? item.current?['name'] ?? item.id)
                    .toString(),
              ),
              subtitle: Text('${(item.bytes / 1048576).toStringAsFixed(1)} MB'),
              trailing: item.current == null
                  ? null
                  : const Icon(Icons.edit_outlined),
              onTap: item.current == null
                  ? null
                  : () async {
                      Navigator.pop(sheet);
                      await recordActions(
                        context,
                        ref,
                        item.type,
                        jsonDecode(jsonEncode(item.current))
                            as Map<String, dynamic>,
                      );
                    },
            ),
        ],
      ),
    ),
  );
}
