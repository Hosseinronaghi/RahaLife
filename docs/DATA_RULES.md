# Critical data rules

- Store canonical timestamps in UTC and retain the user's timezone identifier where recurrence depends on local time.
- Persian and Gregorian calendars are display/input systems; database dates remain canonical ISO timestamps.
- Store money as integer minor units, never floating point.
- Use UUIDs for syncable entities.
- Soft-delete syncable entities with `deletedAt` tombstones.
- Every syncable entity has `updatedAt` and a monotonic local version.
- Medication logs distinguish taken-on-time, taken-late, skipped, missed and postponed.
- AI never writes directly to SQLite; validated application use cases perform writes.
