CREATE TABLE  workflow_queue (
  workflow_queue_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  workflow_id varchar(100) NOT NULL,
  workflow_config text,
  working_server varchar(250) NOT NULL,
  working_dir varchar(250) NOT NULL,
  set_date datetime NOT NULL,
  status_id int(11) NOT NULL,
  last_update timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  sge_priority int(11) NOT NULL DEFAULT '0',
  sge_job_id int(11) DEFAULT NULL,
  comments text,
  PRIMARY KEY (workflow_queue_id)
)
