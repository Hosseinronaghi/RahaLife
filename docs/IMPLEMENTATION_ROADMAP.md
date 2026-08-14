# Raha Life implementation roadmap

## Delivered foundation — v0.1 to v0.4.1

- Flutter responsive shell
- Persian/English localization and RTL/LTR
- Material 3 theme and personalization
- Today dashboard, calendar, global search, reports
- Affairs and Appointment classification
- People, Shopping, Medicine, Finance, Cycle
- local account/session
- reminders and alarms
- scheduled Shopping linked to Affairs
- bill reminders and finance categories
- customizable module order and visibility
- Android, Windows and Web CI builds

## Delivered client/workspace milestone — v0.5.0

- Project workspace with Overview, Affairs, Notes, Checklist, Files, People and Finance
- Rich Notes editor using Delta JSON, tags, pin/archive, Project/Person links and sharing
- Inbox / Quick Capture conversion flow
- dedicated modern Cycle dashboard and symptom logging
- searchable medication starter catalog, therapeutic/use metadata, reason, medicine form and course duration
- Birthday relationship support
- unified Reminder Editor used by main scheduled modules
- Messages UI with local outgoing queue, file metadata and shared-item references
- system sharing plus internal People permission grants
- Shopping sharing permissions (view/check/edit)
- Android native home-screen widgets: Today, Affairs, Medicine, Appointment, Shopping, Birthday, Quick Add
- widget privacy setting, pin requests, and deep-link launch routing
- Sync Center covering Android, iOS, Windows, macOS, Linux and Web
- record-level Sync engine contract and conflict model
- Drift schema v5 with shared sync metadata
- manual CI workflow for Linux, macOS and iOS simulator

## Next milestone 1 — Raha Cloud account and real synchronization

### Server account

- remote registration/login
- email verification
- password recovery
- access/refresh token lifecycle
- migrate/claim an existing local account
- device registration, device list, remote sign-out
- account export/deletion

### Sync API

- PostgreSQL data store
- push/pull endpoints with cursors
- UUID/version/device/update/tombstone handling
- SyncQueue integration from Drift repositories
- retry/backoff
- sync history and diagnostics
- conflict persistence and UI
- attachment object storage

### Platform goal

One account must synchronize the same data across:

- Android
- iPhone
- Windows PC
- macOS
- Linux
- Web

## Next milestone 2 — live collaboration and Messages

- actual one-to-one Message delivery
- unread/read state across devices
- attachment upload/download
- shared Shopping list invitations
- owner / viewer / checker / editor permissions
- live Shopping item updates
- shared Projects and Notes
- Shared Spaces
- collaboration notifications

## Next milestone 3 — personal cloud backup providers

- Google Drive OAuth + encrypted application backup
- Dropbox OAuth + encrypted app-folder backup
- OneDrive OAuth + encrypted app-folder backup
- backup history
- restore preview
- selective backup modules
- local encrypted backup/export

## Next milestone 4 — native platform polish

### iOS

- native WidgetKit Extension and App Group entitlement
- production signing / TestFlight workflow
- notification permission UX

### Windows/macOS/Linux

- tray/quick panel
- installer packaging
- startup/background options
- native notification verification

### Android

- actionable reminder buttons
- Snooze actions
- widget interaction polish

## Product-depth milestones

### Finance

- custom categories/subcategories
- destination account for transfers
- recurring transactions
- People-linked debt/receivables
- budgets/category limits
- savings goals
- receipt attachments
- charts and exports

### Medicine

- multiple daily schedules
- taken / late / skipped / missed / postponed logs
- stock decrement/refill reminders
- expiry reminder
- medication report export
- authoritative terminology provider adapter

The medication catalog remains a recording aid; Raha Life must not prescribe or recommend medication for a disease.

### Notes

- image/file attachments in the editor
- voice notes
- backlinks
- trash/restore history
- templates

### Cycle

- richer multi-month calendar
- trends
- stronger privacy lock controls
- optional fertility features, disabled by default

### Projects

- templates
- project-specific dashboards
- richer file lifecycle/versioning
- shared Project collaboration
