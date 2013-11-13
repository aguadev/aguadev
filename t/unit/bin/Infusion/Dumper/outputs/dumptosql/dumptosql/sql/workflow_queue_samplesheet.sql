CREATE TABLE  'workflow_queue_samplesheet' (
  'workflow_samplesheet_id' int(10) unsigned NOT NULL AUTO_INCREMENT,
  'workflow_queue_id' int(10) unsigned NOT NULL,
  'flowcell_samplesheet_id' int(11) NOT NULL,
  PRIMARY KEY ('workflow_samplesheet_id'),
  UNIQUE KEY 'un_fbq_ss' ('workflow_queue_id','flowcell_samplesheet_id'),
  KEY 'fk_workflow_queue_idx' ('workflow_queue_id'),
  CONSTRAINT 'fk_workflow_queue' FOREIGN KEY ('workflow_queue_id') REFERENCES 'workflow_queue' ('workflow_queue_id') ON DELETE CASCADE ON UPDATE NO ACTION
)
