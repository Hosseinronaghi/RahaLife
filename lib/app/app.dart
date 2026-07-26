import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class RahaLifeApp extends ConsumerWidget {
  const RahaLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
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
        final textDirection = locale.languageCode == 'fa'
            ? TextDirection.rtl
            : TextDirection.ltr;
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
