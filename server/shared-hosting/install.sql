CREATE TABLE IF NOT EXISTS sync_entities (
    owner_id VARCHAR(64) NOT NULL DEFAULT 'personal',
    entity_type VARCHAR(120) NOT NULL,
    entity_id VARCHAR(120) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    version INT NOT NULL,
    updated_at_utc VARCHAR(40) NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    deleted_at_utc VARCHAR(40) NULL,
    payload_json LONGTEXT NOT NULL,
    clock_json LONGTEXT NOT NULL,
    PRIMARY KEY (owner_id, entity_type, entity_id),
    KEY idx_sync_entities_updated (updated_at_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_changes (
    owner_id VARCHAR(64) NOT NULL DEFAULT 'personal',
    cursor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    change_id VARCHAR(160) NOT NULL,
    entity_type VARCHAR(120) NOT NULL,
    entity_id VARCHAR(120) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    version INT NOT NULL,
    updated_at_utc VARCHAR(40) NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    deleted_at_utc VARCHAR(40) NULL,
    payload_json LONGTEXT NOT NULL,
    clock_json LONGTEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cursor_id),
    UNIQUE KEY uq_sync_changes_change_id (change_id),
    KEY idx_sync_changes_device_cursor (device_id, cursor_id),
    KEY idx_sync_changes_entity (entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS raha_users(id VARCHAR(64) PRIMARY KEY,username VARCHAR(64) UNIQUE NOT NULL,password_hash VARCHAR(255) NOT NULL) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS raha_sessions(token_hash CHAR(64) PRIMARY KEY,account_id VARCHAR(64) NOT NULL,expires_at DATETIME NOT NULL,FOREIGN KEY(account_id) REFERENCES raha_users(id)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS auth_attempts(id BIGINT AUTO_INCREMENT PRIMARY KEY,attempt_key CHAR(64) NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,KEY attempts_lookup(attempt_key,created_at)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS connections(low_id VARCHAR(64) NOT NULL,high_id VARCHAR(64) NOT NULL,requested_by VARCHAR(64) NOT NULL,status VARCHAR(16) NOT NULL,PRIMARY KEY(low_id,high_id)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS direct_messages(id VARCHAR(64) PRIMARY KEY,sender_id VARCHAR(64) NOT NULL,recipient_id VARCHAR(64) NOT NULL,body TEXT NOT NULL,created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),KEY conversation(sender_id,recipient_id,created_at)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS shared_records(id VARCHAR(64) PRIMARY KEY,owner_id VARCHAR(64) NOT NULL,recipient_id VARCHAR(64) NOT NULL,permission VARCHAR(8) NOT NULL,payload_json LONGTEXT NOT NULL,version INT NOT NULL,KEY recipient(recipient_id)) ENGINE=InnoDB;
