CREATE TABLE  status (
  status_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  status varchar(45) NOT NULL,
  description varchar(45) DEFAULT NULL,
  PRIMARY KEY (status_id),
  UNIQUE KEY status_UNIQUE (status)
)
