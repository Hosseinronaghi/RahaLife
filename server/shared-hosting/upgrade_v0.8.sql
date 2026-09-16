ALTER TABLE sync_entities ADD COLUMN clock_json LONGTEXT NULL;
ALTER TABLE sync_changes ADD COLUMN clock_json LONGTEXT NULL;

ALTER TABLE sync_entities ADD COLUMN owner_id VARCHAR(64) NOT NULL DEFAULT 'personal', DROP PRIMARY KEY, ADD PRIMARY KEY(owner_id,entity_type,entity_id);
ALTER TABLE sync_changes ADD COLUMN owner_id VARCHAR(64) NOT NULL DEFAULT 'personal';

CREATE TABLE IF NOT EXISTS raha_users(id VARCHAR(64) PRIMARY KEY,username VARCHAR(64) UNIQUE NOT NULL,password_hash VARCHAR(255) NOT NULL) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS raha_sessions(token_hash CHAR(64) PRIMARY KEY,account_id VARCHAR(64) NOT NULL,expires_at DATETIME NOT NULL,FOREIGN KEY(account_id) REFERENCES raha_users(id)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS auth_attempts(id BIGINT AUTO_INCREMENT PRIMARY KEY,attempt_key CHAR(64) NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,KEY attempts_lookup(attempt_key,created_at)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS connections(low_id VARCHAR(64) NOT NULL,high_id VARCHAR(64) NOT NULL,requested_by VARCHAR(64) NOT NULL,status VARCHAR(16) NOT NULL,PRIMARY KEY(low_id,high_id)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS direct_messages(id VARCHAR(64) PRIMARY KEY,sender_id VARCHAR(64) NOT NULL,recipient_id VARCHAR(64) NOT NULL,body TEXT NOT NULL,created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),KEY conversation(sender_id,recipient_id,created_at)) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS shared_records(id VARCHAR(64) PRIMARY KEY,owner_id VARCHAR(64) NOT NULL,recipient_id VARCHAR(64) NOT NULL,permission VARCHAR(8) NOT NULL,payload_json LONGTEXT NOT NULL,version INT NOT NULL,KEY recipient(recipient_id)) ENGINE=InnoDB;
