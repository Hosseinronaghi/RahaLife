# Raha Life — v0.5.3

Raha Life is a Persian/English, local-first personal organizer intended for Android, iPhone, Windows, macOS, Linux and Web.

## v0.5.3 file metadata hotfix

- Uses `await PlatformFile.length()` for attachment size with `file_picker 12`.
- Fixes the analyzer and desktop/mobile compilation error caused by the removed `PlatformFile.size` getter.


It brings daily Affairs, Appointments, Shopping, Medicine, Cycle tracking, People, Birthdays, Notes, Habits, Finance, Projects, sharing and reminders into one consistent application while allowing each module to keep its own subject-specific UI.


## v0.5.2 Android build hotfix

- Moves file selection to `file_picker 12.0.0` federated architecture.
- Uses `FilePicker.pickFile()` for the two single-file attachment flows.
- Pins CI to Flutter 3.47.0 so future Flutter stable changes do not unexpectedly break releases.
- Updates `share_plus` to 13.3.0 for current built-in Kotlin support.
- Sets generated iOS projects to deployment target 14.0, required by file_picker 12.

## v0.5.1 hotfix

This hotfix fixes analyzer/build compatibility with current Dart/Flutter stable without changing product behavior. It removes fatal lint infos, fixes nullable medication catalog access, and removes an unused import.

## v0.5.0 highlights

### Project workspace

Projects now have a dedicated workspace with:

- Overview and progress
- Affairs linked to the Project
- Rich Notes
- Checklist and completion progress
- Files/attachments metadata
- People
- Project-linked Finance
- system share
- internal People share permissions

### Professional Notes

The Note module now uses a rich-text document model instead of a plain text area. Notes support:

- rich formatting
- tags
- pin/archive/delete
- Project link
- Person link
- system share
- internal share with People

Quick Add now opens the professional Note editor for new notes.

### Cycle-specific UI

Cycle has a dedicated visual language instead of reusing generic list cards. It includes:

- current cycle-day summary
- approximate next-period estimate
- quick symptom logging
- pain, flow, mood and symptoms
- history
- privacy toggle
- reminder editor

Predictions are explicitly approximate and non-diagnostic.

### Medicine catalog and course tracking

Medicine includes a searchable starter catalog for **recording medicines the user already uses**. Search covers generic name, therapeutic group and general recorded-use labels. The form records:

- generic/brand name
- medicine form
- dose
- reason entered by the user
- treatment group/use metadata
- start/end date
- continuous, fixed-date, fixed-days or as-needed course
- stock
- reminder/alarm

The catalog is not a prescribing or treatment recommendation system.

### Birthdays

Birthday registration includes Relationship and can be linked to People records.

### Sharing and Messages

Raha Life now has:

- OS/system sharing for Projects, Notes, Affairs/Appointments and Shopping
- internal share grants with People
- view/check/edit permission concepts
- Shopping list sharing with selected People
- Messages UI
- local outgoing message queue
- file attachment metadata
- shared Project/Note/Shopping references inside Messages

Remote delivery is intentionally not claimed yet. Messages and internal grants are queued for the Raha Cloud milestone.

### Inbox / Quick Capture

A lightweight Inbox captures text first and later converts it to Affairs, Appointment, Note, Shopping or Project.

### Widgets

Android CI generates seven native home-screen widget providers:

- Today
- Affairs
- Medicine
- Appointment
- Shopping
- Birthday
- Quick Add

Widgets support light/dark system resources, app-localized data, privacy masking, Android pin requests and deep links back to the correct Raha Life destination. Quick Add opens the Quick Add sheet.

The Flutter bridge for iOS is present, but an actual WidgetKit Extension/App Group target still has to be created in the Apple-native milestone. `home_widget` only provides the Flutter/native bridge; native widget targets are still required.

### Cross-platform sync architecture

Schema v5 and `lib/core/sync/sync_contract.dart` prepare record-level synchronization for:

- Android
- iPhone / iOS
- Windows
- macOS
- Linux
- Web

The design synchronizes records rather than copying a live SQLite file. It includes UUID/version/device/update/delete metadata, a SyncQueue, pull cursor, push acknowledgements and conflict objects.

**Important:** Raha Cloud is not deployed in v0.5.0. The Sync Center is an app-side control center and local checkpoint. Real remote sync, remote Messages and live collaborative lists require the next server milestone.

Google Drive, Dropbox and OneDrive remain planned as personal encrypted backup/recovery providers rather than the transactional collaboration transport.

See `docs/SYNC_ARCHITECTURE_0.5.md`.

## Default module order

The user can reorder/hide modules from Settings. The current default includes:

```text
Inbox
Project
Affairs
Appointment
Shopping
Medicine
Cycle
People
Birthday
Note
Habit
Finance
Messages
```

Cycle remains before People; Shopping and Medicine remain before Birthday.

## GitHub Actions

### Normal build workflow

`.github/workflows/build-release.yml` creates:

- Android universal APK
- Android split APKs
- Android AAB
- Windows x64 portable ZIP
- Web release ZIP

Android CI also generates the native widget classes/resources.

### Extended platform workflow

`.github/workflows/build-extended-platforms.yml` can be started manually and creates:

- Linux x64 portable archive
- macOS release ZIP
- unsigned iOS Simulator application ZIP

The iOS Simulator artifact is for testing only; App Store/TestFlight distribution still requires Apple signing/provisioning.

## Repository setup

Upload the **contents** of the source ZIP to the repository root so that `pubspec.yaml` is directly visible.

The project now targets Dart `>=3.10.0` because current plugin dependencies require a modern Flutter/Dart toolchain.

Typical validation/build sequence:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```

## Status boundaries

### Implemented in this source

- local-first UI and persistence prototypes
- Project workspace
- rich Notes
- Cycle-specific UI
- enhanced Medicine
- People sharing model
- Messages queue UI
- Android widgets
- cross-platform Sync contracts/schema
- CI definitions for six target platform families

### Not yet remotely operational

- Raha Cloud backend
- remote registration/account recovery
- actual multi-device data transfer
- Google Drive / Dropbox / OneDrive OAuth and backup APIs
- remote Message delivery
- live collaborative Shopping/Projects
- iOS native WidgetKit Extension
- desktop tray/quick-panel implementation
- full migration of all feature repositories from SharedPreferences prototypes to Drift

## Documentation

- `docs/SYNC_ARCHITECTURE_0.5.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/UI_UX_SPECIFICATION.md`
- `CHANGELOG.md`
