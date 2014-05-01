CREATE TABLE IF NOT EXISTS provenance
(
    username       	VARCHAR(30) NOT NULL,
    project        	VARCHAR(40) NOT NULL,
    workflow       	VARCHAR(40) NOT NULL,
	workflownumber	INT(6) NOT NULL,
    sample         	VARCHAR(40) NOT NULL,

	stage			VARCHAR(40) NOT NULL,
	stagenumber		INT(6) NOT NULL,
	
	application		VARCHAR(40) NOT NULL,
	owner			VARCHAR(40) NOT NULL,
    package         VARCHAR(40) NOT NULL,
    version         VARCHAR(40) NOT NULL,
	installdir		VARCHAR(255) NOT NULL,

	host			VARCHAR(40) NOT NULL,
	started			datetime,
	completed		datetime,
	duration		INT(12),
	status			VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username, project, workflow, workflownumber, sample, stage, stagenumber, application)
);
