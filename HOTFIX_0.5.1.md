# Raha Life v0.5.1+10 — Analyzer / build hotfix

This hotfix is based on v0.5.0+9 and addresses the GitHub Actions failures reported by `flutter analyze --fatal-infos` and the Windows release compiler.

## Fixed

- Replaced all standalone `__` / multiple-underscore unused callback parameters in `lib/` with Dart wildcard `_`, eliminating the `unnecessary_underscores` infos that become fatal under `--fatal-infos`.
- Fixed nullable medication catalog access in `medication_screen.dart` by reading the currently selected catalog item null-safely.
- Removed the unused `project.dart` import from `projects_screen.dart`.
- Bumped package version to `0.5.1+10`.

## Product behavior

No feature, schema, sync, or UI behavior is intentionally changed by this hotfix.

## Expected CI effect

The 37 issues in the supplied analyzer log are addressed. The Windows compiler failure at medication screen line 357 is addressed by the same null-safety fix.

## Verification boundary

Static source checks were run in the packaging environment. Flutter/Dart SDK is not installed in this environment, so the authoritative acceptance step remains GitHub Actions: `flutter analyze --fatal-infos`, `flutter test`, then platform builds.
