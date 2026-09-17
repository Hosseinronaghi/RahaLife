import 'package:flutter/material.dart';

import '../../../../core/sync/providers/backup_target.dart';

class SyncConnectionDraft {
  const SyncConnectionDraft({
    required this.name,
    required this.kind,
    required this.purpose,
    required this.config,
    required this.credentials,
  });

  final String name;
  final SyncProviderKind kind;
  final SyncTargetPurpose purpose;
  final Map<String, String> config;
  final Map<String, String> credentials;
}

Future<SyncConnectionDraft?> showSyncConnectionSheet(
  BuildContext context, {
  required SyncProviderKind kind,
}) {
  return showModalBottomSheet<SyncConnectionDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SyncConnectionSheet(kind: kind),
  );
}

class _SyncConnectionSheet extends StatefulWidget {
  const _SyncConnectionSheet({required this.kind});

  final SyncProviderKind kind;

  @override
  State<_SyncConnectionSheet> createState() => _SyncConnectionSheetState();
}

class _SyncConnectionSheetState extends State<_SyncConnectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _baseUrl = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _token = TextEditingController();
  final _remotePath = TextEditingController(text: 'RahaLife');
  final _endpoint = TextEditingController();
  final _bucket = TextEditingController();
  final _region = TextEditingController(text: 'us-east-1');
  final _prefix = TextEditingController(text: 'RahaLife');
  final _accessKey = TextEditingController();
  final _secretKey = TextEditingController();
  final _sessionToken = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '22');
  var _purpose = SyncTargetPurpose.backup;
  var _pathStyle = true;
  var _allowInsecureHttp = false;
  var _showSecrets = false;

  bool get _fa => Localizations.localeOf(context).languageCode == 'fa';
  String t(String fa, String en) => _fa ? fa : en;

  bool get _supportsRecordSync =>
      widget.kind == SyncProviderKind.rahaServer ||
      widget.kind == SyncProviderKind.customHttp;

  @override
  void initState() {
    super.initState();
    _name.text = _defaultName(widget.kind);
    if (_supportsRecordSync) _purpose = SyncTargetPurpose.both;
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _baseUrl,
      _username,
      _password,
      _token,
      _remotePath,
      _endpoint,
      _bucket,
      _region,
      _prefix,
      _accessKey,
      _secretKey,
      _sessionToken,
      _host,
      _port,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _defaultName(SyncProviderKind kind) => switch (kind) {
    SyncProviderKind.webDav => t('وب‌دَو شخصی', 'Personal WebDAV'),
    SyncProviderKind.nextcloud => t('نکست‌کلاد من', 'My Nextcloud'),
    SyncProviderKind.s3 => t('فضای S3 من', 'My S3 storage'),
    SyncProviderKind.sftp => t('سرور SFTP من', 'My SFTP server'),
    SyncProviderKind.rahaServer => t('سرور رها سینک', 'Raha Sync server'),
    SyncProviderKind.customHttp => t('سرور سفارشی', 'Custom server'),
    _ => t('اتصال جدید', 'New connection'),
  };

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return t('این فیلد الزامی است.', 'This field is required.');
    }
    return null;
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool secret = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: secret && !_showSecrets,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  List<Widget> _providerFields() => switch (widget.kind) {
    SyncProviderKind.webDav || SyncProviderKind.nextcloud => <Widget>[
      _field(
        _baseUrl,
        t('آدرس WebDAV', 'WebDAV URL'),
        hint: widget.kind == SyncProviderKind.nextcloud
            ? 'https://cloud.example.com/remote.php/dav/files/USERNAME'
            : 'https://example.com/dav',
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(_username, t('نام کاربری', 'Username'), validator: _required),
      const SizedBox(height: 12),
      _field(
        _password,
        t('رمز یا App Password', 'Password or app password'),
        secret: true,
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(
        _remotePath,
        t('پوشه رها لایف', 'Raha Life folder'),
        validator: _required,
      ),
    ],
    SyncProviderKind.s3 => <Widget>[
      _field(
        _endpoint,
        t('Endpoint', 'Endpoint'),
        hint: 'https://s3.example.com',
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(_bucket, t('Bucket', 'Bucket'), validator: _required),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _field(_region, t('منطقه', 'Region'), validator: _required),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _prefix,
              t('پوشه/Prefix', 'Folder / prefix'),
              validator: _required,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _field(_accessKey, t('Access Key', 'Access key'), validator: _required),
      const SizedBox(height: 12),
      _field(
        _secretKey,
        t('Secret Key', 'Secret key'),
        secret: true,
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(
        _sessionToken,
        t('Session Token (اختیاری)', 'Session token (optional)'),
        secret: true,
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(t('استفاده از Path-style', 'Use path-style URLs')),
        subtitle: Text(
          t(
            'برای MinIO و بسیاری از سرویس‌های سازگار با S3 مناسب است.',
            'Recommended for MinIO and many S3-compatible services.',
          ),
        ),
        value: _pathStyle,
        onChanged: (value) => setState(() => _pathStyle = value),
      ),
    ],
    SyncProviderKind.sftp => <Widget>[
      Row(
        children: [
          Expanded(
            flex: 3,
            child: _field(
              _host,
              t('هاست / IP', 'Host / IP'),
              validator: _required,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _port,
              t('پورت', 'Port'),
              keyboardType: TextInputType.number,
              validator: _required,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _field(_username, t('نام کاربری', 'Username'), validator: _required),
      const SizedBox(height: 12),
      _field(
        _password,
        t('رمز عبور', 'Password'),
        secret: true,
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(
        _remotePath,
        t('مسیر پشتیبان', 'Backup path'),
        hint: '/home/user/RahaLife',
        validator: _required,
      ),
    ],
    SyncProviderKind.rahaServer || SyncProviderKind.customHttp => <Widget>[
      _field(
        _baseUrl,
        t('آدرس سرور', 'Server URL'),
        hint: 'https://sync.example.com',
        validator: _required,
      ),
      const SizedBox(height: 12),
      _field(
        _token,
        t('توکن دسترسی', 'Access token'),
        secret: true,
        validator: _required,
      ),
    ],
    _ => const <Widget>[],
  };

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final config = <String, String>{};
    final credentials = <String, String>{};
    switch (widget.kind) {
      case SyncProviderKind.webDav:
      case SyncProviderKind.nextcloud:
        config.addAll(<String, String>{
          'baseUrl': _baseUrl.text.trim(),
          'username': _username.text.trim(),
          'remotePath': _remotePath.text.trim(),
          'allowInsecureHttp': _allowInsecureHttp.toString(),
        });
        credentials['username'] = _username.text.trim();
        credentials['password'] = _password.text;
        break;
      case SyncProviderKind.s3:
        config.addAll(<String, String>{
          'endpoint': _endpoint.text.trim(),
          'bucket': _bucket.text.trim(),
          'region': _region.text.trim(),
          'prefix': _prefix.text.trim(),
          'pathStyle': _pathStyle.toString(),
          'allowInsecureHttp': _allowInsecureHttp.toString(),
        });
        credentials.addAll(<String, String>{
          'accessKey': _accessKey.text.trim(),
          'secretKey': _secretKey.text,
          if (_sessionToken.text.trim().isNotEmpty)
            'sessionToken': _sessionToken.text.trim(),
        });
        break;
      case SyncProviderKind.sftp:
        config.addAll(<String, String>{
          'host': _host.text.trim(),
          'port': _port.text.trim(),
          'username': _username.text.trim(),
          'remotePath': _remotePath.text.trim(),
        });
        credentials['password'] = _password.text;
        break;
      case SyncProviderKind.rahaServer:
      case SyncProviderKind.customHttp:
        config.addAll(<String, String>{
          'baseUrl': _baseUrl.text.trim(),
          'allowInsecureHttp': _allowInsecureHttp.toString(),
        });
        credentials['token'] = _token.text.trim();
        break;
      case SyncProviderKind.localOnly:
      case SyncProviderKind.manualFile:
      case SyncProviderKind.googleDrive:
      case SyncProviderKind.oneDrive:
      case SyncProviderKind.dropbox:
      case SyncProviderKind.iCloud:
      case SyncProviderKind.peerToPeer:
        break;
    }
    Navigator.of(context).pop(
      SyncConnectionDraft(
        name: _name.text.trim(),
        kind: widget.kind,
        purpose: _purpose,
        config: config,
        credentials: credentials,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(_kindIcon(widget.kind))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('افزودن اتصال', 'Add connection'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(_kindLabel(widget.kind)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _field(
              _name,
              t('نام اتصال', 'Connection name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            if (_supportsRecordSync) ...[
              Text(
                t('کاربرد اتصال', 'Connection purpose'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<SyncTargetPurpose>(
                segments: <ButtonSegment<SyncTargetPurpose>>[
                  ButtonSegment<SyncTargetPurpose>(
                    value: SyncTargetPurpose.sync,
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(t('سینک', 'Sync')),
                  ),
                  ButtonSegment<SyncTargetPurpose>(
                    value: SyncTargetPurpose.backup,
                    icon: const Icon(Icons.backup_rounded),
                    label: Text(t('پشتیبان', 'Backup')),
                  ),
                  ButtonSegment<SyncTargetPurpose>(
                    value: SyncTargetPurpose.both,
                    icon: const Icon(Icons.all_inclusive_rounded),
                    label: Text(t('هر دو', 'Both')),
                  ),
                ],
                selected: <SyncTargetPurpose>{_purpose},
                onSelectionChanged: (values) =>
                    setState(() => _purpose = values.first),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'سینک رکوردی افزایشی فقط تغییرات جدید را جابه‌جا می‌کند؛ پشتیبان یک فایل بازیابی رمزگذاری‌شده جداگانه است.',
                  'Incremental record sync moves only new changes; backup is a separate encrypted recovery package.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.backup_rounded),
                title: Text(
                  t(
                    'کاربرد این اتصال: پشتیبان رمزگذاری‌شده',
                    'Connection purpose: encrypted backup',
                  ),
                ),
                subtitle: Text(
                  t(
                    'WebDAV، S3 و SFTP در این نسخه مقصد پشتیبان هستند؛ سینک رکوردی به API سازگار رها سینک نیاز دارد.',
                    'WebDAV, S3 and SFTP are backup targets in this release; record sync requires a Raha Sync-compatible API.',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ..._providerFields(),
            if (widget.kind == SyncProviderKind.webDav ||
                widget.kind == SyncProviderKind.nextcloud ||
                widget.kind == SyncProviderKind.s3 ||
                widget.kind == SyncProviderKind.rahaServer ||
                widget.kind == SyncProviderKind.customHttp) ...[
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(t('اجازه HTTP بدون TLS', 'Allow HTTP without TLS')),
                subtitle: Text(
                  t(
                    'خاموش بماند؛ فقط برای شبکه محلی مورد اعتماد روشن کنید. HTTPS حالت پیش‌فرض است.',
                    'Keep this off; enable it only on a trusted local network. HTTPS is the default.',
                  ),
                ),
                value: _allowInsecureHttp,
                onChanged: (value) =>
                    setState(() => _allowInsecureHttp = value),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(t('نمایش اطلاعات محرمانه', 'Show secret values')),
              value: _showSecrets,
              onChanged: (value) => setState(() => _showSecrets = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(t('ذخیره اتصال', 'Save connection')),
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(SyncProviderKind kind) => switch (kind) {
    SyncProviderKind.webDav => 'WebDAV',
    SyncProviderKind.nextcloud => 'Nextcloud / ownCloud',
    SyncProviderKind.s3 => 'S3-compatible',
    SyncProviderKind.sftp => 'SFTP',
    SyncProviderKind.rahaServer => 'Raha Sync Server',
    SyncProviderKind.customHttp => 'Custom HTTPS API',
    _ => kind.name,
  };

  IconData _kindIcon(SyncProviderKind kind) => switch (kind) {
    SyncProviderKind.webDav ||
    SyncProviderKind.nextcloud => Icons.cloud_sync_rounded,
    SyncProviderKind.s3 => Icons.storage_rounded,
    SyncProviderKind.sftp => Icons.dns_rounded,
    SyncProviderKind.rahaServer => Icons.hub_rounded,
    SyncProviderKind.customHttp => Icons.api_rounded,
    _ => Icons.cloud_rounded,
  };
}
