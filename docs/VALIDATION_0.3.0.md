# Raha Life v0.3.0+6 — Validation report

## Static checks completed in the delivery environment

- `pubspec.yaml`, `l10n.yaml`, and both GitHub Actions workflow files parse as valid YAML.
- Persian and English ARB files parse as valid JSON.
- Persian and English localization files contain 238 identical active keys.
- All 210 localization references found in current Dart source files exist in both ARB files.
- Relative Dart imports resolve across 50 current Dart source files, excluding generated localization files that are created by Flutter.
- No reference to the deleted `MyApp` test class remains.
- No reference to the old `HomeEntryType.task` enum remains.
- Project version is `0.3.0+6`.
- Android build workflow includes Java 17, desugaring, and internet permission generation.
- Windows build remains pinned to `windows-2022`.
- Full and changed-files archives are checked after packaging.

## Test files included

- `test/money_test.dart`
- `test/locale_formatters_test.dart`
- `test/home_controller_test.dart`
- `test/people_controller_test.dart`
- `test/shopping_controller_test.dart`
- `test/medication_controller_test.dart`
- `test/finance_controller_test.dart`
- `test/cycle_controller_test.dart`

## Required GitHub verification

The current execution environment does not contain the Flutter SDK, so this report does not falsely claim a successful Flutter compile. GitHub Actions must perform the authoritative checks:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build web --release
```

If any GitHub job fails, the full failing step log remains the source of truth and should be used for the next patch.
