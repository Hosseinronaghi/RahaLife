import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raha_life/features/sync/presentation/sync_center_screen.dart';
import 'package:raha_life/features/sync/presentation/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/core/database/app_database.dart';
import 'package:raha_life/core/persistence/attachments.dart';
import 'package:raha_life/core/persistence/drift_entity_repository.dart';
import 'package:raha_life/features/files/files_screen.dart';
import 'package:raha_life/features/entertainment/entertainment_screen.dart';
import 'package:raha_life/l10n/generated/app_localizations.dart';

void main() {
  for (final width in [360.0, 800.0, 1280.0]) {
    for (final page in ['files', 'entertainment', 'sync']) {
      testWidgets('$page opens with Persian large text at $width', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final repo = DriftEntityRepository(database: db);
        addTearDown(db.close);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
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
            home: page == 'files'
                ? FilesScreen(
                    attachmentStore: AttachmentStore(repository: repo),
                  )
                : page == 'sync'
                ? ProviderScope(
                    overrides: [
                      syncSettingsProvider.overrideWith(
                        (ref) => SyncSettingsNotifier(boot: false),
                      ),
                    ],
                    child: const SyncCenterScreen(),
                  )
                : EntertainmentScreen(repository: repo),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page == 'files') {
          expect(find.text('ضبط صدا'), findsOneWidget);
          expect(find.text('افزودن فایل'), findsOneWidget);
        } else if (page == 'sync') {
          expect(find.text('WebDAV'), findsNothing);
          expect(find.text('همگام‌سازی خودکار'), findsOneWidget);
          expect(
            tester
                .widgetList<Switch>(find.byType(Switch))
                .every((w) => w.onChanged == null),
            isTrue,
          );
        } else {
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          Navigator.pop(tester.element(find.byType(BottomSheet)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
