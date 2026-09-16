# Raha Life Sync Architecture — v0.6

## Principles

1. Local-first: the app must work without network access.
2. No Raha-owned server is required for the personal-data core.
3. Users choose one or more storage/sync providers.
4. A live SQLite database file is never copied between concurrently active devices as a sync mechanism.
5. Remote record sync uses UUID/version/device metadata and conflict preservation.
6. Backup data is encrypted before it leaves the client.
7. Remote SQL databases are never exposed directly to the app.

## Provider layers

### Local / manual
- device-only
- encrypted `.rahabackup`
- system save/open picker
- file-mediated device transfer

### Personal storage
- WebDAV
- Nextcloud / ownCloud
- S3-compatible / MinIO
- SFTP on native platforms
- Google Drive / OneDrive / Dropbox / iCloud through system file integrations today; direct OAuth adapters later

### Self-hosted API
- Raha Sync Server — PHP/MySQL shared-hosting edition
- Raha Sync Server — Docker edition
- compatible custom HTTPS API

## Backup vs record sync

A backup target stores an encrypted snapshot. It does not need transactional semantics. Record sync exchanges independent entity changes and requires a compatible API.

`BackupTarget` and `SyncTransport` are deliberately separate interfaces.

## Record metadata

Each syncable entity is expected to carry:

- entity type
- UUID/entity ID
- operation (upsert/delete)
- version
- updated-at UTC
- device ID
- optional deleted-at UTC tombstone
- JSON payload

## Conflict policy

A remote higher version can replace a lower local version. Same-version divergent edits from different devices are preserved as conflicts rather than silently overwritten. Feature-specific merge strategies can later resolve independent child records such as shopping items.

## Encryption

The v0.6 backup envelope uses a 256-bit AES-GCM key stored through platform secure storage. A recovery key can be exported separately for a new device. The backup file does not contain the plaintext recovery key.

## Automatic backup

Automatic backup is app-lifecycle driven in v0.6: on launch/resume, if enabled and at least six hours have elapsed, enabled backup targets are considered. A Wi-Fi/Ethernet-only option can block cellular execution.

This is not an OS background scheduler yet.

## Migration boundary

The database schema and sync contracts exist, but several active feature controllers still persist to SharedPreferences. Full multi-device record sync must wait until those repositories become Drift-backed and implement `SyncStore`/SyncQueue behavior.

## Remote retention

In v0.6, generic storage providers overwrite a single encrypted `latest.rahabackup`. The self-hosted Raha Sync Server additionally keeps a bounded archive (default seven versions). This avoids unbounded storage growth while still allowing server-managed rollback history.

## Local-network permissions

Apple platform bootstrap adds a local-network usage description for user-selected NAS/VPS/home-server connections. Android local-network permission behavior must be revisited when the project targets Android 17 / SDK 37 or newer; the current generated target should not request that future permission prematurely.
