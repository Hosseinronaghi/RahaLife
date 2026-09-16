import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';

import 'drift_entity_repository.dart';

class AttachmentStore {
  final DriftEntityRepository repository = DriftEntityRepository();
  Future<Map<String, Object?>?> pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if (await file.length() > 4 * 1024 * 1024) {
      throw StateError('Maximum attachment size is 4 MB.');
    }
    final bytes = await file.readAsBytes();
    final id = sha256.convert(bytes).toString();
    await repository.upsert('attachment_blob', {
      'id': id,
      'name': file.name,
      'bytes': base64Encode(bytes),
      'size': bytes.length,
    });
    return {
      'id': id,
      'name': file.name,
      'size': bytes.length,
      'path': 'raha-attachment:$id',
    };
  }

  Future<void> save(String? path) async {
    if (path == null || !path.startsWith('raha-attachment:')) {
      throw StateError('Reattach this legacy file on its original device.');
    }
    final item = await repository.loadOne(
      'attachment_blob',
      path.substring(16),
    );
    if (item == null) {
      throw StateError(
        'Attachment has not arrived yet. Synchronize and retry.',
      );
    }
    await FilePicker.saveFile(
      fileName: item['name'].toString(),
      bytes: base64Decode(item['bytes'] as String),
    );
  }
}
