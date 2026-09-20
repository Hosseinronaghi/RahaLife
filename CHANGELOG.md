## 0.10.0-dev.2+18 (review)

Managed media and recording; entertainment; grouped daily agenda; dose history and snooze; simpler sync/backup UI; localized catalog; credential hashing and error hardening. See docs/v010/STATUS_FA.md for validation and unfinished work.

# Changelog

## 0.8.0+15 — review candidate

- Schema 7, vector-clock conflict detection, atomic cursor application and exact change acknowledgements.
- Safer stale-editor writes, insert-only migration, logical backups and legacy recovery tooling.
- Responsive Today redesign, bundled Persian typography, light/dark themes and editable home shortcuts.
- Profile, record editing/recovery, financial transfers/budgets/installments, bookmarks and BYOK assistant expansion.
- Protocol 3 accounts, friends, direct messages and independently shared snapshots.
- 50 passing Flutter cases, release web compilation and documented external acceptance gates.
- See docs/RELEASE_0.8_FA.md for implemented scope and unresolved product work.

## 0.7.0+14

### P0 — Safe update and primary data migration
- Added a v0.7 preflight recovery snapshot for known legacy primary SharedPreferences payloads before migration starts.
- Added a one-time native SQLite safety copy before schema migration where a native database exists.
- Added migration journal rows so legacy imports are idempotent and legacy keys are removed only after durable writes succeed.
- Upgraded Drift schema to version 6 with entity documents, durable change log, provider cursor state, conflicts and migration journal tables.
- Added optional persistent Android release-signing support in GitHub Actions; production in-place upgrades require the same user-owned keystore across releases.

### P0 — Primary data on Drift
- Migrated active primary domain repositories for Today/home entries, People, Notes, Projects, Medication, Cycle, Inbox, Messages, Sharing, Finance and Shopping to Drift-backed entity documents.
- Split Shopping into list records and independent item records so checking/editing one item does not rewrite the entire list.
- Added serialized per-entity write queues to prevent rapid asynchronous UI saves from completing out of order.
- Added canonical JSON encoding so map key ordering does not create false sync changes.
- Configuration/session preferences intentionally remain settings rather than user-domain records.

### P0 — Incremental multi-device sync
- Implemented durable record-level `SyncChanges` with stable `changeId`, version, device identity and tombstones.
- Implemented pull-first cursor sync with bounded pagination and exact change acknowledgements.
- Added automatic incremental sync after local changes, app start and app resume, respecting the optional Wi-Fi/Ethernet-only policy.
- Added one active live record-sync target at a time with independent unlimited backup targets.
- Switching live record-sync provider requeues durable history so a new compatible server can be seeded without database replacement.
- Added conflict storage and user-facing Keep Local / Use Remote resolution; no silent overwrite for divergent same-revision edits.
- Updated the PHP/MySQL and Docker self-hosted server protocol to v2 with idempotent `changeId`, cursor paging, tombstones, stale-delta acknowledgement and conflict preservation.
- Added `server/shared-hosting/upgrade_v0.7.sql` for existing v0.6 MySQL installations.

### P0 — Backup and web data runtime
- Backup payload v2 now exports a logical Drift snapshot and merges it conservatively during restore.
- Equal local revisions are never overwritten by backup restore; only missing or strictly newer backup revisions are merged.
- v0.6 backup payloads remain supported through the legacy raw-database restore path.
- Added conditional native/web Drift database connections and a WASM web worker preparation script used by Web CI.

### P0 — Design System v2 foundation
- Added shared spacing, radius, motion and module-identity visual tokens.
- Added reusable Raha surfaces, hero panels and metric tiles.
- Updated the global Material 3 theme and rolled the new visual language into Today with richer graphical hierarchy, module accents and animated progress.
- This is the design-system foundation and first screen rollout; final bespoke UI for every module remains iterative work.

### Tests and docs
- Added tests for record deltas, canonical JSON, serialized rapid writes, remote apply behavior, conflict resolution, schema v6 and non-destructive logical backup merge.
- Added protocol-v2, migration, Android signing and Design System v2 documentation.

### Current boundary
- Live record sync currently targets a self-hosted Raha Sync Server or compatible custom HTTPS API. WebDAV/Nextcloud/S3/SFTP remain encrypted-backup targets.
- Direct Google Drive/OneDrive/Dropbox OAuth live-record adapters still require provider application registrations and are not presented as active.
- Multi-user Friends/remote social authentication, professional Finance v2, career/profile personalization, Home slots, complete edit coverage, AI onboarding, bookmarks and browser extension remain later P1/P2 work.

## 0.6.0+13

