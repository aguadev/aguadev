CREATE TABLE samplefile
(
    username       	VARCHAR(30) NOT NULL,
    project        	VARCHAR(40) NOT NULL,
    workflow       	VARCHAR(40) NOT NULL,
	workflownumber	INT(8) NOT NULL,
    sample         	VARCHAR(40) NOT NULL,
	filename		VARCHAR(40) NOT NULL,	
	filesize		INT(40) NOT NULL,	
    
    PRIMARY KEY  (username, project, workflow, workflownumber, sample, filename, filesize)
);
