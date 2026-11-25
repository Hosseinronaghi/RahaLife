import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../../core/sync/providers/backup_target.dart';
import '../../../../core/sync/providers/dropbox_backup_target.dart';
import '../../../../core/sync/providers/oauth_pkce.dart';
import '../sync_controller.dart';

class DropboxConnectButton extends ConsumerStatefulWidget {
  const DropboxConnectButton({super.key});
  @override
  ConsumerState<DropboxConnectButton> createState() => _DropboxConnectState();
}

class _DropboxConnectState extends ConsumerState<DropboxConnectButton> {
  bool busy = false;
  String status = '';
  static bool _authInProgress = false;
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
      final redirect = Uri.parse(DropboxOAuth.redirect);
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
      final oauth = DropboxOAuth();
      final callback = await FlutterWebAuth2.authenticate(
        url: oauth.authorize(attempt, DropboxOAuth.clientId).toString(),
        callbackUrlScheme: desktop ? redirect.toString() : redirect.scheme,
        options: const FlutterWebAuth2Options(useWebview: false, timeout: 300),
      );
      final credentials = await oauth.exchange(
        attempt: attempt,
        callback: Uri.parse(callback),
        appId: DropboxOAuth.clientId,
      );
      if (!mounted) return;
      final controller = ref.read(syncSettingsProvider.notifier);
      final email = await DropboxBackupTarget(
        profile: const SyncConnectionProfile(
          id: 'oauth-validation',
          name: 'Dropbox',
          kind: SyncProviderKind.dropbox,
          purpose: SyncTargetPurpose.backup,
        ),
        credentials: credentials,
      ).accountEmail();
      if (!mounted) return;
      await controller.addConnection(
        name: email.isEmpty ? 'Dropbox' : 'Dropbox · $email',
        kind: SyncProviderKind.dropbox,
        purpose: SyncTargetPurpose.backup,
        config: const {},
        credentials: credentials,
      );
      if (mounted) {
        setState(
          () => status = t(
            'متصل شد؛ اکنون می‌توانید پشتیبان بگیرید یا بازیابی کنید. همگام‌سازی رکوردها از این مسیر هنوز فعال نیست.',
            'Connected. Backup and restore are available. Record sync through Dropbox is not enabled yet.',
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
        onPressed: !DropboxOAuth.configured || busy ? null : connect,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_outlined),
        label: Text(t('اتصال به Dropbox', 'Connect to Dropbox')),
      ),
      if (!DropboxOAuth.configured)
        Text(
          t(
            'ورود مستقیم Dropbox در این بسته هنوز توسط ناشر فعال نشده است.',
            'Direct Dropbox sign-in has not been configured by the publisher in this build.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (status.isNotEmpty) Text(status),
    ],
  );
}
