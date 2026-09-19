-- Apply once after v0.8, with writes paused and a tested database backup.
ALTER TABLE sync_changes DROP INDEX uq_sync_changes_change_id,
 ADD UNIQUE KEY uq_sync_changes_change_id(owner_id,change_id),
 ADD INDEX idx_owner_cursor(owner_id,cursor_id);
ALTER TABLE direct_messages DROP PRIMARY KEY, ADD PRIMARY KEY(sender_id,id);
