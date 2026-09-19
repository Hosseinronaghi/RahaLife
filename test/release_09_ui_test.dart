import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/app/theme.dart';
import 'package:raha_life/core/settings/app_settings.dart';
import 'package:raha_life/core/notifications/agenda.dart';
import 'package:raha_life/features/cycle/presentation/cycle_controller.dart';
import 'package:raha_life/features/cycle/presentation/cycle_screen.dart';
import 'package:raha_life/features/finance/presentation/finance_controller.dart';
import 'package:raha_life/features/finance/presentation/finance_screen.dart';
import 'package:raha_life/features/notes/presentation/notes_controller.dart';
import 'package:raha_life/features/notes/presentation/note_editor_screen.dart';
import 'package:raha_life/features/people/presentation/people_controller.dart';
import 'package:raha_life/features/people/presentation/people_screen.dart';
import 'package:raha_life/features/projects/presentation/projects_controller.dart';
import 'package:raha_life/l10n/generated/app_localizations.dart';

void main() {
  for (final width in [360.0, 800.0, 1280.0]) {
    for (final page in ['notes', 'people', 'finance', 'cycle']) {
      testWidgets('$page Persian large text at $width', (tester) async {
        await tester.runAsync(() async {
          final loader = FontLoader('Vazirmatn')
            ..addFont(rootBundle.load('assets/fonts/Vazirmatn.ttf'));
          await loader.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final notes = NotesNotifier(persistenceEnabled: false);
        final finance = FinanceNotifier(persistenceEnabled: false)
          ..addAccount('Cash', id: 'cash', openingBalance: 1200000);
        final people = PeopleNotifier(persistenceEnabled: false)
          ..add(
            name: 'سارا',
            relationship: 'دوست',
            birthDate: DateTime(2000, 1, 1),
          );
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notesProvider.overrideWith((ref) => notes),
              peopleProvider.overrideWith((ref) => people),
              financeProvider.overrideWith((ref) => finance),
              projectsProvider.overrideWith(
                (ref) => ProjectsNotifier(persistenceEnabled: false),
              ),
              cycleProvider.overrideWith(
                (ref) => CycleNotifier(persistenceEnabled: false),
              ),
              agendaProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: buildLightTheme(
                locale: const Locale('fa'),
                accent: AccentChoice.emerald,
              ),
              locale: const Locale('fa'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: key,
                child: switch (page) {
                  'notes' => const NoteEditorScreen(),
                  'people' => const PeopleScreen(),
                  'finance' => const FinanceScreen(),
                  _ => const CycleScreen(),
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page == 'notes') {
          await tester.enterText(
            find.byType(TextField).first,
            'یادداشت آزمایشی',
          );
          await tester.tap(find.byIcon(Icons.check_rounded));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.check_rounded));
          await tester.pumpAndSettle();
          expect(notes.state, hasLength(1));
          await tester.tap(find.byIcon(Icons.expand_more));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        tester.testTextInput.hide();
        await tester.pump(const Duration(seconds: 5));
        if (width == 360) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory('review/ui').createSync(recursive: true);
            File(
              'review/ui/$page-mobile.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (width == 360 && page != 'notes') {
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
