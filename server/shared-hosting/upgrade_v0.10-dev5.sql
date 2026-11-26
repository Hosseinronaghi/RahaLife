-- Optional on databases created before dev.5. Run once after taking a backup.
CREATE INDEX idx_sync_owner_cursor ON sync_changes(owner_id, cursor_id);
