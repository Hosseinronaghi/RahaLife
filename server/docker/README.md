# Raha Sync Server — Docker Edition

For a VPS, NAS or home server with Docker:

```bash
cp .env.example .env
# edit .env and set strong passwords/token
docker compose up -d --build
```

Put a TLS reverse proxy (Caddy, Nginx, Traefik, NAS proxy) in front of port 8080 before exposing the service to the internet. In Raha Life, add a **Raha Sync Server** connection using the public HTTPS URL and `RAHA_API_TOKEN`.

`RAHA_KEEP_BACKUP_VERSIONS` controls the number of timestamped encrypted backup archives retained by the server (default 7), in addition to `latest.rahabackup`.

## Raha Life v0.7

The bundled server implements sync protocol 2: cursor-based incremental pull, exact `changeId` acknowledgements for idempotent push retries, tombstones and explicit conflict reporting. A new Docker deployment creates the current schema automatically.

If you are reusing a MySQL data volume created by the v0.6 image, back it up and apply `server/shared-hosting/upgrade_v0.7.sql` once before using v0.7 clients. The client sends only record changes after the initial seed; encrypted backup snapshots remain a separate recovery channel.
