# Raha Life v0.5.0+9 — Validation report

## Static validation completed in the packaging environment

- Persian and English ARB key parity: PASS
- Localized keys in each language: 477
- `l10n.*` references with missing keys: 0
- YAML parsing: PASS
  - `pubspec.yaml`
  - `l10n.yaml`
  - `.github/workflows/build-release.yml`
  - `.github/workflows/flutter-ci.yml`
  - `.github/workflows/build-extended-platforms.yml`
- Dart delimiter scan (lib + test): PASS
- Dart files included in delimiter scan: 96
- missing relative imports (excluding generated l10n / generated Drift file): 0
- package import names missing from pubspec dependencies: 0
- deprecated project usages searched:
  - `FilePicker.platform`: none
  - old `onReorder:` callback: none
  - generated `MyApp` reference: none
- Android widget generator test:
  - generated native providers: 7
  - generated receiver entries: 7
  - generated widget XML parsed successfully
  - widget deep-link target generation checked

## Current package API checks

The implementation was aligned with the current APIs used by the selected dependency versions, including:

- `file_picker 11.0.3` static picking API
- `home_widget 0.9.3` data/update/pin and widget launch bridge APIs
- `flutter_quill 11.5.1` editor/toolbar/localization structure

## Tests added in v0.5.0

- Project controller behavior
- Message queue behavior
- Medicine course completion
- Sharing model behavior
- Sync engine pull/push behavior
- Sync conflict preservation

Existing v0.4 tests remain in the test suite.

## Android widget generator smoke test

The generator was executed against a temporary Android manifest. Result:

- XML/resource generation succeeded
- all XML files parsed
- Kotlin source files created for Today/Affairs/Medicine/Appointment/Shopping/Birthday/Quick Add
- manifest receiver count = 7

## Limitation of this validation environment

Flutter and Dart SDK executables are not installed in this packaging environment. Therefore the following were **not** claimed as executed here:

- `flutter pub get`
- `flutter analyze --fatal-infos`
- `flutter test`
- Drift code generation compile check
- APK/AAB build
- Windows build
- Web build
- Linux/macOS/iOS build

GitHub Actions in the delivered repository is responsible for those checks. The first CI run after replacement is therefore a required acceptance step for this release.

## Acceptance criterion after GitHub upload

The release should not be considered build-validated until these jobs are green:

1. Flutter CI analyze/test
2. Android APK/AAB
3. Windows portable
4. Web release
5. optional manual Extended Platforms workflow for Linux/macOS/iOS Simulator

Any compiler/analyzer failure from those jobs should be treated as a v0.5.x hotfix rather than ignored.
