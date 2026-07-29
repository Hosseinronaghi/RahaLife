# Raha Life v0.4.1+8 — Analyze Hotfix

## Fixed

1. `lib/features/medication/presentation/medication_controller.dart`
   - Removed the unnecessary null assertion from `updated!.active`.

2. `lib/features/settings/presentation/settings_screen.dart`
   - Replaced deprecated `onReorder` with `onReorderItem`.

3. `lib/core/settings/app_settings.dart`
   - Removed the old manual `newIndex` adjustment because `onReorderItem` supplies the adjusted index.

4. `pubspec.yaml`
   - Updated version from `0.4.0+7` to `0.4.1+8`.

5. `CHANGELOG.md` and `README.md`
   - Documented the hotfix.

## Expected CI result

`flutter analyze --fatal-infos` should no longer report the two submitted issues.

The Flutter SDK was not available in the packaging environment, so the final analyzer and build run must be performed by GitHub Actions.
