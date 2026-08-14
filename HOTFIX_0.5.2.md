# Raha Life v0.5.2+11 — Android plugin build hotfix

This hotfix addresses the Android release build failure in `GeneratedPluginRegistrant.java` for `file_picker`.

## Changes
- `file_picker`: 11.0.3 → 12.0.0.
- Migrated the two single-file picker call sites to `FilePicker.pickFile()`.
- `share_plus`: 12.0.2 → 13.3.0.
- GitHub Actions pinned to Flutter 3.47.0 instead of following future stable releases automatically.
- Added `flutter clean` before dependency resolution in generated-platform jobs.
- Extended Apple workflow now sets iOS deployment target 14.0, required by file_picker 12.

## Why
file_picker 11.x had Android plugin-registration / Kotlin build compatibility regressions that can produce `cannot find symbol FilePickerPlugin`. Version 12 moves to a federated plugin architecture and includes the Android compatibility fixes.

## Validation note
Flutter SDK is not installed in the packaging environment, so final `flutter analyze`, tests, and platform builds must run in GitHub Actions.