### Added
- Provider-based local-first data/backup architecture with no dependency on a Raha-owned VPS or cloud.
- AES-256-GCM encrypted `.rahabackup` creation and restore plus recovery-key export/import.
- Multiple user-defined backup connections, primary target selection, connection test, enable/disable, backup and restore.
- Secure provider credential storage separate from ordinary settings.
- Real WebDAV and Nextcloud/ownCloud encrypted backup targets.
- Real S3-compatible/MinIO encrypted backup target with AWS Signature V4 requests.
- Real SFTP encrypted backup target on native platforms, with a web-safe unsupported adapter.
- Self-hosted Raha Sync Server / Custom HTTPS backup target.
- HTTP record-sync transport for a compatible Raha Sync Server.
- HTTPS-by-default transport validation with an explicit trusted-LAN HTTP override.
- Automatic backup checks after sync settings load and on app resume, with optional Wi-Fi/Ethernet-only policy.
- Encrypted system-share transfer for moving a backup to another device without a Raha server.
- Docker self-hosted server edition for VPS/NAS/home server deployments.
- PHP/MySQL shared-hosting server edition for users without a VPS or Docker.
- Self-hosted health, backup upload/download, sync pull/push and conflict-preservation endpoints.
- Bounded self-hosted backup retention (default seven archives) plus a rolling latest snapshot; generic WebDAV/S3/SFTP automatic targets keep one rolling latest snapshot to prevent unbounded storage growth.
- Apple local-network privacy text for user-selected NAS/VPS/home-server connections.
- Sync provider model/security tests.

### Changed
- Reframed cloud architecture from `Raha Cloud` dependency to `Raha Sync`, a provider-based/self-hostable architecture.
- Updated Persian and English copy for Messages, Shared Space and Sync so it no longer promises a Raha-owned cloud.
- Personal cloud backup can use the OS file picker for Google Drive, OneDrive, Dropbox and iCloud locations exposed by the platform.
- App version is now `0.6.0+13`.

### Current boundary
- Record-sync protocol and self-hosted endpoints are implemented, but full record-level synchronization of every feature waits for migration of active feature repositories from SharedPreferences to Drift.
- Automatic OAuth adapters for Google Drive/OneDrive/Dropbox require real provider app registrations/client IDs and are not falsely presented as connected.
- Direct network P2P/QR pairing is not yet implemented; v0.6.0 provides encrypted file-mediated device transfer.

## 0.5.3+12

- Fixed the file attachment size lookup for `file_picker 12` by using the asynchronous `PlatformFile.length()` API.
- Restores analyzer and Windows/Android build compatibility after the v12 file-picker migration.
- No product behavior or data-model changes.

## 0.5.2+11

- Migrated `file_picker` to 12.0.0 and the new federated plugin architecture.
- Updated single-file picking call sites to `FilePicker.pickFile()`.
- Updated `share_plus` to 13.3.0 for current Flutter / built-in Kotlin compatibility.
- Pinned GitHub Actions to Flutter 3.47.0 for reproducible builds.
- Added `flutter clean` before dependency resolution in CI build jobs.
- Raised generated iOS deployment target to 14.0 to match file_picker 12 requirements.
- Fixes Android release failure where `GeneratedPluginRegistrant.java` could not resolve `FilePickerPlugin`.

## 0.5.1+10

Hotfix for current Flutter stable / `flutter analyze --fatal-infos`:

- Fixed nullable medication catalog access that blocked Windows and other builds.
- Replaced deprecated-style multiple underscore wildcard parameter names with Dart wildcard `_`.
- Removed an unused Projects import.
- No feature or data-model changes.

## 0.5.0+9

### Added
- Project workspace with Overview, Affairs, Rich Notes, Checklist, Files, People and Finance tabs.
- Rich Notes editor with Delta JSON, tags, pin/archive, Person/Project links and sharing.
- Inbox / Quick Capture conversion flow.
- Dedicated modern Cycle UI with symptom logging, privacy control and approximate next-cycle reminder.
- Searchable starter Medicine catalog, medicine form, user-recorded reason, course types, start/end dates and finished-course state.
- Birthday relationship support.
- Internal People sharing grants and Shopping permissions (view/check/edit).
- Messages UI with local queued messages, attachment metadata and shared-item references.
- Sync Center for Android, iOS, Windows, macOS, Linux and Web.
- Transport-independent record sync engine contract with pull/push cursors and preserved conflicts.
- Drift schema v5 with common version/device/deleted metadata for syncable user data.
- Seven Android native home-screen widgets: Today, Affairs, Medicine, Appointment, Shopping, Birthday and Quick Add.
- Android widget pin requests, privacy masking and deep-link routing.
- Manual GitHub Actions build workflow for Linux, macOS and iOS Simulator.
- Sync architecture documentation.

### Changed
- Quick Add now opens the Rich Note editor for Notes.
- File Picker calls migrated to the current static API.
- Unified Reminder Editor is used by scheduled Shopping and bill flows as well as Medicine/Cycle.
- Project Dart SDK floor moved to 3.10 for current plugin compatibility.

