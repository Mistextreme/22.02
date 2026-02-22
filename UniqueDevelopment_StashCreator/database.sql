CREATE TABLE IF NOT EXISTS `unique_stashes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash_id` VARCHAR(50) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `slots` INT DEFAULT 100,
    `weight` INT DEFAULT 30000,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `size_x` FLOAT DEFAULT 0.6,
    `size_y` FLOAT DEFAULT 1.9,
    `size_z` FLOAT DEFAULT 2.0,
    `rotation` FLOAT DEFAULT 0.0,
    `code` VARCHAR(50) NOT NULL,
    `debug` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);