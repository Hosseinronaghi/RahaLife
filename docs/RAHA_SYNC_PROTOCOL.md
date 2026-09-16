# Raha Sync Protocol v2

Raha Sync v2 is the incremental record-sync contract used by Raha Life v0.7.x. It is deliberately separate from encrypted backup. A normal sync never uploads or replaces the whole SQLite database.

## Core rules

Every syncable record has a stable identity and revision metadata:

- `entityType`
- `entityId` (stable UUID in normal domain models)
- `version`
- `deviceId`
- `updatedAtUtc`
- `deletedAtUtc` for tombstones
- `changeId` for one durable local delta
- `operation`: `upsert` or `delete`
- `payload`

Local edits are first committed to Drift and appended to `sync_changes`. Only those pending changes are pushed. Pull uses a server cursor so a device requests only changes it has not processed.

## One live record-sync target

Raha Life v0.7 keeps one active live record-sync target at a time. Users may still configure multiple independent backup targets.

When the user intentionally switches the live sync server/API, the durable local change history is requeued. Protocol-v2 `changeId` values make retries idempotent on a server that has already seen them, while an unseen server can be seeded without replacing a database snapshot.

## Authentication

The personal reference server uses:

```http
Authorization: Bearer <personal-api-token>
```

This is personal/self-hosted authentication, not a central multi-user Raha account service. Multi-user friends/collaboration is a separate future layer.

## Health

```http
GET /health
```

Protocol-v2 servers return `protocolVersion: 2` and advertise backup/record-sync support.

## Pull

```http
GET /v1/sync/pull?deviceId=<uuid>&cursor=<cursor>
```

Example response:

```json
{
  "ok": true,
  "changes": [
    {
      "changeId": "8b9b...",
      "entityType": "shopping_item",
      "entityId": "5a91...",
      "operation": "upsert",
      "version": 4,
      "updatedAtUtc": "2026-08-15T11:00:00.000Z",
      "deviceId": "phone-device-id",
      "deletedAtUtc": null,
      "payload": {
        "id": "5a91...",
        "listId": "list-1",
        "title": "Milk",
        "checked": true
      }
    }
  ],
  "nextCursor": "482",
  "hasMore": false
}
```

The reference server reads cursor rows in order, including rows originally sent by the requesting device, so the cursor cannot become stuck behind the device's own changes. Those own-device changes are filtered from the response body.

Clients pull before pushing. Remote records with strictly newer versions are applied. Same-revision divergent edits from different devices are stored as conflicts rather than silently overwriting either side.

## Push

```http
POST /v1/sync/push
Content-Type: application/json
```

```json
{
  "deviceId": "windows-device-id",
  "changes": [
    {
      "changeId": "local-change-uuid",
      "entityType": "rich_note",
      "entityId": "note-uuid",
      "operation": "upsert",
      "version": 6,
      "updatedAtUtc": "2026-08-15T11:02:00.000Z",
      "deviceId": "windows-device-id",
      "deletedAtUtc": null,
      "payload": {"id": "note-uuid", "title": "Updated"}
    }
  ]
}
```

Response:

```json
{
  "ok": true,
  "accepted": ["local-change-uuid"],
  "conflicts": []
}
```

`accepted` contains exact `changeId` values. Retrying an already committed `changeId` is acknowledged without creating a second server change. Older local deltas discovered after pull are also acknowledged as superseded so they do not retry forever.

## Deletes / tombstones

A user delete does not immediately erase sync history. The local record receives `deletedAtUtc` and a `delete` delta. Other devices receive the tombstone and therefore do not accidentally resurrect an older copy.

Physical tombstone cleanup can be added later with a retention policy once every participating device/provider has safely advanced beyond it.

## Conflicts

A true conflict is a divergent same-entity, same-version edit from different devices. The client stores both envelopes in `sync_conflicts`.

The v0.7 conflict UI supports:

- **Keep local**: keep current local content, create a fresh revision greater than both conflicting versions, and queue it for sync.
- **Use remote**: accept the remote envelope and mark the conflict resolved.

Old conflicting pending deltas are marked superseded so the chosen resolution can converge.

## Backup is separate

Encrypted `.rahabackup` files are recovery snapshots, not the live sync transport. v0.7 backups contain a logical Drift snapshot and, on native platforms, may also include a raw SQLite disaster-recovery copy. Restore is conservative: existing equal revisions are not overwritten; only missing or strictly newer backup revisions are merged.

WebDAV, Nextcloud/ownCloud, S3-compatible storage and SFTP are backup targets in v0.7. A Raha Sync Server or compatible HTTPS API is required for live record-level cursor/push/pull semantics.

## v0.6 server upgrade

Fresh v0.7 server installs already use protocol v2. Existing v0.6 shared-hosting/MySQL installations must back up their database and run:

```text
server/shared-hosting/upgrade_v0.7.sql
```

before enabling v0.7 live record sync.
