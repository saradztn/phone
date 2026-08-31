-- ============================================================================
-- AURA Phone - database schema (MySQL / MariaDB)
-- The resource ALSO auto-creates these tables on start (IF NOT EXISTS),
-- so importing this file is optional but recommended for full control.
-- Default table prefix: phone_  (change in shared/config.lua -> database.prefix)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `phone_numbers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` VARCHAR(64) NOT NULL,
    `phone_number` VARCHAR(16) NOT NULL,
    `display_name` VARCHAR(32) NOT NULL DEFAULT '',
    `created_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_account` (`account_id`),
    UNIQUE KEY `uniq_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_contacts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `contact_number` VARCHAR(16) NOT NULL,
    `contact_name` VARCHAR(32) NOT NULL,
    `favorite` TINYINT NOT NULL DEFAULT 0,
    `created_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_owner_contact` (`owner_id`, `contact_number`),
    KEY `idx_owner` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sender_number` VARCHAR(16) NOT NULL,
    `receiver_number` VARCHAR(16) NOT NULL,
    `message` VARCHAR(512) NOT NULL,
    `timestamp` INT UNSIGNED NOT NULL,
    `is_read` TINYINT NOT NULL DEFAULT 0,
    `read_at` INT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_receiver` (`receiver_number`, `is_read`),
    KEY `idx_pair` (`sender_number`, `receiver_number`, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_calls` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `caller_number` VARCHAR(16) NOT NULL,
    `receiver_number` VARCHAR(16) NOT NULL,
    `duration` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` VARCHAR(12) NOT NULL DEFAULT 'ENDED',
    `timestamp` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_parties` (`caller_number`, `receiver_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_notifications` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `app` VARCHAR(24) NOT NULL,
    `title` VARCHAR(64) NOT NULL,
    `body` VARCHAR(160) NOT NULL,
    `timestamp` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_id`, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_notes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `title` VARCHAR(48) NOT NULL,
    `body` VARCHAR(2048) NOT NULL,
    `created_at` INT UNSIGNED NOT NULL,
    `updated_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_id`, `updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_settings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `skey` VARCHAR(32) NOT NULL,
    `svalue` VARCHAR(128) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_owner_key` (`owner_id`, `skey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_apps` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `app_id` VARCHAR(24) NOT NULL,
    `installed` TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_owner_app` (`owner_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_bank_tx` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `from_number` VARCHAR(16) NOT NULL,
    `to_number` VARCHAR(16) NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `timestamp` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_pair` (`from_number`, `to_number`, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_bank_pending` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `to_number` VARCHAR(16) NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `timestamp` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_vehicles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `model` VARCHAR(64) NOT NULL DEFAULT '',
    `vehicle` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_x` FLOAT NOT NULL DEFAULT 0,
    `last_y` FLOAT NOT NULL DEFAULT 0,
    `last_z` FLOAT NOT NULL DEFAULT 0,
    `locked` TINYINT NOT NULL DEFAULT 0,
    `engine` TINYINT NOT NULL DEFAULT 0,
    `updated_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_id`),
    KEY `idx_vehicle` (`vehicle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `phone_properties` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_id` VARCHAR(64) NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `ptype` VARCHAR(32) NOT NULL DEFAULT 'House',
    `x` FLOAT NOT NULL DEFAULT 0,
    `y` FLOAT NOT NULL DEFAULT 0,
    `z` FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
