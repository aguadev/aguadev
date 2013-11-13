CREATE TABLE  workflow (
  workflow_id int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '		',
  workflow_name varchar(200) NOT NULL,
  workflow_version varchar(200) NOT NULL,
  create_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  driver_location text NOT NULL,
  sge_min_parameters text NOT NULL,
  PRIMARY KEY (workflow_id),
  UNIQUE KEY un_name_version (workflow_name,workflow_version)
)
