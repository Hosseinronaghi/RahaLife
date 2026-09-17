import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/sync/providers/backup_target.dart';
import '../domain/sync_settings.dart';
import 'sync_conflicts_sheet.dart';
import 'sync_controller.dart';
import 'widgets/sync_connection_sheet.dart';

class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  bool _fa(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'fa';

  String _t(BuildContext context, String fa, String en) =>
      _fa(context) ? fa : en;

  bool get _canShareBackupFile =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.linux;

  bool _canRecordSync(SyncConnectionProfile connection) =>
      connection.enabled &&
      (connection.kind == SyncProviderKind.rahaServer ||
          connection.kind == SyncProviderKind.customHttp) &&
      (connection.purpose == SyncTargetPurpose.sync ||
          connection.purpose == SyncTargetPurpose.both);

  bool _canBackup(SyncConnectionProfile connection) =>
      connection.enabled &&
      (connection.purpose == SyncTargetPurpose.backup ||
          connection.purpose == SyncTargetPurpose.both) &&
      switch (connection.kind) {
        SyncProviderKind.webDav ||
        SyncProviderKind.nextcloud ||
        SyncProviderKind.s3 ||
        SyncProviderKind.sftp ||
        SyncProviderKind.rahaServer ||
        SyncProviderKind.customHttp => true,
        _ => false,
      };

  Future<void> _showResult(
    BuildContext context, {
    required bool success,
    required String successFa,
    required String successEn,
    String? failureDetails,
  }) async {
    if (!context.mounted) return;
    final message = success
        ? _t(context, successFa, successEn)
        : _t(
            context,
            'عملیات انجام نشد. تنظیمات اتصال و کلید بازیابی را بررسی کنید.',
            'The operation could not be completed. Check the connection and recovery key.',
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: !success && failureDetails != null && failureDetails.isNotEmpty
            ? SnackBarAction(
                label: _t(context, 'جزئیات', 'Details'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(
                        _t(context, 'جزئیات فنی', 'Technical details'),
                      ),
                      content: SelectableText(failureDetails),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(_t(context, 'بستن', 'Close')),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Future<void> _addConnection(
    BuildContext context,
    WidgetRef ref,
    SyncProviderKind kind,
  ) async {
    if (kIsWeb && kind == SyncProviderKind.sftp) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_t(context, 'SFTP در نسخه وب', 'SFTP on web')),
          content: Text(
            _t(
              context,
              'مرورگر اجازه اتصال مستقیم TCP/SSH نمی‌دهد. SFTP در Android، iPhone، Windows، macOS و Linux فعال است. برای وب از WebDAV، S3 یا HTTPS API استفاده کنید.',
              'Browsers cannot open direct TCP/SSH connections. SFTP is available on Android, iPhone, Windows, macOS and Linux. Use WebDAV, S3 or HTTPS API on web.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t(context, 'متوجه شدم', 'Got it')),
            ),
          ],
        ),
      );
      return;
    }
    final draft = await showSyncConnectionSheet(context, kind: kind);
    if (draft == null || !context.mounted) return;
    final notifier = ref.read(syncSettingsProvider.notifier);
    final id = await notifier.addConnection(
      name: draft.name,
      kind: draft.kind,
      purpose: draft.purpose,
      config: draft.config,
      credentials: draft.credentials,
    );
    final result = await notifier.testConnection(id);
    if (!context.mounted) return;
    await _showResult(
      context,
      success: result.success,
      successFa: 'اتصال ذخیره شد و آزمایش اتصال موفق بود.',
      successEn: 'Connection saved and tested successfully.',
      failureDetails: result.message,
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncSettingsProvider.notifier);
    final ok = await notifier.exportEncryptedBackup();
    if (!context.mounted) return;
    await _showResult(
      context,
      success: ok,
      successFa: 'پشتیبان رمزگذاری‌شده ذخیره شد.',
      successEn: 'Encrypted backup saved.',
      failureDetails: ref.read(syncSettingsProvider).lastActionMessage,
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'بازیابی پشتیبان', 'Restore backup')),
        content: Text(
          _t(
            context,
            'اطلاعات موجود با داده‌های فایل پشتیبان ادغام/جایگزین می‌شوند. شناسه این دستگاه حفظ خواهد شد. پس از بازیابی بهتر است برنامه را یک‌بار ببندید و دوباره باز کنید.',
            'Current data will be merged/replaced with the backup data. This device ID is preserved. Restart the app after restoring.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(context, 'انصراف', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t(context, 'ادامه', 'Continue')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(syncSettingsProvider.notifier);
    final ok = await notifier.importEncryptedBackup();
    if (!context.mounted) return;
    await _showResult(
      context,
      success: ok,
      successFa: 'پشتیبان بازیابی شد. برنامه را یک‌بار دوباره باز کنید.',
      successEn: 'Backup restored. Restart the app once.',
      failureDetails: ref.read(syncSettingsProvider).lastActionMessage,
    );
  }

  Future<void> _showRecoveryKey(BuildContext context, WidgetRef ref) async {
    final key = await ref
        .read(syncSettingsProvider.notifier)
        .exportRecoveryKey();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'کلید بازیابی', 'Recovery key')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(
                context,
                'این کلید برای بازکردن پشتیبان‌های رمزگذاری‌شده روی دستگاه جدید لازم است. آن را در جای امن نگه دارید و برای دیگران نفرستید.',
                'This key is required to open encrypted backups on a new device. Store it safely and do not share it.',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(key),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: key));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(_t(context, 'کپی', 'Copy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_t(context, 'بستن', 'Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _importRecoveryKey(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _t(context, 'واردکردن کلید بازیابی', 'Import recovery key'),
        ),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _t(context, 'کلید بازیابی', 'Recovery key'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_t(context, 'انصراف', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(_t(context, 'واردکردن', 'Import')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty || !context.mounted) return;
    final ok = await ref
        .read(syncSettingsProvider.notifier)
        .importRecoveryKey(value);
    if (!context.mounted) return;
    await _showResult(
      context,
      success: ok,
      successFa: 'کلید بازیابی روی این دستگاه ثبت شد.',
      successEn: 'Recovery key imported on this device.',
      failureDetails: ref.read(syncSettingsProvider).lastActionMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncSettingsProvider);
    final notifier = ref.read(syncSettingsProvider.notifier);
    final locale = Localizations.localeOf(context);
    final busy = state.busyConnectionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'داده و همگام‌سازی', 'Data & sync')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _HeroCard(
            title: _t(
              context,
              'اطلاعات شما، در اختیار خودتان',
              'Your data stays under your control',
            ),
            body: _t(
              context,
              'رها لایف Local-first است. بدون اینترنت کار می‌کند و برای پشتیبان یا همگام‌سازی می‌توانید فضای ابری یا سرور شخصی خودتان را انتخاب کنید.',
              'Raha Life is local-first. It works offline and lets you choose your own cloud or personal server for backup and sync.',
            ),
            deviceId: state.deviceId,
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(context, 'حالت نگهداری داده', 'Data mode'),
            icon: Icons.shield_outlined,
            child: SegmentedButton<PersonalSyncStrategy>(
              segments: [
                ButtonSegment(
                  value: PersonalSyncStrategy.localOnly,
                  icon: const Icon(Icons.phone_android_rounded),
                  label: Text(_t(context, 'فقط دستگاه', 'Device only')),
                ),
                ButtonSegment(
                  value: PersonalSyncStrategy.encryptedBackup,
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(_t(context, 'پشتیبان', 'Backup')),
                ),
                ButtonSegment(
                  value: PersonalSyncStrategy.providerBased,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(_t(context, 'اتصال‌ها', 'Providers')),
                ),
              ],
              selected: <PersonalSyncStrategy>{state.strategy},
              onSelectionChanged: (values) =>
                  notifier.setStrategy(values.first),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(context, 'پشتیبان رمزگذاری‌شده', 'Encrypted backup'),
            icon: Icons.enhanced_encryption_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t(
                    context,
                    'فایل .rahabackup شامل داده‌های فعلی رها لایف است و قبل از خروج از دستگاه با AES-256-GCM رمزگذاری می‌شود.',
                    'The .rahabackup file contains current Raha Life data and is encrypted with AES-256-GCM before it leaves the device.',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _exportBackup(context, ref),
                      icon: const Icon(Icons.save_alt_rounded),
                      label: Text(_t(context, 'ساخت پشتیبان', 'Create backup')),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => _importBackup(context, ref),
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(_t(context, 'بازیابی', 'Restore')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showRecoveryKey(context, ref),
                      icon: const Icon(Icons.key_rounded),
                      label: Text(_t(context, 'کلید بازیابی', 'Recovery key')),
                    ),
                    TextButton.icon(
                      onPressed: () => _importRecoveryKey(context, ref),
                      icon: const Icon(Icons.key_off_outlined),
                      label: Text(_t(context, 'ورود کلید', 'Import key')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(context, 'فضای ابری شخصی', 'Personal cloud'),
            icon: Icons.cloud_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t(
                    context,
                    'بدون نیاز به سرور رها، فایل پشتیبان را از پنجره ذخیره سیستم مستقیماً در Google Drive، OneDrive، Dropbox یا iCloud خودتان قرار دهید. اگر سرویس به Files سیستم متصل باشد، همین حالا قابل استفاده است.',
                    'Without any Raha server, save the encrypted backup through the system file picker directly to your Google Drive, OneDrive, Dropbox or iCloud when that service is available in the OS file picker.',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CloudChip(
                      icon: Icons.cloud_rounded,
                      label: 'Google Drive',
                    ),
                    _CloudChip(icon: Icons.window_rounded, label: 'OneDrive'),
                    _CloudChip(
                      icon: Icons.inventory_2_outlined,
                      label: 'Dropbox',
                    ),
                    _CloudChip(icon: Icons.apple_rounded, label: 'iCloud'),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _exportBackup(context, ref),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(
                    _t(context, 'انتخاب محل ذخیره', 'Choose save location'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    context,
                    'اتصال خودکار OAuth به این سرویس‌ها به Client ID انتشار هر سرویس نیاز دارد؛ تا قبل از ثبت آن، گزینه دستی بالا امن و فعال است.',
                    'Automatic OAuth integration needs published app client IDs for each provider. Until those are registered, the secure manual option above is fully usable.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(context, 'سرور و فضای شخصی', 'Personal server & storage'),
            icon: Icons.dns_rounded,
            child: Column(
              children: [
                _ProviderAddTile(
                  icon: Icons.cloud_sync_rounded,
                  title: 'WebDAV',
                  subtitle: _t(
                    context,
                    'هاست، NAS و سرویس‌های WebDAV',
                    'Hosting, NAS and WebDAV services',
                  ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.webDav),
                ),
                _ProviderAddTile(
                  icon: Icons.cloud_circle_outlined,
                  title: 'Nextcloud / ownCloud',
                  subtitle: _t(
                    context,
                    'فضای شخصی یا سازمانی شما',
                    'Your personal or organization cloud',
                  ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.nextcloud),
                ),
                _ProviderAddTile(
                  icon: Icons.storage_rounded,
                  title: 'S3-compatible',
                  subtitle: _t(
                    context,
                    'MinIO، NAS و Object Storage سازگار',
                    'MinIO, NAS and compatible object storage',
                  ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.s3),
                ),
                _ProviderAddTile(
                  icon: Icons.terminal_rounded,
                  title: 'SFTP',
                  subtitle: kIsWeb
                      ? _t(
                          context,
                          'در مرورگر غیرفعال؛ در اپ‌های Native فعال است',
                          'Unavailable in browser; available in native apps',
                        )
                      : _t(
                          context,
                          'مناسب پشتیبان روی VPS/NAS',
                          'Backup to VPS/NAS',
                        ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.sftp),
                ),
                _ProviderAddTile(
                  icon: Icons.hub_rounded,
                  title: 'Raha Sync Server',
                  subtitle: _t(
                    context,
                    'نسخه قابل نصب روی VPS/NAS/هاست شخصی',
                    'Self-hosted edition for VPS/NAS/personal hosting',
                  ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.rahaServer),
                ),
                _ProviderAddTile(
                  icon: Icons.api_rounded,
                  title: 'Custom HTTPS API',
                  subtitle: _t(
                    context,
                    'برای Gateway یا API سازگار شخصی',
                    'For your compatible gateway or API',
                  ),
                  onTap: () =>
                      _addConnection(context, ref, SyncProviderKind.customHttp),
                ),
              ],
            ),
          ),
          if (state.connections.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: _t(context, 'اتصال‌های من', 'My connections'),
              icon: Icons.cable_rounded,
              child: Column(
                children: [
                  for (final connection in state.connections)
                    _ConnectionTile(
                      connection: connection,
                      busy: state.busyConnectionId == connection.id,
                      fa: _fa(context),
                      canSync: _canRecordSync(connection),
                      canBackup: _canBackup(connection),
                      onEnabled: (value) =>
                          notifier.setConnectionEnabled(connection.id, value),
                      onPrimary: () =>
                          notifier.setPrimaryConnection(connection.id),
                      onTest: () async {
                        final result = await notifier.testConnection(
                          connection.id,
                        );
                        if (!context.mounted) return;
                        await _showResult(
                          context,
                          success: result.success,
                          successFa: 'اتصال با موفقیت برقرار شد.',
                          successEn: 'Connection test succeeded.',
                          failureDetails: result.message,
                        );
                      },
                      onSync: () async {
                        final result = await notifier.syncConnection(
                          connection.id,
                        );
                        if (!context.mounted) return;
                        final latestState = ref.read(syncSettingsProvider);
                        final uploaded = result?.uploaded ?? 0;
                        final downloaded = result?.downloaded ?? 0;
                        final conflicts =
                            result?.conflicts ?? latestState.conflicts;
                        final countsFa =
                            '${localizeDigits(uploaded, locale)} ارسال، '
                            '${localizeDigits(downloaded, locale)} دریافت، '
                            '${localizeDigits(conflicts, locale)} تعارض';
                        final countsEn =
                            '$uploaded uploaded, $downloaded downloaded, '
                            '$conflicts conflicts';
                        await _showResult(
                          context,
                          success: result != null,
                          successFa: 'همگام‌سازی انجام شد: $countsFa',
                          successEn: 'Sync completed: $countsEn',
                          failureDetails: latestState.lastActionMessage,
                        );
                      },
                      onBackup: () async {
                        final ok = await notifier.backupToConnection(
                          connection.id,
                        );
                        if (!context.mounted) return;
                        await _showResult(
                          context,
                          success: ok,
                          successFa:
                              'پشتیبان رمزگذاری‌شده روی این مقصد ذخیره شد.',
                          successEn:
                              'Encrypted backup uploaded to this target.',
                          failureDetails: ref
                              .read(syncSettingsProvider)
                              .lastActionMessage,
                        );
                      },
                      onRestore: () async {
                        final ok = await notifier.restoreLatestFromConnection(
                          connection.id,
                        );
                        if (!context.mounted) return;
                        await _showResult(
                          context,
                          success: ok,
                          successFa:
                              'آخرین پشتیبان بازیابی شد. برنامه را دوباره باز کنید.',
                          successEn: 'Latest backup restored. Restart the app.',
                          failureDetails: ref
                              .read(syncSettingsProvider)
                              .lastActionMessage,
                        );
                      },
                      onDelete: () => notifier.removeConnection(connection.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _t(
                context,
                'همگام‌سازی و پشتیبان خودکار',
                'Automatic sync & backup',
              ),
              icon: Icons.autorenew_rounded,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _t(
                        context,
                        'سینک خودکار تغییرات',
                        'Automatic change sync',
                      ),
                    ),
                    subtitle: Text(
                      _t(
                        context,
                        'هنگام بازشدن و بازگشت به برنامه، فقط تغییرات جدید با سرور/API سازگار Push/Pull می‌شوند.',
                        'When the app opens or resumes, only new changes are pushed/pulled through a compatible server/API.',
                      ),
                    ),
                    value: state.autoSync,
                    onChanged: notifier.setAutoSync,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _t(
                        context,
                        'پشتیبان خودکار دوره‌ای',
                        'Periodic automatic backup',
                      ),
                    ),
                    subtitle: Text(
                      _t(
                        context,
                        'در صورت گذشت حداقل ۶ ساعت، یک پشتیبان رمزگذاری‌شده روی مقصدهای Backup ساخته می‌شود.',
                        'After at least 6 hours, an encrypted recovery backup is created on enabled backup targets.',
                      ),
                    ),
                    value: state.autoBackup,
                    onChanged: notifier.setAutoBackup,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _t(
                        context,
                        'فقط Wi-Fi / شبکه ثابت',
                        'Wi-Fi / Ethernet only',
                      ),
                    ),
                    value: state.wifiOnly,
                    onChanged: state.autoBackup || state.autoSync
                        ? notifier.setWifiOnly
                        : null,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await notifier.syncAllEnabled();
                                  if (!context.mounted) return;
                                  await _showResult(
                                    context,
                                    success: ok,
                                    successFa:
                                        'سینک افزایشی روی اتصال‌های فعال اجرا شد.',
                                    successEn:
                                        'Incremental sync ran on enabled connections.',
                                    failureDetails: ref
                                        .read(syncSettingsProvider)
                                        .lastActionMessage,
                                  );
                                },
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(_t(context, 'سینک اکنون', 'Sync now')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await notifier.backupAllEnabled();
                                  if (!context.mounted) return;
                                  await _showResult(
                                    context,
                                    success: ok,
                                    successFa:
                                        'پشتیبان روی مقصدهای فعال اجرا شد.',
                                    successEn: 'Backup ran on enabled targets.',
                                    failureDetails: ref
                                        .read(syncSettingsProvider)
                                        .lastActionMessage,
                                  );
                                },
                          icon: const Icon(Icons.backup_rounded),
                          label: Text(
                            _t(context, 'پشتیبان اکنون', 'Back up now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(
              context,
              'انتقال دستگاه به دستگاه',
              'Device-to-device transfer',
            ),
            icon: Icons.mobile_friendly_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t(
                    context,
                    'برای انتقال بدون سرور، روی دستگاه قدیمی پشتیبان رمزگذاری‌شده بسازید، فایل را با روش دلخواه منتقل کنید و روی دستگاه جدید ابتدا همان کلید بازیابی و سپس فایل را وارد کنید.',
                    'For serverless transfer, create an encrypted backup on the old device, transfer the file by any method, then import the same recovery key and backup on the new device.',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => _exportBackup(context, ref),
                      icon: const Icon(Icons.send_to_mobile_rounded),
                      label: Text(
                        _t(context, 'ساخت فایل انتقال', 'Create transfer file'),
                      ),
                    ),
                    if (_canShareBackupFile)
                      FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () async {
                                final ok = await notifier
                                    .shareEncryptedBackup();
                                if (!context.mounted) return;
                                await _showResult(
                                  context,
                                  success: ok,
                                  successFa: 'پنجره اشتراک فایل انتقال باز شد.',
                                  successEn:
                                      'The transfer-file share sheet was opened.',
                                  failureDetails: ref
                                      .read(syncSettingsProvider)
                                      .lastActionMessage,
                                );
                              },
                        icon: const Icon(Icons.share_rounded),
                        label: Text(
                          _t(
                            context,
                            'اشتراک فایل انتقال',
                            'Share transfer file',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _t(context, 'این دستگاه', 'This device'),
            icon: Icons.devices_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.devices_rounded),
                  ),
                  title: Text(_platformLabel(context)),
                  subtitle: Text(
                    state.deviceId.isEmpty
                        ? '…'
                        : state.deviceId.substring(
                            0,
                            state.deviceId.length > 8
                                ? 8
                                : state.deviceId.length,
                          ),
                  ),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                  ),
                ),
                if (state.lastSyncAt != null)
                  Text(
                    '${_t(context, 'آخرین سینک', 'Last sync')}: '
                    '${compactDualDate(state.lastSyncAt!.toLocal(), locale)} • '
                    '${localizedTime(state.lastSyncAt!.toLocal(), locale)}',
                  ),
                if (state.lastBackupAt != null)
                  Text(
                    '${_t(context, 'آخرین پشتیبان', 'Last backup')}: '
                    '${compactDualDate(state.lastBackupAt!.toLocal(), locale)} • '
                    '${localizedTime(state.lastBackupAt!.toLocal(), locale)}',
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.outbox_rounded, size: 18),
                      label: Text(
                        '${_t(context, 'تغییرات در صف', 'Pending changes')}: '
                        '${localizeDigits(state.pendingChanges, locale)}',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.merge_type_rounded, size: 18),
                      label: Text(
                        '${_t(context, 'تعارض‌ها', 'Conflicts')}: '
                        '${localizeDigits(state.conflicts, locale)}',
                      ),
                      onPressed: state.conflicts > 0
                          ? () => showSyncConflictsSheet(context, ref)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('Android')),
                    Chip(label: Text('iPhone / iOS')),
                    Chip(label: Text('Windows')),
                    Chip(label: Text('macOS')),
                    Chip(label: Text('Linux')),
                    Chip(label: Text('Web')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ArchitectureNote(fa: _fa(context)),
        ],
      ),
    );
  }

  String _platformLabel(BuildContext context) {
    if (kIsWeb) return _t(context, 'نسخه وب', 'Web app');
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iPhone / iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.body,
    required this.deviceId,
  });

  final String title;
  final String body;
  final String deviceId;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(body),
              if (deviceId.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${Localizations.localeOf(context).languageCode == 'fa' ? 'دستگاه' : 'Device'} ${deviceId.substring(0, deviceId.length > 8 ? 8 : deviceId.length)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _CloudChip extends StatelessWidget {
  const _CloudChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _ProviderAddTile extends StatelessWidget {
  const _ProviderAddTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.add_circle_outline_rounded),
    onTap: onTap,
  );
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.connection,
    required this.busy,
    required this.fa,
    required this.canSync,
    required this.canBackup,
    required this.onEnabled,
    required this.onPrimary,
    required this.onTest,
    required this.onSync,
    required this.onBackup,
    required this.onRestore,
    required this.onDelete,
  });

  final SyncConnectionProfile connection;
  final bool busy;
  final bool fa;
  final bool canSync;
  final bool canBackup;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onPrimary;
  final VoidCallback onTest;
  final VoidCallback onSync;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  String t(String faText, String enText) => fa ? faText : enText;

  @override
  Widget build(BuildContext context) {
    final statusColor = connection.lastError == null
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connection.isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Icon(_providerIcon(connection.kind))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            connection.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (connection.isPrimary) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: statusColor,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${_providerLabel(connection.kind)} • ${_purposeLabel(connection.purpose)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: connection.enabled, onChanged: onEnabled),
            ],
          ),
          if (busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TextButton.icon(
                onPressed: busy ? null : onTest,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: Text(t('آزمایش', 'Test')),
              ),
              if (canSync)
                FilledButton.icon(
                  onPressed: busy ? null : onSync,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(t('سینک', 'Sync')),
                ),
              if (canBackup)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onBackup,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(t('پشتیبان', 'Backup')),
                ),
              if (canBackup)
                TextButton.icon(
                  onPressed: busy ? null : onRestore,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(t('بازیابی', 'Restore')),
                ),
              if (!connection.isPrimary)
                TextButton.icon(
                  onPressed: onPrimary,
                  icon: const Icon(Icons.star_outline_rounded),
                  label: Text(t('اصلی', 'Primary')),
                ),
              TextButton.icon(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('حذف', 'Remove')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _providerLabel(SyncProviderKind kind) => switch (kind) {
    SyncProviderKind.webDav => 'WebDAV',
    SyncProviderKind.nextcloud => 'Nextcloud',
    SyncProviderKind.s3 => 'S3',
    SyncProviderKind.sftp => 'SFTP',
    SyncProviderKind.rahaServer => 'Raha Sync Server',
    SyncProviderKind.customHttp => 'HTTPS API',
    _ => kind.name,
  };

  String _purposeLabel(SyncTargetPurpose purpose) => switch (purpose) {
    SyncTargetPurpose.sync => t('سینک', 'Sync'),
    SyncTargetPurpose.backup => t('پشتیبان', 'Backup'),
    SyncTargetPurpose.both => t('سینک و پشتیبان', 'Sync & backup'),
  };

  IconData _providerIcon(SyncProviderKind kind) => switch (kind) {
    SyncProviderKind.webDav ||
    SyncProviderKind.nextcloud => Icons.cloud_sync_rounded,
    SyncProviderKind.s3 => Icons.storage_rounded,
    SyncProviderKind.sftp => Icons.terminal_rounded,
    SyncProviderKind.rahaServer => Icons.hub_rounded,
    SyncProviderKind.customHttp => Icons.api_rounded,
    _ => Icons.cloud_rounded,
  };
}

class _ArchitectureNote extends StatelessWidget {
  const _ArchitectureNote({required this.fa});

  final bool fa;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fa
                  ? 'نکته: داده‌های اصلی اکنون در Drift ثبت می‌شوند و یک اتصال Live Sync فعال در هر لحظه فقط تغییرات جدید را با Cursor، Change ID، Tombstone و Conflict منتقل می‌کند. مقصدهای پشتیبان می‌توانند متعدد باشند. اگر سرور Live Sync را عوض کنید، تاریخچه تغییرات پایدار برای مقصد جدید بازپخش می‌شود؛ دیتابیس کامل جایگزین نمی‌شود. WebDAV، S3 و SFTP برای پشتیبان رمزگذاری‌شده هستند و اتصال مستقیم MySQL/PostgreSQL از کلاینت عمداً پشتیبانی نمی‌شود.'
                  : 'Note: primary data now lives in Drift. One live record-sync connection is active at a time and transfers only new changes using cursors, change IDs, tombstones and conflict tracking, while backup targets can be multiple. If you switch the live sync server, durable change history is replayed to the new target instead of replacing a whole database. WebDAV, S3 and SFTP are encrypted-backup targets, and direct client connections to MySQL/PostgreSQL are intentionally unsupported.',
            ),
          ),
        ],
      ),
    ),
  );
}
