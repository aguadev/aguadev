CREATE TABLE  'comment' (
  'comment_id' int(10) unsigned NOT NULL,
  'source_table' varchar(45) NOT NULL,
  'source_table_id' int(11) NOT NULL,
  'comment_content' text,
  'date_inserted' timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ('comment_id')
)
