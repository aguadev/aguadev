CREATE TABLE  project (
  project_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  project_name varchar(100) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
  status_id int(10) unsigned NOT NULL,
  description varchar(250) DEFAULT NULL,
  build_version enum('NCBI36','NCBI37') NOT NULL DEFAULT 'NCBI37',
  dbsnp_version enum('129','130','131','132') DEFAULT NULL,
  include_NPF enum('y','n') NOT NULL DEFAULT 'n',
  build_location varchar(250) DEFAULT NULL,
  project_policy text,
  project_manager varchar(45) DEFAULT NULL,
  data_analyst varchar(45) DEFAULT NULL,
  PRIMARY KEY (project_id),
  UNIQUE KEY unique_proj_name (project_name),
  KEY status_id (status_id)
)
