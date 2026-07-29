import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  void initState() {
    super.initState();
    ReminderService.instance.selectedPayload.addListener(_handleReminderTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleReminderTap());
  }

  @override
  void dispose() {
    ReminderService.instance.selectedPayload.removeListener(_handleReminderTap);
    super.dispose();
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
