# Raha Life implementation roadmap — after v0.7.0

## Delivered foundation — v0.1 to v0.6

- Flutter cross-platform application foundation for Android, iOS, Windows, macOS, Linux and Web
- Persian/English localization, RTL/LTR, Solar Hijri/Gregorian presentation
- Today, Calendar, Affairs, Appointment, Shopping, Medication, Cycle, People, Birthday, Notes, Habits, Finance, Projects, Messages, Inbox, Reports, Search and Settings foundations
- reminders/alarms, widgets, local account/session, sharing foundations
- encrypted local-first backup and recovery key
- WebDAV/Nextcloud/S3/SFTP/self-hosted/custom backup providers
- Docker and PHP/MySQL self-hosted Raha Sync server packages
- provider-based architecture with no dependency on a Raha-owned VPS/cloud

## P0 delivered in v0.7.0 — core data and sync

### Safe update / migration

- preflight recovery capture before v0.7 migration
- native SQLite safety copy where available
- schema v6 migration
- migration journal and one-time legacy imports
- primary legacy preference removal only after durable import succeeds
- optional persistent Android release-signing workflow

### Primary data on Drift

- active primary user-domain repositories moved from SharedPreferences JSON to Drift entity documents
- Shopping split into parent lists and independent item records
- canonical JSON comparison
- serialized per-entity writes

### Incremental device sync

- durable record change log
- `changeId`, version, device ID, timestamp and tombstones
- cursor-based pull and exact acknowledged push
- pull-first synchronization
- automatic sync debounce and resume/start checks
- one active live record-sync target; multiple backup targets
- provider-switch history replay
- conflict persistence and Keep Local / Use Remote UI
- self-hosted protocol v2 and v0.6 server upgrade SQL

### Design System v2 foundation

- shared visual tokens
- module visual identities
- Raha surfaces, hero panels and metric tiles
- global theme/control update
- Today as first full visible rollout

## P1 — next product-depth milestone

### Finance v2 — personal accounting

- unlimited accounts: cash, bank account, bank card, wallet, savings, custom
- bank/account metadata, opening balance, currency, archive
- income / expense / transfer / debt / receivable / installment / bill / savings
- internal ledger postings so transfers are not double-counted as income/expense
- account-specific and consolidated reports
- categories/subcategories, budgets, savings goals, recurring transactions, receipts
- filters, charts and exports

### Profile + occupation / use style

- expanded profile and avatar
- occupation/activity area
- personal/work/study/family/mixed use style
- suggested initial module layout/templates based on use profile
- user can always override or disable suggestions without changing old data

### Home slots

- configurable visible slot count
- every eligible module can be added/removed/reordered
- when full, adding a module prompts replacement/reorder or capacity change
- independent Today-section ordering can remain available

### Complete editing contract

For every user-created module item:

- create
- view
- edit
- duplicate where meaningful
- archive where meaningful
- delete
- undo/restore where meaningful

### Connections / Friends

Separate from People. People can include non-Raha contacts; Connections represents Raha users.

- username / QR / invite
- requests and acceptance
- block/remove
- messages
- sharing permissions
- shared Shopping / Projects / Shared Spaces

This requires an optional multi-user collaboration backend/provider; personal data remains local-first and must not depend on it.

### AI assistant UX

- clear capability/privacy explanation
- free Raha quota when available
- BYOK OpenAI/Gemini/custom OpenAI-compatible provider
- explicit preview/confirmation before data-changing actions
- disclose what data is sent
- medical and financial safety boundaries

## P2

### Links / Bookmarks

- folders, tags, favicon, pin, archive, search
- HTML import/export first
- browser-extension sync later

### Browser Extension

- Chrome/Edge/Firefox target
- explicit permissions
- bookmark import/export/sync bridge

### Advanced reports

- finance, habits, medication adherence, cycle trends, weekly/monthly review
- comparisons, filters and export

### Module-specific settings

Dedicated settings for Affairs, Appointment, Shopping, Medication, Cycle, Finance, Notes, Projects and other modules.

## Platform/release work continuing alongside P1

- GitHub CI acceptance of v0.7 migration/sync
- iOS/macOS production signing and TestFlight/App Store workflows when Apple credentials are available
- Windows installer packaging / stable app identity
- Linux packaging refinement
- Google Drive/OneDrive/Dropbox direct OAuth adapters only after real provider app registrations exist
- direct LAN/QR device pairing and SFTP private-key authentication
