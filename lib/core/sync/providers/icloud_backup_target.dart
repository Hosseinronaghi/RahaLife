import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'backup_target.dart';

class ICloudBackupTarget implements BackupTarget {
  ICloudBackupTarget({
    this.channel = const MethodChannel('com.raha.life/icloud_backup'),
  });

  final MethodChannel channel;
  static const maxBytes = 32 * 1024 * 1024;
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  SyncProviderKind get kind => SyncProviderKind.iCloud;

  @override
  Set<SyncProviderCapability> get capabilities => {
    SyncProviderCapability.automaticBackup,
    SyncProviderCapability.files,
  };

  @override
  Future<BackupTargetTestResult> testConnection() async {
    try {
      if (await channel.invokeMethod<bool>('check') == true) {
        return const BackupTargetTestResult(
          success: true,
          message: 'iCloud application storage is available.',
        );
      }
    } on PlatformException {
      // An ad-hoc build or a signed-out account cannot use the container.
    } on MissingPluginException {
      // The channel is compiled only for Apple platforms.
    }
    return const BackupTargetTestResult(
      success: false,
      message: 'A signed iCloud build and an active iCloud account are required.',
    );
  }

  @override
  Future<void> upload(BackupObject object) async {
    if (object.bytes.isEmpty || object.bytes.length > maxBytes) {
      throw StateError('icloud_backup_size_limit');
    }
    await channel.invokeMethod<void>('upload', object.bytes);
  }

  @override
  Future<BackupObject?> downloadLatest() async {
    final result = await channel.invokeMapMethod<String, Object?>('downloadLatest');
    if (result == null) return null;
    final bytes = result['bytes'];
    final file = result['fileName'];
    final stamp = result['createdAtMillis'];
    if (bytes is! Uint8List || bytes.isEmpty || bytes.length > maxBytes ||
        file is! String || stamp is! int) {
      throw StateError('icloud_invalid_backup');
    }
    return BackupObject(
      bytes: bytes,
      fileName: file,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true),
    );
  }
}
