CREATE TABLE IF NOT EXISTS stage (

    owner               VARCHAR(30) NOT NULL,
    package             VARCHAR(40) NOT NULL,
    version             VARCHAR(40) NOT NULL,
    installdir          VARCHAR(255) NOT NULL,

    username            VARCHAR(30) NOT NULL,
    project             VARCHAR(20) NOT NULL,
    workflow            VARCHAR(20) NOT NULL,
    workflownumber      INT(12),
    
    name                VARCHAR(40) NOT NULL default '',    
    number              INT(12),
    type                VARCHAR(40),

    location            VARCHAR(255) NOT NULL default '',
    executor            VARCHAR(40) NOT NULL default '',
    cluster             VARCHAR(20)NOT NULL default '',
    submit              INT(1),

    stderrfile          varchar(255) default NULL,
    stdoutfile          varchar(255) default NULL,

    queued              DATETIME DEFAULT NULL,
    started             DATETIME DEFAULT NULL,
    completed           DATETIME DEFAULT NULL,
    workflowpid         INT(12) DEFAULT NULL,
    stagepid            INT(12) DEFAULT NULL,
    stagejobid          INT(12) DEFAULT NULL,
    status              VARCHAR(20),
    
    description         TEXT,
    notes               TEXT,
    
    PRIMARY KEY  (username, project, workflow, workflownumber, number)
);