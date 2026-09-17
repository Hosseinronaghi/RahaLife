import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/persistence/drift_entity_repository.dart';
import '../sync/presentation/synced_feature_refresh.dart';
import 'record_editor.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});
  @override
  ConsumerState<RecordsScreen> createState() => _RecordsState();
}

class _RecordsState extends ConsumerState<RecordsScreen> {
  String query = '';
  bool trash = false;
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(c, 'مدیریت اطلاعات', 'Manage records')),
        actions: [
          IconButton(
            tooltip: tr(c, 'حذف‌شده‌ها', 'Trash'),
            icon: Icon(trash ? Icons.folder : Icons.delete_outline),
            onPressed: () => setState(() => trash = !trash),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr(
                  c,
                  'جست‌وجو در اطلاعات و بایگانی',
                  'Search records and archive',
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: appDatabase.select(appDatabase.entityDocuments).watch(),
              builder: (c, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!
                    .where(
                      (r) =>
                          ![
                            'attachment_blob',
                            'user_preferences',
                          ].contains(r.entityType) &&
                          (r.deletedAt != null) == trash &&
                          r.payloadJson.contains(query),
                    )
                    .toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (c, i) {
                    final r = rows[i];
                    final data = Map<String, Object?>.from(
                      jsonDecode(r.payloadJson) as Map,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          trash ? Icons.restore : Icons.description_outlined,
                        ),
                        title: Text(
                          (data['title'] ??
                                  data['name'] ??
                                  data['body'] ??
                                  data['note'] ??
                                  '—')
                              .toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: data['archived'] == true
                            ? Text(tr(c, 'بایگانی‌شده', 'Archived'))
                            : null,
                        trailing: Icon(
                          trash ? Icons.restore : Icons.more_horiz,
                        ),
                        onTap: () async {
                          if (trash) {
                            await DriftEntityRepository().upsert(
                              r.entityType,
                              data,
                            );
                            invalidateSyncedFeatureProviders(ref);
                          } else {
                            await recordActions(c, ref, r.entityType, data);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
