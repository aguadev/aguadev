CREATE TABLE  flowcell_lane_qc (
  flowcell_lane_qc_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  flowcell_id int(10) unsigned NOT NULL,
  lane int(2) NOT NULL,
  comments text,
  status_id int(10) unsigned NOT NULL DEFAULT '0',
  date_created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  user_and_ip varchar(200) NOT NULL,
  archive_status_id int(10) DEFAULT NULL,
  archive_file_name varchar(255) DEFAULT NULL,
  fingerprint_status_id int(10) DEFAULT NULL,
  PRIMARY KEY (flowcell_lane_qc_id),
  UNIQUE KEY fc_id_lane (flowcell_id,lane),
  UNIQUE KEY archive_file_name_UNIQUE (archive_file_name),
  KEY fc_id (flowcell_id),
  KEY lane_idx (lane),
  KEY status_id (status_id),
  KEY archive_status_id (archive_status_id)
)
