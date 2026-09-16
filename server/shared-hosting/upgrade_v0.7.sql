-- Raha Sync protocol v2 upgrade for servers created by Raha Life v0.6.x.
-- Run this once before using the v0.7 clients. Fresh installations already
-- contain this column through install.sql.
ALTER TABLE sync_changes
  ADD COLUMN change_id VARCHAR(160) NULL AFTER cursor_id;

UPDATE sync_changes
SET change_id = CONCAT('legacy-server-', cursor_id)
WHERE change_id IS NULL OR change_id = '';

ALTER TABLE sync_changes
  MODIFY change_id VARCHAR(160) NOT NULL,
  ADD UNIQUE KEY uq_sync_changes_change_id (change_id);
