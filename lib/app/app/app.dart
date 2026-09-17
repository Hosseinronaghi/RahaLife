import '../features/sync/presentation/synced_feature_refresh.dart';
import '../core/notifications/agenda.dart';
import '../core/notifications/reminder_coordinator.dart';
import '../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:home_widget/home_widget.dart';

import '../core/notifications/reminder_service.dart';
import '../core/settings/app_settings.dart';
import '../features/sync/presentation/sync_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class RahaLifeApp extends ConsumerStatefulWidget {
  const RahaLifeApp({super.key});

  @override
  ConsumerState<RahaLifeApp> createState() => _RahaLifeAppState();
}

class _RahaLifeAppState extends ConsumerState<RahaLifeApp>
    with WidgetsBindingObserver {
  final _reminders = ReminderCoordinator();
  StreamSubscription<Uri?>? _widgetClickSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ReminderService.instance.selectedPayload.addListener(_handleReminderTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleReminderTap());
    unawaited(_initializeWidgetLaunchHandling());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncSettingsProvider.notifier);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(agendaProvider);
      final sync = ref.read(syncSettingsProvider.notifier);
      unawaited(sync.runAutoSyncIfEnabled());
      unawaited(sync.runAutoBackupIfDue());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ReminderService.instance.selectedPayload.removeListener(_handleReminderTap);
    _widgetClickSubscription?.cancel();
    _reminders.dispose();
    super.dispose();
  }

  bool get _supportsHomeWidget =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initializeWidgetLaunchHandling() async {
    if (!_supportsHomeWidget) return;
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetUri,
    );
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) _handleWidgetUri(initialUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final target = uri.host.isNotEmpty
        ? uri.host
        : uri.path.replaceFirst('/', '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      switch (target) {
        case 'affairs':
          router.go('/module/affair');
          break;
        case 'medication':
          router.go('/medication');
          break;
        case 'appointment':
          router.go('/module/appointment');
          break;
        case 'shopping':
          router.go('/shopping');
          break;
        case 'birthday':
          router.go('/module/birthday');
          break;
        case 'quick-add':
          router.go('/quick-add');
          break;
        default:
          router.go('/today');
          break;
      }
    });
  }

  void _handleReminderTap() {
    final payload = ReminderService.instance.consumeSelectedPayload();
    if (payload == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      if (payload.startsWith('route:')) {
        router.go(payload.substring(6));
      } else if (payload.startsWith('shopping:')) {
        final id = payload.substring('shopping:'.length);
        router.go('/shopping/$id');
      } else if (payload.startsWith('bill:')) {
        router.go('/finance');
      } else if (payload.startsWith('cycle:')) {
        router.go('/cycle');
      } else if (payload.startsWith('medication:')) {
        router.go('/medication');
      } else {
        router.go('/today');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(agendaProvider, (_, next) {
      if (next.hasValue) _reminders.update(next.value!);
    });
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: buildLightTheme(
        locale: settings.locale,
        accent: settings.accentChoice,
      ),
      darkTheme: buildDarkTheme(
        locale: settings.locale,
        accent: settings.accentChoice,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        final mediaQuery = MediaQuery.maybeOf(context);
        Widget content = child ?? const SizedBox.shrink();
        if (mediaQuery != null) {
          content = MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(
                mediaQuery.textScaler.scale(14) / 14 * settings.textScale,
              ),
            ),
            child: content,
          );
        }
        return Directionality(
          textDirection: locale.languageCode == 'fa'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Stack(
            children: [
              content,
              ValueListenableBuilder<String?>(
                valueListenable: WriteStatus.error,
                builder: (c, error, _) => error == null
                    ? const SizedBox.shrink()
                    : Positioned(
                        left: 12,
                        right: 12,
                        bottom: 90,
                        child: Material(
                          color: Theme.of(c).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(error),
                                TextButton(
                                  onPressed: () {
                                    WriteStatus.error.value = null;
                                    invalidateSyncedFeatureProviders(ref);
                                  },
                                  child: Text(
                                    locale.languageCode == 'fa'
                                        ? 'بارگذاری دوبارهٔ اطلاعات'
                                        : 'Reload stored data',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: WriteStatus.loading,
                builder: (c, count, _) => count == 0
                    ? const SizedBox.shrink()
                    : const Positioned.fill(
                        child: AbsorbPointer(
                          child: ColoredBox(
                            color: Color(0x44000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
      routerConfig: router,
    );
  }
}
