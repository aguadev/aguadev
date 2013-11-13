CREATE TABLE  requeue_report (
  requeue_report_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  date_created date NOT NULL,
  update_timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  lanes_requested int(11) NOT NULL,
  sample_id int(11) NOT NULL,
  status_id varchar(45) NOT NULL DEFAULT '59',
  user_code_and_ip varchar(255) NOT NULL,
  requeue_type varchar(45) DEFAULT NULL,
  comments text,
  current_seen int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (requeue_report_id),
  KEY sample_idx (sample_id),
  KEY status_idx (status_id)
)
