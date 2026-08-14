import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:home_widget/home_widget.dart';

import '../core/notifications/reminder_service.dart';
import '../core/settings/app_settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class RahaLifeApp extends ConsumerStatefulWidget {
  const RahaLifeApp({super.key});

  @override
  ConsumerState<RahaLifeApp> createState() => _RahaLifeAppState();
}

class _RahaLifeAppState extends ConsumerState<RahaLifeApp> {
  StreamSubscription<Uri?>? _widgetClickSubscription;
  @override
  void initState() {
    super.initState();
    ReminderService.instance.selectedPayload.addListener(_handleReminderTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleReminderTap());
    unawaited(_initializeWidgetLaunchHandling());
  }

  @override
  void dispose() {
    ReminderService.instance.selectedPayload.removeListener(_handleReminderTap);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  bool get _supportsHomeWidget => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initializeWidgetLaunchHandling() async {
    if (!_supportsHomeWidget) return;
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) _handleWidgetUri(initialUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final target = uri.host.isNotEmpty ? uri.host : uri.path.replaceFirst('/', '');
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
      if (payload.startsWith('shopping:')) {
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
              textScaler: TextScaler.linear(settings.textScale),
            ),
            child: content,
          );
        }
        return Directionality(
          textDirection: locale.languageCode == 'fa'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: content,
        );
      },
      routerConfig: router,
    );
  }
}
