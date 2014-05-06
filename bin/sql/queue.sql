CREATE TABLE IF NOT EXISTS queue
(
    username       	VARCHAR(30) NOT NULL,
    project        	VARCHAR(40) NOT NULL,
    workflow       	VARCHAR(40) NOT NULL,
	workflownumber	INT(8) NOT NULL,
 
    PRIMARY KEY  (username, project, workflow, workflownumber)
);
