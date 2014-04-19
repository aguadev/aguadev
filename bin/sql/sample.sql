CREATE TABLE IF NOT EXISTS sample (
    username        VARCHAR(30) NOT NULL,    
    sample        	VARCHAR(40) NOT NULL,
	project			VARCHAR(30) NOT NULL,    
	workflow		VARCHAR(30) NOT NULL,    
	workflownumber	VARCHAR(30) NOT NULL,
	workflowversion	VARCHAR(255) NOT NULL,
	stage			VARCHAR(30) NOT NULL,
	stagenumber		VARCHAR(30) NOT NULL,
    status      	VARCHAR(255) NOT NULL,
    server			VARCHAR(255) NOT NULL,
	serverid		VARCHAR(255) NOT NULL,
    datetime        DATETIME NOT NULL,
    notes           TEXT,
    
    PRIMARY KEY  (username, sample, project, workflow, workflownumber, workflowversion)
);
