CREATE TABLE IF NOT EXISTS queuesample
(
    username       	VARCHAR(30) NOT NULL,
    project        	VARCHAR(40) NOT NULL,
    workflow       	VARCHAR(40) NOT NULL,
	workflownumber	INT(8) NOT NULL,
    sample         	VARCHAR(40) NOT NULL,
	status			VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username, project, workflow, workflownumber, sample)
);
