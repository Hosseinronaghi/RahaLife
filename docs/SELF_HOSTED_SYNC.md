# Self-hosted Raha Sync

Raha Life can use infrastructure owned by the user instead of a Raha-operated server.

## Supported connection styles in v0.6

| Target | Backup | Restore | Record sync contract | Typical use |
|---|---:|---:|---:|---|
| WebDAV | Yes | Yes | No | NAS/hosting/cloud drive |
| Nextcloud / ownCloud | Yes | Yes | No | personal cloud |
| S3-compatible / MinIO | Yes | Yes | No | object storage/NAS |
| SFTP | Yes (native) | Yes (native) | No | VPS/NAS backup |
| Raha Sync Server | Yes | Yes | API implemented | VPS/NAS/shared hosting |
| Custom HTTPS API | Yes | Yes | compatible API possible | custom gateway |

## Shared hosting

Use `server/shared-hosting`. Import `install.sql`, create `config.local.php` from the example, keep the storage directory outside the public web root where possible, use a long random API token, and expose only HTTPS.

## Docker / NAS / VPS

Use `server/docker`. Copy `.env.example` to `.env`, set long random database passwords and API token, then run Docker Compose. Put a TLS reverse proxy in front of the HTTP port before exposing it to the internet.

## Trusted LAN HTTP

The app requires HTTPS for HTTP-based targets by default. A per-connection override allows plain HTTP only when the user explicitly chooses it for a trusted local network. It should not be used over the public internet.

## Credentials

Provider secrets are stored separately in secure storage. Normal connection settings contain non-secret metadata such as endpoint, bucket, folder, host and port.

## Direct SQL is intentionally unsupported

Do not expose MySQL/PostgreSQL credentials or ports to Raha Life clients. Shared-hosting or self-hosted database access must sit behind the HTTPS Raha Sync API.

## Backup retention

Generic WebDAV, Nextcloud, S3-compatible and SFTP targets keep a single remote `latest.rahabackup` snapshot in v0.6 so automatic backups cannot grow remote storage without a bound. Manual exports remain timestamped. Raha Sync Server keeps timestamped archives and prunes them to the configured `keep_backup_versions` / `RAHA_KEEP_BACKUP_VERSIONS` value (default: 7), while also keeping `latest.rahabackup`.
