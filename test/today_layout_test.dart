import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/notifications/agenda.dart';
import 'package:raha_life/features/dashboard/presentation/today_screen.dart';
import 'package:raha_life/features/sync/presentation/sync_controller.dart';
import 'package:raha_life/l10n/generated/app_localizations.dart';

void main() {
  for (final width in [360.0, 800.0, 1280.0]) {
    testWidgets('Today RTL at $width with large text has no layout exception', (
      tester,
    ) async {
      final handler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        handler?.call(details);
      };
      addTearDown(() => FlutterError.onError = handler);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaProvider.overrideWith((ref) => Stream.value([])),
            syncSettingsProvider.overrideWith(
              (ref) => SyncSettingsNotifier(boot: false),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
