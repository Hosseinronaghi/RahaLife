import 'dart:typed_data';

enum SyncProviderKind {
  localOnly,
  manualFile,
  googleDrive,
  oneDrive,
  dropbox,
  iCloud,
  webDav,
  nextcloud,
  s3,
  sftp,
  rahaServer,
  customHttp,
  peerToPeer,
}

enum SyncTargetPurpose { sync, backup, both }

enum SyncProviderCapability {
  manualBackup,
  automaticBackup,
  recordSync,
  realtime,
  files,
  selfHosted,
}

class SyncConnectionProfile {
  const SyncConnectionProfile({
    required this.id,
    required this.name,
    required this.kind,
    required this.purpose,
    this.enabled = true,
    this.isPrimary = false,
    this.config = const <String, String>{},
    this.lastTestedAt,
    this.lastSuccessAt,
    this.lastError,
  });

  factory SyncConnectionProfile.fromJson(Map<String, Object?> json) {
    return SyncConnectionProfile(
      id: json['id']! as String,
      name: json['name']! as String,
      kind: SyncProviderKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => SyncProviderKind.manualFile,
      ),
      purpose: SyncTargetPurpose.values.firstWhere(
        (value) => value.name == json['purpose'],
        orElse: () => SyncTargetPurpose.backup,
      ),
      enabled: json['enabled'] as bool? ?? true,
      isPrimary: json['isPrimary'] as bool? ?? false,
      config: json['config'] is Map
          ? Map<String, String>.from(json['config']! as Map)
          : const <String, String>{},
      lastTestedAt: _parseDate(json['lastTestedAt']),
      lastSuccessAt: _parseDate(json['lastSuccessAt']),
      lastError: json['lastError'] as String?,
    );
  }

  final String id;
  final String name;
  final SyncProviderKind kind;
  final SyncTargetPurpose purpose;
  final bool enabled;
  final bool isPrimary;
  final Map<String, String> config;
  final DateTime? lastTestedAt;
  final DateTime? lastSuccessAt;
  final String? lastError;

  SyncConnectionProfile copyWith({
    String? name,
    SyncProviderKind? kind,
    SyncTargetPurpose? purpose,
    bool? enabled,
    bool? isPrimary,
    Map<String, String>? config,
    DateTime? lastTestedAt,
    DateTime? lastSuccessAt,
    String? lastError,
    bool clearLastError = false,
  }) {
    return SyncConnectionProfile(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      purpose: purpose ?? this.purpose,
      enabled: enabled ?? this.enabled,
      isPrimary: isPrimary ?? this.isPrimary,
      config: config ?? this.config,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'kind': kind.name,
    'purpose': purpose.name,
    'enabled': enabled,
    'isPrimary': isPrimary,
    'config': config,
    'lastTestedAt': lastTestedAt?.toUtc().toIso8601String(),
    'lastSuccessAt': lastSuccessAt?.toUtc().toIso8601String(),
    'lastError': lastError,
  };
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

class BackupObject {
  const BackupObject({
    required this.bytes,
    required this.fileName,
    required this.createdAtUtc,
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime createdAtUtc;
}

class BackupTargetTestResult {
  const BackupTargetTestResult({required this.success, required this.message});

  final bool success;
  final String message;
}

abstract interface class BackupTarget {
  SyncProviderKind get kind;
  Set<SyncProviderCapability> get capabilities;

  Future<BackupTargetTestResult> testConnection();
  Future<void> upload(BackupObject object);
  Future<BackupObject?> downloadLatest();
}
