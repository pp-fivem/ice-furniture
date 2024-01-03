CREATE TABLE IF NOT EXISTS `player_furnitures` (
  `identifier` varchar(100) NOT NULL,
  `object` varchar(100) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`,`object`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `furniture_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location` varchar(50) NOT NULL DEFAULT '',
  `pos` longtext DEFAULT NULL,
  `rotation` longtext DEFAULT NULL,
  `model` varchar(50) DEFAULT '',
  `uniqueId` VARCHAR(30) DEFAULT '',
  PRIMARY KEY (`id`) USING BTREE COMMENT 'Node'
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;