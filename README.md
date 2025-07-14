CREATE TABLE IF NOT EXISTS `player_blips` (
  `citizenid` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `sprite` int(11) DEFAULT NULL,
  `color` int(11) DEFAULT NULL,
  PRIMARY KEY (`citizenid`,`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;