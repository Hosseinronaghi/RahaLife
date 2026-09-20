import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/persistence/attachments.dart';
import 'attachment_preview.dart';
import 'voice_recorder.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({
    this.entityType,
    this.entityId,
    this.attachmentStore,
    super.key,
  });
  final String? entityType, entityId;
  final AttachmentStore? attachmentStore;
  @override
  State<FilesScreen> createState() => _FilesState();
}

class _FilesState extends State<FilesScreen> {
  late final store = widget.attachmentStore ?? AttachmentStore();
  List<Map<String, Object?>> items = [];
  bool loading = true, busy = false;
  String? error;
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final type = widget.entityId == null
          ? 'attachment_blob'
          : 'attachment_link';
      final all = await store.repository.loadAll(type);
      if (!mounted) return;
      setState(() {
        items = all
            .where(
              (e) =>
                  widget.entityId == null ||
                  (e['entityId'] == widget.entityId &&
                      e['entityType'] == widget.entityType),
            )
            .toList();
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = t('خواندن فایل‌ها ناموفق بود.', 'Could not load files.');
        });
      }
    }
  }

  Future<void> add({bool voice = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      Map<String, Object?>? file;
      if (voice) {
        final bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(builder: (_) => const VoiceRecorderScreen()),
        );
        if (bytes != null) {
          file = await store.put(
            bytes,
            'Voice-${DateTime.now().millisecondsSinceEpoch}.wav',
          );
        }
      } else {
        file = await store.pick();
      }
      if (file != null && widget.entityId != null) {
        await store.repository.upsert('attachment_link', {
          ...file,
          'id': const Uuid().v4(),
          'attachmentId': file['id'],
          'entityType': widget.entityType,
          'entityId': widget.entityId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      }
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'افزودن فایل انجام نشد؛ سقف هر فایل ۳۲ مگابایت است.',
            'Could not add file; maximum 32 MB each.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> unlink(Map<String, Object?> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          t('پیوست از این مورد جدا شود؟', 'Remove this attachment link?'),
        ),
        content: Text(
          t(
            'خود فایل در بخش فایل‌ها باقی می‌ماند.',
            'The file remains in Files.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('لغو', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('جدا کردن', 'Unlink')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await store.repository.deleteFromSnapshot('attachment_link', item);
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(() => error = t('تغییر ذخیره نشد.', 'Could not save change.'));
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(t('فایل‌ها و صداها', 'Files and recordings')),
      actions: [
        IconButton(
          onPressed: busy ? null : refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => add(),
                    icon: const Icon(Icons.upload_file),
                    label: Text(t('افزودن فایل', 'Add file')),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => add(voice: true),
                    icon: const Icon(Icons.mic),
                    label: Text(t('ضبط صدا', 'Record voice')),
                  ),
                ],
              ),
              if (busy) const LinearProgressIndicator(),
              if (error != null) Text(error!),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(t('هنوز فایلی اضافه نشده است.', 'No files yet.')),
                ),
              for (final item in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(item['name']?.toString() ?? ''),
                    subtitle: Text(
                      '${((item['size'] as num? ?? 0) / 1024 / 1024).toStringAsFixed(1)} ${t('مگابایت', 'MB')}',
                    ),
                    onTap: () => openAttachment(
                      c,
                      item['path']?.toString() ??
                          'raha-attachment:${item['id']}',
                    ),
                    trailing: widget.entityId == null
                        ? null
                        : IconButton(
                            onPressed: busy ? null : () => unlink(item),
                            icon: const Icon(Icons.link_off),
                          ),
                  ),
                ),
            ],
          ),
  );
}
