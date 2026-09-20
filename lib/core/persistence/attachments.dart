import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'drift_entity_repository.dart';

/// Managed, content-addressed attachments. Small chunks fit incremental sync batches.
/// Legacy inline attachments remain readable; no original file path is required.
class AttachmentStore {
  AttachmentStore({DriftEntityRepository? repository})
    : repository = repository ?? DriftEntityRepository();
  final DriftEntityRepository repository;
  static const maxBytes = 32 * 1024 * 1024;
  static const chunkBytes = 32 * 1024;
  Future<Map<String, Object?>?> pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw StateError('Maximum attachment size is 32 MB.');
    }
    return put(await file.readAsBytes(), file.name);
  }

  Future<Map<String, Object?>> put(Uint8List bytes, String filename) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw StateError('Attachment must be between 1 byte and 32 MB.');
    }
    final id = sha256.convert(bytes).toString();
    final name = filename
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
        .trim();
    final safeName = name.isEmpty
        ? 'attachment'
        : name.substring(0, name.length > 200 ? 200 : name.length);
    final count = (bytes.length / chunkBytes).ceil();
    await repository.db.transaction(() async {
      final existing = await repository.loadOne('attachment_blob', id);
      if (existing == null || existing['bytes'] is! String) {
        for (var i = 0; i < count; i++) {
          final end = (i + 1) * chunkBytes > bytes.length
              ? bytes.length
              : (i + 1) * chunkBytes;
          final encoded = base64Encode(bytes.sublist(i * chunkBytes, end));
          final oldChunk = await repository.loadOne(
            'attachment_chunk',
            '$id:$i',
          );
          if (oldChunk?['bytes'] == encoded &&
              oldChunk?['attachmentId'] == id &&
              oldChunk?['index'] == i) {
            continue;
          }
          await repository.upsert('attachment_chunk', {
            'id': '$id:$i',
            'attachmentId': id,
            'index': i,
            'bytes': encoded,
          });
        }
        if (existing == null) {
          await repository.upsert('attachment_blob', {
            'id': id,
            'name': safeName,
            'size': bytes.length,
            'chunks': count,
          });
        }
      }
    });
    return {
      'id': id,
      'name': safeName,
      'size': bytes.length,
      'path': 'raha-attachment:$id',
    };
  }

  Future<Map<String, Object?>> metadata(String? path) async {
    if (path == null || !path.startsWith('raha-attachment:')) {
      throw StateError('Reattach this legacy file on its original device.');
    }
    final id = path.substring(16);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
      throw StateError('Invalid attachment reference.');
    }
    final item = await repository.loadOne('attachment_blob', id);
    if (item == null) {
      throw StateError('Attachment unavailable. Synchronize and retry.');
    }
    return item;
  }

  Future<Uint8List> read(String? path) async {
    final item = await metadata(path);
    final expected = (item['size'] as num?)?.toInt();
    if (expected == null || expected < 1 || expected > maxBytes) {
      throw StateError('Invalid attachment size.');
    }
    final builder = BytesBuilder(copy: false);
    if (item['bytes'] is String) {
      if ((item['bytes']! as String).length > maxBytes * 2) {
        throw StateError('Oversized attachment.');
      }
      builder.add(base64Decode(item['bytes']! as String));
    } else {
      final count = (item['chunks'] as num?)?.toInt() ?? 0;
      if (count < 1 || count != (expected / chunkBytes).ceil()) {
        throw StateError('Invalid chunk count.');
      }
      for (var i = 0; i < count; i++) {
        final chunk = await repository.loadOne(
          'attachment_chunk',
          '${item['id']}:$i',
        );
        final encoded = chunk?['bytes'];
        if (encoded is! String || encoded.length > chunkBytes * 2) {
          throw StateError('Attachment incomplete. Synchronize and retry.');
        }
        final bytes = base64Decode(encoded);
        if (bytes.length > chunkBytes) throw StateError('Invalid chunk size.');
        builder.add(bytes);
      }
    }
    final bytes = builder.takeBytes();
    if (bytes.length != expected ||
        sha256.convert(bytes).toString() != item['id']) {
      throw StateError('Attachment integrity check failed.');
    }
    return bytes;
  }

  Future<void> save(String? path) async {
    final item = await metadata(path);
    await FilePicker.saveFile(
      fileName: item['name'].toString(),
      bytes: await read(path),
    );
  }
}
