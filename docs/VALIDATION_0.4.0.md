# Raha Life v0.4.0+7 — Validation Report

## Static checks completed in the delivery environment

- 53 Dart source files inspected.
- 11 Dart test files present.
- English and Persian ARB files contain 328 matching localization keys.
- 300 localization references were checked; no missing keys were found.
- Placeholder metadata for localized parameterized messages matches the message placeholders.
- `pubspec.yaml`, `l10n.yaml`, and both GitHub Actions workflows parse as valid YAML.
- Relative Dart imports were checked, excluding generated localization output.
- Dart delimiter balance was checked across source and tests.
- No stale `MyApp` or `HomeEntryType.task` references were found.
- Android workflow includes desugaring, Java 17, exact-alarm/full-screen permissions, and notification receivers.
- Windows workflow remains pinned to `windows-2022`.

## Tests added in this release

- Reminder serialization and stable notification IDs.
- Scheduled Shopping date/location/reminder and Affair link.
- Bill accounting before and after payment.

Existing tests for Money, Finance, Home entries, Persian digits, People, Shopping, Medicine, and Cycle remain included.

## Important limitation

Flutter SDK is not installed in the artifact-generation environment. Therefore, this report does not claim that `flutter analyze`, `flutter test`, APK/AAB compilation, or Windows compilation ran locally. GitHub Actions is configured to perform those checks after the files are committed.

Required CI commands:

```text
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
```
