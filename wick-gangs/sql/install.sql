-- Optional: run this if you do not want auto-create on resource start.
-- wick-gangs creates the same tables itself.

CREATE TABLE IF NOT EXISTS wick_gangs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(32) NOT NULL UNIQUE,
    label VARCHAR(64) NOT NULL,
    tag VARCHAR(8) NOT NULL DEFAULT '',
    color VARCHAR(16) NOT NULL DEFAULT 'red',
    icon VARCHAR(16) NOT NULL DEFAULT 'gang',
    pending_icon VARCHAR(16) NULL,
    points INT NOT NULL DEFAULT 0,
    spray_count INT NOT NULL DEFAULT 0,
    leader VARCHAR(80) NULL,
    hq_x DOUBLE NULL,
    hq_y DOUBLE NULL,
    hq_z DOUBLE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wick_gang_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gang_id INT NOT NULL,
    identifier VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL DEFAULT '',
    rank INT NOT NULL DEFAULT 1,
    is_guest TINYINT NOT NULL DEFAULT 0,
    guest_until INT NOT NULL DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX gang_idx (gang_id)
);

CREATE TABLE IF NOT EXISTS wick_gang_sprays (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gang_id INT NOT NULL,
    identifier VARCHAR(80) NOT NULL,
    player_name VARCHAR(80) NOT NULL DEFAULT '',
    mode VARCHAR(12) NOT NULL DEFAULT 'freehand',
    text_content VARCHAR(40) NULL,
    strokes LONGTEXT NULL,
    x DOUBLE NOT NULL,
    y DOUBLE NOT NULL,
    z DOUBLE NOT NULL,
    heading DOUBLE NOT NULL DEFAULT 0,
    zone_id VARCHAR(32) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX gang_idx (gang_id)
);

CREATE TABLE IF NOT EXISTS wick_gang_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gang_id INT NOT NULL,
    type VARCHAR(24) NOT NULL DEFAULT 'info',
    title VARCHAR(80) NOT NULL DEFAULT '',
    message VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX gang_idx (gang_id)
);

CREATE TABLE IF NOT EXISTS wick_gang_activity (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gang_id INT NULL,
    actor VARCHAR(80) NOT NULL DEFAULT '',
    actor_name VARCHAR(80) NOT NULL DEFAULT '',
    action VARCHAR(32) NOT NULL DEFAULT 'info',
    detail VARCHAR(180) NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX gang_idx (gang_id)
);

CREATE TABLE IF NOT EXISTS wick_gang_zone_state (
    zone_id VARCHAR(32) PRIMARY KEY,
    owner_gang_id INT NULL,
    scores TEXT NULL
);
