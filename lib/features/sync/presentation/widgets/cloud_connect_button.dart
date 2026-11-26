import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../../core/sync/providers/backup_target.dart';
import '../../../../core/sync/providers/backup_target_factory.dart';
import '../../../../core/sync/providers/oauth_pkce.dart';
import '../sync_controller.dart';

class CloudConnectButton extends ConsumerStatefulWidget {
  const CloudConnectButton({
    super.key,
    this.kind = SyncProviderKind.dropbox,
  });

  final SyncProviderKind kind;
  @override
  ConsumerState<CloudConnectButton> createState() => _CloudConnectState();
}

class _CloudConnectState extends ConsumerState<CloudConnectButton> {
  bool busy = false;
  String status = '';
  static bool _authInProgress = false;
  bool get _oneDrive => widget.kind == SyncProviderKind.oneDrive;
  String get _name => _oneDrive ? 'OneDrive' : 'Dropbox';
  bool get _configured =>
      _oneDrive ? OneDriveOAuth.configured : DropboxOAuth.configured;
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;

  Future<void> connect() async {
    if (busy || _authInProgress) return;
    setState(() {
      busy = true;
      status = '';
    });
    _authInProgress = true;
    try {
      final redirect = Uri.parse(_oneDrive ? OneDriveOAuth.redirect : DropboxOAuth.redirect);
      final desktop =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);
      if (redirect.hasQuery ||
          redirect.hasFragment ||
          redirect.userInfo.isNotEmpty) {
        throw StateError('invalid_redirect_configuration');
      }
      if (kIsWeb) {
        if (redirect.origin != Uri.base.origin || redirect.scheme != 'https') {
          throw StateError('web_requires_same_origin_https_callback');
        }
      } else if (desktop) {
        if (redirect.scheme != 'http' ||
            redirect.host != '127.0.0.1' ||
            !redirect.hasPort ||
            redirect.port == 0) {
          throw StateError('desktop_requires_loopback_callback');
        }
      } else if (redirect.scheme != 'com.raha.life.oauth') {
        throw StateError('native_callback_scheme_mismatch');
      }
      final attempt = OAuthPkceAttempt(redirectUri: redirect);
      final oneDrive = OneDriveOAuth();
      final dropbox = DropboxOAuth();
      final appId = _oneDrive ? OneDriveOAuth.clientId : DropboxOAuth.clientId;
      final authorization = _oneDrive
          ? oneDrive.authorize(attempt, appId)
          : dropbox.authorize(attempt, appId);
      final callback = await FlutterWebAuth2.authenticate(
        url: authorization.toString(),
        callbackUrlScheme: desktop ? redirect.toString() : redirect.scheme,
        options: const FlutterWebAuth2Options(useWebview: false, timeout: 300),
      );
      final parsed = Uri.parse(callback);
      final credentials = _oneDrive
          ? await oneDrive.exchange(attempt: attempt, callback: parsed, appId: appId)
          : await dropbox.exchange(attempt: attempt, callback: parsed, appId: appId);
      if (!mounted) return;
      final controller = ref.read(syncSettingsProvider.notifier);
      final validation = await createBackupTarget(
        profile: SyncConnectionProfile(
          id: 'oauth-validation',
          name: _name,
          kind: widget.kind,
          purpose: SyncTargetPurpose.backup,
        ),
        credentials: credentials,
      ).testConnection();
      if (!validation.success) throw StateError('cloud_validation_failed');
      if (!mounted) return;
      await controller.addConnection(
        name: _name,
        kind: widget.kind,
        purpose: SyncTargetPurpose.backup,
        config: const {},
        credentials: credentials,
      );
      if (mounted) {
        setState(
          () => status = t(
            'متصل شد؛ اکنون می‌توانید پشتیبان بگیرید یا بازیابی کنید. همگام‌سازی رکوردها از این مسیر هنوز فعال نیست.',
            'Connected. Backup and restore are available. This connection does not sync individual records.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => status = t(
            'اتصال کامل نشد؛ ممکن است ورود لغو شده باشد یا تنظیمات انتشار و شبکه نیاز به بررسی داشته باشد.',
            'Connection did not complete. Sign-in may have been cancelled; check release configuration and network.',
          ),
        );
      }
    } finally {
      _authInProgress = false;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: !_configured || busy ? null : connect,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_outlined),
        label: Text(t('اتصال به $_name', 'Connect to $_name')),
      ),
      if (!_configured)
        Text(
          t(
            'ورود مستقیم $_name در این بسته فعال نیست.',
            'Direct $_name sign-in is not enabled in this build.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (status.isNotEmpty) Text(status),
    ],
  );
}
