-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
INSERT INTO `items` (`name`, `label`, `weight`) VALUES
  ('gang_tablet', 'WSMM GANGS', 1),
  ('gang_spray', 'بخاخ WSMM GANGS', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
