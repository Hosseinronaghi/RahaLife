import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../core/persistence/attachments.dart';

Future<void> openAttachment(BuildContext context, String? path) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AttachmentPreview(path: path)),
  );
}

class AttachmentPreview extends StatefulWidget {
  const AttachmentPreview({required this.path, super.key});
  final String? path;
  @override
  State<AttachmentPreview> createState() => _PreviewState();
}

class _PreviewState extends State<AttachmentPreview> {
  final store = AttachmentStore();
  Uint8List? bytes;
  String name = '', kind = '', error = '';
  Player? player;
  VideoController? video;
  StreamSubscription<String>? errors;
  bool exporting = false;
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final meta = await store.metadata(widget.path);
      final content = await store.read(widget.path);
      if (!mounted) return;
      name = meta['name'].toString();
      kind = name.split('.').last.toLowerCase();
      bytes = content;
      if ([
        'mp4',
        'mov',
        'mkv',
        'webm',
        'mp3',
        'm4a',
        'aac',
        'wav',
        'ogg',
        'flac',
      ].contains(kind)) {
        MediaKit.ensureInitialized();
        final p = Player();
        player = p;
        video = VideoController(p);
        errors = p.stream.error.listen((_) {
          if (mounted) {
            setState(
              () => error = t(
                'این فایل قابل پخش نیست.',
                'Cannot play this file.',
              ),
            );
          }
        });
        final media = await Media.memory(
          content,
          type: kind == 'wav'
              ? 'audio/wav'
              : kind == 'mp3'
              ? 'audio/mpeg'
              : kind == 'mp4'
              ? 'video/mp4'
              : null,
        );
        if (!mounted) return;
        await p.open(media, play: false);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'فایل ناقص، نامعتبر یا در دسترس نیست. همگام‌سازی را بررسی کنید.',
            'File incomplete, unsupported or unavailable. Check synchronization.',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    errors?.cancel();
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(name.isEmpty ? t('پیوست', 'Attachment') : name),
      actions: [
        IconButton(
          tooltip: t('ذخیره فایل', 'Save file'),
          icon: const Icon(Icons.download_outlined),
          onPressed: bytes == null || exporting
              ? null
              : () async {
                  setState(() => exporting = true);
                  try {
                    await store.save(widget.path);
                  } catch (_) {
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(t('ذخیره نشد.', 'Could not save.')),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => exporting = false);
                  }
                },
        ),
      ],
    ),
    body: error.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error),
            ),
          )
        : bytes == null
        ? const Center(child: CircularProgressIndicator())
        : video != null
        ? Video(controller: video!)
        : ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(kind)
        ? InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(
              child: Image.memory(
                bytes!,
                errorBuilder: (_, _, _) =>
                    Text(t('تصویر خوانده نشد.', 'Cannot read image.')),
              ),
            ),
          )
        : kind == 'pdf'
        ? PdfViewer.data(bytes!, sourceName: widget.path!)
        : Center(
            child: Text(
              t(
                'پیش‌نمایش این نوع فایل موجود نیست؛ می‌توانید آن را ذخیره کنید.',
                'Preview unavailable; you can save this file.',
              ),
            ),
          ),
  );
}
