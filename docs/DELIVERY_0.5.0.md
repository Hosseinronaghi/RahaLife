# Raha Life v0.5.0+9 — Delivery report

Base compared: v0.4.1+8

## Delivery scope

This release implements the app-side/workspace work agreed after v0.4.1: Project, richer Notes, dedicated Cycle UX, enhanced Medicine entry, Birthday relationship, Messages/sharing queues, Android widgets, Inbox, and a platform-neutral sync architecture covering Android, iPhone/iOS, Windows, macOS, Linux and Web.

## Implemented

### Project workspace

- Project list and create/edit flow
- status, dates, description and progress
- Overview tab
- linked Affairs tab
- Rich Notes tab
- Checklist with completion/progress
- file attachment metadata via native file picker
- linked People
- Project-linked Finance
- system share
- internal share with selected People

### Notes

- Rich-text editor based on Delta JSON
- title and tags
- pin/archive/delete
- Project link
- Person link
- system share
- internal People sharing
- Quick Add now opens the Rich Note editor instead of creating a new legacy simple Note entry

Not yet in this milestone: voice recording and embedded image/file handling directly inside the rich editor.

### Cycle

- dedicated subject-specific modern screen
- current cycle day
- approximate next-period estimate
- flow, pain, mood and symptom capture
- history
- privacy visibility option
- Reminder Editor for the approximate next period
- explicit non-diagnostic/approximate messaging

### Medicine

- searchable starter catalog
- search by generic name, therapeutic group and general-use label
- medicine form
- generic/brand metadata
- reason entered by the user
- start/end dates
- continuous / fixed date / fixed days / as-needed course
- calculated finished-course state
- stock
- unified reminder/alarm editor

The catalog is a recording aid only and is not a prescribing or disease-to-drug recommendation engine.

### Birthday

- Relationship is recorded in Birthday entry data.
- People records can supply/own Birthday information without duplicating identity data.

### Reminder consistency

- reusable Reminder Editor
- Persian/English localized labels
- Persian digits for offsets in Persian UI
- notification vs alarm
- once/daily/weekly/monthly/yearly
- shared reminder UI used across the main scheduled flows

Custom free-form recurrence and notification Snooze actions remain later work.

### Shopping sharing

- system text sharing retained
- internal sharing with People added
- permissions: view / check items / edit
- queued grant state is stored locally

Live multi-user changes require Raha Cloud and are not claimed as active yet.

### Messages

- Messages list and one-to-one conversation UI
- requires a local signed-in account in the current client
- local outgoing queue
- read metadata model
- file attachment metadata picker
- Project/Note/Shopping item references inside Messages
- local queue status messaging

Actual delivery to another account/device requires the Raha Cloud backend.

### Inbox / Quick Capture

- fast text capture
- conversion to Affairs, Appointment, Note, Shopping or Project

### Widgets

Android build CI now generates seven native widget providers:

1. Today
2. Affairs
3. Medicine
4. Appointment
5. Shopping
6. Birthday
7. Quick Add

Additional behavior:

- light/dark native resources
- Persian/English widget data
- privacy masking
- refresh from Widget Center
- request Android pin/add from the app
- tap routing to the relevant module
- Quick Add widget deep-links to the Quick Add sheet

For iOS the Flutter data bridge is prepared, but the native WidgetKit Extension/App Group target is not yet generated in CI. Desktop widgets are not claimed; a tray/quick panel is planned.

### Synchronization architecture

- platform list includes Android, iOS, Windows, macOS, Linux and Web
- local device UUID
- provider/mode preferences
- Drift schema version 5
- common `version`, `deviceId`, `updatedAt`, `deletedAt` metadata on syncable user data
- SyncQueue table
- record-level `SyncEnvelope`
- pull cursor
- push acknowledgements
- conflict objects
- transport-independent `RecordSyncEngine`
- `PersonalCloudBackupProvider` contract
- tests for pull/push and cross-device conflict preservation

Important boundary: v0.5.0 contains the client architecture and sync engine contract, **not a deployed Raha Cloud service**. The Sync Center's current action stores a local checkpoint rather than performing remote synchronization.

### Google Drive / Dropbox / OneDrive

- selectable in the Sync Center
- represented in architecture as personal backup/recovery providers
- common provider contract exists

Not yet implemented:

- OAuth sign-in
- provider API credentials
- encrypted upload/download adapters

These need provider app registrations/credentials and belong to the cloud milestone.

### Platform builds

Existing normal CI:

- Android APK/AAB
- Windows portable
- Web release

New manual extended workflow:

- Linux x64 portable
- macOS release
- iOS Simulator application (unsigned/testing only)

The Linux workflow includes native secret-storage development requirements.

## Database changes

Drift schema: v4 -> v5

Record-level sync metadata was standardized across core user-data tables. New workspace/message/share tables are included in the migration path.

## Package/API maintenance included

- current static File Picker calls are used (`FilePicker.pickFiles()`)
- Flutter Quill rich editor/localization integration
- Home Widget native bridge is guarded to Android/iOS only
- project Dart SDK floor raised to 3.10 for current plugin requirements

## Files changed relative to v0.4.1

- Added: 38
- Modified: 32
- Removed: 0
- Total changed paths: 70

See `CHANGED_FILES_0.5.0.txt`.

## Explicitly not claimed as complete

- remote account registration/login/password reset
- real device-to-device synchronization
- deployed Raha Cloud API/database
- live Message delivery
- live shared Shopping/Project editing
- Google Drive/Dropbox/OneDrive OAuth + cloud backup transfer
- iOS WidgetKit native target
- desktop tray/quick panel
- full feature-repository migration from SharedPreferences prototypes to Drift
- voice/image/file Notes embedded in the rich editor
- production Apple signing and App Store/TestFlight delivery
