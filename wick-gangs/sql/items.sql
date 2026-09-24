INSERT INTO `items` (`name`, `label`, `weight`) VALUES
  ('gang_tablet', 'تابلت العصابة', 1),
  ('gang_spray', 'بخاخ عصابة', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
