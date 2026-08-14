# Raha Life sync architecture — v0.5.0

## Target platforms

The same user data model is intended for:

- Android
- iPhone / iOS
- Windows
- macOS
- Linux
- Web

Every native device remains local-first. The local database is the source used by the UI; network access is never required to create, edit, or read ordinary personal data.

## Record-level synchronization

Raha Life does **not** synchronize a live SQLite database file between devices. Each record is synchronized independently.

Schema v5 introduces/commonizes the metadata needed by the future Drift repositories:

- UUID / entity ID
- `version`
- `deviceId`
- `updatedAt` in UTC
- `deletedAt` tombstone
- SyncQueue operations

`lib/core/sync/sync_contract.dart` now contains a transport-independent record synchronization engine with:

- pull cursor
- push queue
- per-record envelopes
- soft-delete operations
- conflict objects
- upload acknowledgements
- local store abstraction
- cloud transport abstraction

A unit test covers normal pull/push and same-version cross-device conflict preservation.

## Raha Cloud

Raha Cloud is the intended transactional synchronization service for:

- multi-device record sync
- Messages delivery
- shared Shopping lists
- shared Projects
- Shared Spaces
- invitation and permission state
- attachment object references
- near-real-time collaboration

The server itself is **not deployed or connected in v0.5.0**. The current Sync Center stores provider/mode/device settings and creates a local checkpoint only.

## Google Drive, Dropbox, and OneDrive

These providers remain planned as user-controlled personal backup / recovery providers. v0.5.0 defines `PersonalCloudBackupProvider`, but OAuth credentials and provider API adapters are intentionally not embedded yet.

They should be used for:

- encrypted snapshots
- personal recovery
- optional personal backup history

They should not be the collaboration transport for Messages or shared live data.

## Conflict strategy

Independent records merge independently. If exactly the same entity has the same version but different edits from different devices, the engine preserves a conflict instead of silently overwriting a copy.

The next server milestone needs a conflict-resolution UI that can show:

- this-device version
- remote-device version
- merge when fields are independent
- choose local / remote when required

## Attachments

Attachments are modeled separately from database records. The future cloud service should upload binary objects independently and synchronize only object metadata / keys in record payloads.

This applies to:

- Project files
- Note attachments
- Message files
- receipt images
- audio notes

## Security requirements for the server milestone

- HTTPS only
- refresh-token rotation
- secure credential storage
- device registration and revocation
- per-user authorization for every entity
- explicit permissions for shared entities
- encrypted backup snapshots
- rate limiting and abuse controls for Messages and invitations
- account export and deletion

## Current status

### Implemented in app code

- cross-platform data model
- schema v5 sync metadata
- SyncQueue table
- record sync engine contracts
- pull/push/conflict algorithm scaffold
- local device ID
- provider/mode preferences
- queued sharing grants
- queued Messages
- local checkpoint UI

### Requires the next cloud milestone

- Raha Cloud server
- remote account registration/login
- actual device-to-device synchronization
- OAuth for Drive/Dropbox/OneDrive
- attachment upload/download
- live Message delivery
- live shared Shopping/Project updates
- push notifications for remote collaboration
