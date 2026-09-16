// Run with: flutter test test/ui_capture_test.dart
// Captures real Flutter widgets with isolated demonstration data.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/app/theme.dart';
import 'package:raha_life/app/shell/responsive_shell.dart';
import 'package:raha_life/core/settings/app_settings.dart';
import 'package:raha_life/core/notifications/agenda.dart';
import 'package:raha_life/core/notifications/reminder_models.dart';
import 'package:raha_life/features/dashboard/presentation/today_screen.dart';
import 'package:raha_life/features/sync/presentation/sync_controller.dart';
import 'package:raha_life/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final variant in ['mobile-light', 'mobile-dark', 'desktop-light']) {
    testWidgets('Render $variant with bundled Persian font', (tester) async {
      debugDisableShadows = false;
      await tester.runAsync(() async {
        final loader = FontLoader('Vazirmatn')
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn.ttf'));
        await loader.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(
        variant.startsWith('mobile') ? 390 : 1440,
        1000,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final now = DateTime.now();
      final sample = [
        AgendaItem(
          'demo1',
          'مرور برنامهٔ هفته',
          DateTime(now.year, now.month, now.day, 9),
          '/today',
          const ReminderPlan(),
          done: true,
        ),
        AgendaItem(
          'demo2',
          'پیاده‌روی عصرگاهی',
          DateTime(now.year, now.month, now.day, 18),
          '/today',
          const ReminderPlan(),
          type: 'habit',
        ),
        AgendaItem(
          'demo3',
          'خرید خانه',
          DateTime(now.year, now.month, now.day, 19),
          '/today',
          const ReminderPlan(),
          type: 'shopping',
        ),
      ];
      final router = GoRouter(
        initialLocation: '/today',
        routes: [
          ShellRoute(
            builder: (c, s, child) => ResponsiveShell(child: child),
            routes: [
              GoRoute(path: '/today', builder: (c, s) => const TodayScreen()),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaProvider.overrideWith((ref) => Stream.value(sample)),
            syncSettingsProvider.overrideWith(
              (ref) => SyncSettingsNotifier(boot: false),
            ),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              locale: const Locale('fa'),
              theme: buildLightTheme(
                locale: const Locale('fa'),
                accent: AccentChoice.emerald,
              ),
              darkTheme: buildDarkTheme(
                locale: const Locale('fa'),
                accent: AccentChoice.emerald,
              ),
              themeMode: variant.endsWith('dark')
                  ? ThemeMode.dark
                  : ThemeMode.light,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/ui/$variant.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
