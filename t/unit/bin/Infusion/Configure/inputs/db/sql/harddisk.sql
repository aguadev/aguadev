CREATE TABLE  harddisk (
  harddisk_id int(10) NOT NULL AUTO_INCREMENT,
  serial_number varchar(100) NOT NULL,
  drive_label varchar(45) NOT NULL,
  mount_point varchar(245) NOT NULL,
  max_usable_size_GB int(11) NOT NULL,
  diskloader_hostname varchar(90) NOT NULL,
  status_id int(10) DEFAULT NULL,
  project_id varchar(45) DEFAULT NULL,
  truecrypt_volume enum('Y','N') DEFAULT 'N',
  filesystem enum('NTFS','ext3') DEFAULT NULL,
  current_available_size_GB int(11) DEFAULT NULL,
  PRIMARY KEY (harddisk_id),
  UNIQUE KEY serial_number_UNIQUE (serial_number)
)
