CREATE TABLE  requeue_report_history (
  requeue_report_history_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  requeue_report_id int(10) unsigned NOT NULL,
  date_created date NOT NULL,
  update_timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lanes_requested int(11) NOT NULL,
  sample_id int(11) NOT NULL,
  status_id varchar(45) NOT NULL,
  user_code_and_ip varchar(255) NOT NULL,
  requeue_type varchar(45) DEFAULT NULL,
  comments text,
  current_seen int(11) DEFAULT NULL,
  PRIMARY KEY (requeue_report_history_id)
)
