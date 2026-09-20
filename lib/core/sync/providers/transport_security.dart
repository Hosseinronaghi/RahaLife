import 'backup_target.dart';

bool usesHttpTransport(SyncProviderKind kind) => switch (kind) {
  SyncProviderKind.webDav ||
  SyncProviderKind.nextcloud ||
  SyncProviderKind.s3 ||
  SyncProviderKind.rahaServer ||
  SyncProviderKind.customHttp => true,
  _ => false,
};

String? connectionEndpoint(SyncConnectionProfile profile) =>
    switch (profile.kind) {
      SyncProviderKind.webDav ||
      SyncProviderKind.nextcloud => profile.config['baseUrl'],
      SyncProviderKind.s3 => profile.config['endpoint'],
      SyncProviderKind.rahaServer ||
      SyncProviderKind.customHttp => profile.config['baseUrl'],
      _ => null,
    };

void validateTransportSecurity(SyncConnectionProfile profile) {
  if (!usesHttpTransport(profile.kind)) return;
  final raw = connectionEndpoint(profile)?.trim() ?? '';
  if (raw.isEmpty) return;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.host.isEmpty ||
      !uri.hasScheme ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException('A valid server URL is required.');
  }
  if (uri.scheme.toLowerCase() == 'https') return;
  if (uri.scheme.toLowerCase() == 'http' &&
      profile.config['allowInsecureHttp'] == 'true') {
    return;
  }
  throw const FormatException(
    'HTTPS is required. Enable insecure HTTP only for a trusted local network.',
  );
}
