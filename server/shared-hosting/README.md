# Raha server — protocol 3 / app 0.8

Requirements: PHP 8.3 (validated parser/runtime), PDO MySQL, MySQL 8, HTTPS. MariaDB compatibility has not been exercised here. Keep configuration and writable storage outside the public web root; expose only `public/`.

## Fresh installation

1. Import `install.sql` into an empty database.
2. Copy `config.example.php` to `config.local.php`; set database credentials, a strong legacy personal API token, a private `registration_code`, and your permitted web app `cors_origin`.
3. Deploy `public/` as web root with clean-route rewriting; keep its sibling configuration and storage private.
4. In the app Connections page enter the HTTPS base URL and register using the invitation code. Login uses an expiring account token. Enable account record sync explicitly in the UI.
5. The personal API-token mode remains a separate owner scope called `personal`; creating an account does not automatically move existing personal data into that account.

Backups are encrypted by the client. Record sync and messages are not end-to-end encrypted. Configure TLS and server access accordingly.

## Upgrade an existing server

Back up the database and storage and stop writes first. For a v0.6 database, apply `upgrade_v0.7.sql` once, then `upgrade_v0.8.sql` once. For v0.7, apply only `upgrade_v0.8.sql` once. Do not re-import install.sql. The ALTER statements are not idempotent: inspect the schema if an upgrade is interrupted; do not blindly rerun it. Deploy the matching PHP files together and test protocol 3 before enabling clients.

`/health` confirms protocol and database connectivity, not a full schema or authorization audit. Run the HTTP integration checks against the upgraded disposable environment before production use.

## Checks

```bash
php -l public/index.php
php -l public/accounts.php
php -l public/protocol.php
php ../tests/protocol_test.php
```

`.github/workflows/server-ci.yml` configures MySQL and the HTTP smoke suite. Account isolation, retry ACKs, causal conflicts, friendship permissions, sharing CAS, block revocation and logout are covered by that prepared integration suite. It has not been executed against a real MySQL service in this delivery environment.

The account layer provides registration, login/logout, friends, messages and independent shared-record snapshots. Password reset, session refresh, delivery notifications and offline message outbox are follow-up work.
