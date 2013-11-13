CREATE TABLE  flowcell_samplesheet_history (
  flowcell_samplesheet_hist_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  flowcell_samplesheet_id int(10) unsigned NOT NULL,
  flowcell_id int(10) unsigned NOT NULL,
  sample_id int(10) unsigned NOT NULL,
  lane tinyint(1) unsigned NOT NULL,
  ref_sequence varchar(250) NOT NULL,
  control enum('N','Y') NOT NULL,
  status_id int(10) unsigned NOT NULL DEFAULT '0',
  indexval varchar(100) DEFAULT NULL,
  md5sum varchar(45) NOT NULL,
  location varchar(250) NOT NULL,
  date_updated timestamp NULL DEFAULT NULL,
  PRIMARY KEY (flowcell_samplesheet_hist_id)
)
