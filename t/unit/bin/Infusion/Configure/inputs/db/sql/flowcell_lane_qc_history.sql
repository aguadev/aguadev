CREATE TABLE  flowcell_lane_qc_history (
  flowcell_lane_qc_history_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  flowcell_lane_qc_id int(10) unsigned NOT NULL,
  flowcell_id int(10) unsigned NOT NULL,
  lane int(2) NOT NULL,
  comments text,
  status_id int(10) unsigned NOT NULL,
  archive_status_id int(10) DEFAULT NULL,
  archive_file_name varchar(255) DEFAULT NULL,
  date_created timestamp NULL DEFAULT NULL,
  user_and_ip varchar(200) NOT NULL,
  PRIMARY KEY (flowcell_lane_qc_history_id),
  KEY flowcell_id (flowcell_id,lane)
)
