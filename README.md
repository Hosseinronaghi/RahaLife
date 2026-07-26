# Raha Life — Foundation v0.1.0

A production-oriented Flutter foundation for a bilingual, offline-first personal planner.

## Included in this foundation

- Responsive mobile/desktop shell
- Persian/English localization foundation with RTL/LTR
- Daily dashboard and modular navigation
- Drift/SQLite schema for tasks, medications, medication logs, appointments, notes, shopping, finance, habits, goals, categories, tags and sync queue
- AI provider abstraction supporting app quota, OpenAI, Gemini and custom OpenAI-compatible endpoints
- Secure API-key storage
- Online-first AI with no bundled local model
- Backup/sync interfaces and implementation plan
- CI workflow for analysis and tests

## Bootstrap

This archive intentionally contains the project-owned source and configuration. Platform folders should be generated with the installed Flutter SDK:

```bash
flutter create --platforms=android,ios,windows,macos,linux .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Do not overwrite `lib/`, `pubspec.yaml`, `l10n.yaml`, `analysis_options.yaml`, `test/`, or `docs/` when generating platform folders.

## Fonts

Font binaries are not included. Add your licensed/local copies as:

- `assets/fonts/Vazirmatn-Regular.ttf`
- `assets/fonts/Vazirmatn-Bold.ttf`

Alternatively remove the font declaration temporarily.

## Current state

This is the implementation foundation, not the final application. The database schema and service boundaries are established so feature modules can be completed without architecture rewrites.
