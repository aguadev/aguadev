CREATE TABLE  requeue_report_samplesheet (
  requeue_report_samplesheet_id int(11) NOT NULL AUTO_INCREMENT,
  requeue_report_id int(11) NOT NULL,
  flowcell_samplesheet_id int(11) NOT NULL,
  PRIMARY KEY (requeue_report_samplesheet_id),
  UNIQUE KEY un_ss_rq (requeue_report_id,flowcell_samplesheet_id)
)
