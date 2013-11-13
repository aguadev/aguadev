CREATE TABLE  harddisk_sample (
  harddisk_sample_id int(11) NOT NULL AUTO_INCREMENT,
  harddisk_id int(10) NOT NULL,
  sample_id int(10) NOT NULL,
  status_id int(10) NOT NULL,
  deliverable_size_Gb int(11) NOT NULL,
  PRIMARY KEY (harddisk_sample_id)
)
