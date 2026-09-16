# Raha Life v0.7 data migration and recovery

## Goal

v0.7 moves primary user-created domain data from legacy SharedPreferences JSON repositories into Drift while preserving installed-user data and making each record independently syncable.

## Preflight recovery

Before opening/migrating the v0.7 database, `SafeUpgradeCoordinator.prepare()` runs once. It:

1. captures known legacy primary-domain SharedPreferences payloads into a recovery JSON preference;
2. creates a safety copy of the existing native SQLite database and any existing WAL/SHM sidecars where available;
3. marks the preflight complete only after those steps finish.

The recovery snapshot is intentionally not deleted immediately after migration.

## Migrated primary domain entities

- Today/home entries
- People
- Rich notes
- Projects
- Medication plans
- Cycle logs
- Inbox items
- Messages
- Sharing grants
- Finance accounts
- Finance transactions
- Shopping lists
- Shopping items (separate child records)

Session/configuration data such as theme, language, AI configuration, device identity, sync connection settings and privacy toggles intentionally remain settings rather than primary domain records.

## Migration journal

`migration_journal` records each completed legacy import. Legacy preference keys are removed only after records are durably written and the journal entry succeeds. Failed conversions leave the old payload intact so the next launch can retry.

## Shopping granularity

Shopping is deliberately split into `shopping_list` and `shopping_item` entity documents. Checking one item therefore creates an item-level delta rather than re-uploading every item in the list.

## Update acceptance

Source-level migration safety is implemented in v0.7. Actual platform upgrade acceptance still requires CI build/install tests. Android production in-place updates additionally require the same persistent release signing key across versions; see `ANDROID_RELEASE_SIGNING.md`.
