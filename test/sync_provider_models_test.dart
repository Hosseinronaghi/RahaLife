import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/core/sync/providers/backup_target.dart';
import 'package:raha_life/core/sync/providers/transport_security.dart';

void main() {
  test('sync connection profile survives json round-trip', () {
    final profile = SyncConnectionProfile(
      id: 'connection-1',
      name: 'Home NAS',
      kind: SyncProviderKind.webDav,
      purpose: SyncTargetPurpose.backup,
      isPrimary: true,
      config: const <String, String>{
        'baseUrl': 'https://nas.example.com/dav',
        'remotePath': 'RahaLife',
      },
      lastTestedAt: DateTime.utc(2026, 8, 14, 18),
    );

    final restored = SyncConnectionProfile.fromJson(profile.toJson());

    expect(restored.id, profile.id);
    expect(restored.kind, SyncProviderKind.webDav);
    expect(restored.isPrimary, isTrue);
    expect(restored.config['remotePath'], 'RahaLife');
    expect(restored.lastTestedAt, DateTime.utc(2026, 8, 14, 18));
  });

  test('HTTP requires an explicit trusted-network override', () {
    const blocked = SyncConnectionProfile(
      id: 'blocked',
      name: 'LAN server',
      kind: SyncProviderKind.rahaServer,
      purpose: SyncTargetPurpose.backup,
      config: <String, String>{'baseUrl': 'http://192.168.1.20:8080'},
    );
    const allowed = SyncConnectionProfile(
      id: 'allowed',
      name: 'LAN server',
      kind: SyncProviderKind.rahaServer,
      purpose: SyncTargetPurpose.backup,
      config: <String, String>{
        'baseUrl': 'http://192.168.1.20:8080',
        'allowInsecureHttp': 'true',
      },
    );

    expect(() => validateTransportSecurity(blocked), throwsFormatException);
    expect(() => validateTransportSecurity(allowed), returnsNormally);
  });
}
