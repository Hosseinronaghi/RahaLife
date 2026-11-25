import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/notes/domain/rich_note.dart';
import 'package:raha_life/features/notes/presentation/note_editor_screen.dart';
import 'package:raha_life/features/notes/presentation/notes_controller.dart';
import 'package:raha_life/features/people/presentation/people_controller.dart';
import 'package:raha_life/features/projects/presentation/projects_controller.dart';
import 'package:raha_life/l10n/generated/app_localizations.dart';

class DelayedNotes extends NotesNotifier {
  DelayedNotes() : super(persistenceEnabled: false);
  void deliver() => state = [
    RichNote(
      id: 'existing',
      title: 'Original title',
      deltaJson: jsonEncode([
        {'insert': 'Existing body\n'},
      ]),
      plainText: 'Existing body',
      updatedAt: DateTime.utc(2026),
    ),
  ];
}

void main() {
  testWidgets(
    'note editor waits for the record and preserves its body when changing the title',
    (tester) async {
      final notes = DelayedNotes();
      final scope = ProviderContainer(
        overrides: [
          notesProvider.overrideWith((ref) => notes),
          peopleProvider.overrideWith(
            (ref) => PeopleNotifier(persistenceEnabled: false),
          ),
          projectsProvider.overrideWith(
            (ref) => ProjectsNotifier(persistenceEnabled: false),
          ),
        ],
      );
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: NoteEditorScreen(noteId: 'existing'),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      notes.deliver();
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;
      expect(
        tester.widget<TextField>(field).controller?.text,
        'Original title',
      );
      await tester.enterText(field, 'Updated title');
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();
      final result = scope.read(notesProvider).single;
      expect(result.id, 'existing');
      expect(result.title, 'Updated title');
      expect(result.plainText, 'Existing body');
    },
  );
}
