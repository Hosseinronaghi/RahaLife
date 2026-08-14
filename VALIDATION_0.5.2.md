# Raha Life v0.5.2+11 validation

## Targeted build failure
The uploaded GitHub Actions log failed in Android `compileReleaseJavaWithJavac` because the generated plugin registrant referenced `com.mr.flutter.plugin.filepicker.FilePickerPlugin`, which could not be resolved.

## Applied fix
- Upgraded `file_picker` from 11.0.3 to 12.0.0.
- Migrated both single-file attachment flows to the v12 `FilePicker.pickFile()` API.
- Updated `share_plus` from 12.0.2 to 13.3.0.
- Pinned GitHub Actions to Flutter 3.47.0 for repeatable builds.
- Added `flutter clean` before dependency resolution in generated-platform workflows.
- Set generated iOS deployment target to 14.0 for file_picker 12 compatibility.
- Updated local bootstrap script accordingly.

## Static validation performed
- `pubspec.yaml` contains Raha Life version `0.5.2+11`.
- No `file_picker 11.x` dependency remains.
- No source reference to `com.mr.flutter.plugin.filepicker.FilePickerPlugin` exists in the repository.
- Both file picker call sites use `FilePicker.pickFile()` and no longer use the v11 `FilePickerResult.files` flow.
- GitHub Actions YAML files parse successfully.
- All CI workflows pin Flutter `3.47.0`.
- Apple workflow applies iOS deployment target `14.0`.

## Not executed locally
Flutter/Dart SDK is not installed in this packaging runtime, so final `flutter pub get`, `flutter analyze`, `flutter test`, Android, Windows, Web, Linux, macOS, and iOS builds must be confirmed by GitHub Actions.
