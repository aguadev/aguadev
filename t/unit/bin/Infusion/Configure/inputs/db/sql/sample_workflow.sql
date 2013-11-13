CREATE TABLE  sample_workflow (
  sample_workflow_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  sample_id int(11) unsigned NOT NULL,
  workflow_id int(11) unsigned NOT NULL,
  PRIMARY KEY (sample_workflow_id),
  UNIQUE KEY sample_workflow_id_UNIQUE (sample_workflow_id)
)
