CREATE TABLE IF NOT EXISTS `player_pets` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `pet_key` VARCHAR(50) NOT NULL,
  `pet_model` VARCHAR(60) NOT NULL,
  `pet_name` VARCHAR(60) NOT NULL,
  `hunger` INT DEFAULT 100,
  `thirst` INT DEFAULT 100,
  `health` INT DEFAULT 100,
  `out_state` TINYINT(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_cid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
