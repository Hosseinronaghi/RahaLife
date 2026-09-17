import 'dart:typed_data';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database_provider.dart';
import '../../core/persistence/drift_entity_repository.dart';
import 'record_editor.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});
  Future<void> _import(BuildContext c) async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    final text = utf8.decode(await file.readAsBytes());
    final links = RegExp(
      r'<a\b[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(text);
    final repository = DriftEntityRepository();
    final existing = await repository.loadAll('bookmark');
    final urls = existing.map((e) => e['url'].toString()).toSet();
    var count = 0;
    for (final link in links) {
      final url = link[1]!.replaceAll('&amp;', '&');
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          !urls.add(url)) {
        continue;
      }
      await repository.upsert('bookmark', {
        'id': const Uuid().v4(),
        'title': link[2]!.replaceAll(RegExp('<[^>]+>'), ''),
        'url': url,
        'folder': 'Imported',
        'archived': false,
      });
      count++;
    }
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(
        SnackBar(
          content: Text(
            '$count ${tr(c, 'نشانک وارد شد', 'bookmarks imported')}',
          ),
        ),
      );
    }
  }

  Future<void> _export() async {
    final rows = await DriftEntityRepository().loadAll('bookmark');
    const escape = HtmlEscape();
    final html =
        '<!DOCTYPE NETSCAPE-Bookmark-file-1><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8"><TITLE>Raha Bookmarks</TITLE><DL><p>${rows.map((e) => '<DT><A HREF="${escape.convert(e['url'].toString())}">${escape.convert(e['title'].toString())}</A>').join('\n')}</DL>';
    await FilePicker.saveFile(
      fileName: 'Raha-Bookmarks.html',
      bytes: Uint8List.fromList(utf8.encode(html)),
    );
  }

  @override
  Widget build(BuildContext c, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(tr(c, 'نشانک‌ها', 'Bookmarks')),
      actions: [
        IconButton(
          tooltip: tr(c, 'ورود HTML', 'Import HTML'),
          onPressed: () => _import(c),
          icon: const Icon(Icons.file_open_outlined),
        ),
        IconButton(
          tooltip: tr(c, 'خروجی HTML', 'Export HTML'),
          onPressed: _export,
          icon: const Icon(Icons.download_outlined),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => editRecord(c, ref, 'bookmark', {
        'id': const Uuid().v4(),
        'title': '',
        'url': 'https://',
        'folder': '',
      }),
      child: const Icon(Icons.add),
    ),
    body: StreamBuilder(
      stream: appDatabase.select(appDatabase.entityDocuments).watch(),
      builder: (c, snapshot) {
        final rows =
            snapshot.data
                ?.where(
                  (e) =>
                      e.entityType == 'bookmark' &&
                      e.deletedAt == null &&
                      jsonDecode(e.payloadJson)['archived'] != true,
                )
                .toList() ??
            [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          itemBuilder: (c, i) {
            final data = Map<String, Object?>.from(
              jsonDecode(rows[i].payloadJson) as Map,
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: Text(data['title'].toString()),
                subtitle: Text('${data['folder'] ?? ''}\n${data['url']}'),
                isThreeLine: true,
                onTap: () async {
                  final uri = Uri.tryParse(data['url'].toString());
                  if (uri == null ||
                      !['http', 'https'].contains(uri.scheme) ||
                      uri.host.isEmpty) {
                    return;
                  }
                  try {
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw StateError('Unable to open link');
                    }
                  } catch (e) {
                    if (c.mounted) {
                      ScaffoldMessenger.of(
                        c,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => recordActions(c, ref, 'bookmark', data),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