### Sync status
- App-side record-level sync architecture is implemented, but Raha Cloud is not deployed/connected yet.
- Google Drive, Dropbox and OneDrive are represented as personal backup providers; OAuth/API adapters remain the next cloud milestone.
- Internal Messages/shares are local queued prototypes until Raha Cloud is online.

## 0.4.1+8

### Fixed
- Removed an unnecessary non-null assertion in the medication controller.
- Migrated module reordering from the deprecated `onReorder` callback to `onReorderItem`.
- Updated reorder index handling for the new Flutter callback semantics.
- Restored compatibility with `flutter analyze --fatal-infos` on current Flutter stable.

## 0.4.0+7

### Added
- Unified local reminder engine with normal notifications and prominent alarms.
- Time-zone-aware scheduling, repeat rules, exact-alarm permission handling, and notification-tap routing.
- Reminder controls for Affairs, Appointments, Birthdays, Shopping, Medicine, Bills, and estimated Cycle dates.
- Location and address fields for Affairs, Appointments, and Shopping lists.
- Scheduled shopping lists with purchase date, time, location, reminder, recurrence, and a linked Shopping Affair.
- Two-way navigation between a Shopping list and its linked Affair.
- Bill reminders with due date/time, bill type, bill/payment identifiers, paid state, and repeat schedule.
- Full default expense categories covering bills, rent, food, transport, health, medicine, education, travel, subscriptions, loans, and more.
- User-controlled module order with drag-and-drop, hide/show controls, and restore-default action.
- Daily medicine notification/alarm schedules.
- Optional reminder for the estimated next cycle date.
- Tests for reminder serialization and IDs, scheduled Shopping links, and unpaid/paid bill accounting.

### Changed
- Moved Cycle before People in the default module order.
- Rebuilt light and dark theme colors to force readable foreground colors on Android and Windows.
- Added Vazirmatn as the preferred Persian typeface with an offline Vazir fallback.
- Constrained the desktop month calendar width and cell proportions to prevent oversized selected dates.
- Updated notification permissions and Android scheduled-notification receivers in GitHub Actions.
- Updated app version to `0.4.0+7`.

### Still planned
- Server-backed account registration, password recovery, and multi-device synchronization.
- Collaborative live Shopping lists.
- User-created financial categories/subcategories, budgets, receipts, and advanced charts.
- Custom alarm sounds and snooze actions.

## 0.3.0+6

### Added
- Functional local account creation, sign-in, sign-out, secure salted password hashing, and persistent local session.
- Dedicated People module with contact information, birthday, notes, and links to affairs and appointments.
- Dedicated shopping-list model with multiple lists, bulk item entry, check states, sorting, and text sharing.
- Dedicated medication model with medicine form, dosage, time, instructions, stock, and active state.
- Expanded finance model with accounts, opening balances, six transaction types, categories, notes, filters, and summaries.
- Initial private cycle-tracking module with flow, pain, mood, notes, and approximate next-cycle estimation.
- People and user-profile tables in the Drift schema.
- Affairs and cycle-log tables/fields in the Drift schema.
- Medication and finance controller tests.
- Android release internet permission generation for online services and runtime font loading.

### Changed
- Renamed Tasks to Affairs (`امور`) throughout the active UI and data model.
- Moved medical, laboratory, administrative, follow-up, and payment classifications to Affairs.
- Limited Appointment types to meeting formats such as cafe, gathering, in-person, phone, and online.
- Changed Persian module labels to singular forms.
- Reordered modules so Shopping and Medicine appear before Birthday.
- Updated More and Profile screens to reflect the current local account.
- Upgraded the local database schema scaffold to version 3.
- Updated app version to `0.3.0+6`.

### Deferred to the next milestone
- Real server-backed registration and password recovery.
- Android, Windows, and Web synchronization.
- Cloud backup and new-device recovery.
- Collaborative real-time shopping lists.
- Conflict resolution and sync history.

## 0.2.0+5

### Added
- Complete Material 3 visual redesign for mobile and desktop.
- Persian-first RTL layout and English LTR layout.
- Vazirmatn and Inter typography integration.
- Dynamic light, dark, and system themes.
- Emerald, blue, purple, and orange accent choices.
- Persistent language, theme, accent, text scale, and home section settings.
- Redesigned daily dashboard with dual Persian/Gregorian date header.
- Conditional dashboard sections and a unified empty state.
- Working quick add for tasks, medicines, appointments, notes, shopping, finance, habits, and birthdays.
- Entry details, completion toggle, and deletion.
- Global search with type filters.
- Month, week, and day calendar views.
- Active module pages and explicit coming-soon pages.
- Statistics and progress views.
- Birthday database table and repeated birthday date logic.
- Functional AI settings persistence and OpenAI-compatible connection test.
