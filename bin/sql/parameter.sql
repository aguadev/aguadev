CREATE TABLE IF NOT EXISTS parameter
(
    owner           VARCHAR(30) NOT NULL,
    username        VARCHAR(30) NOT NULL,
    package         VARCHAR(40) NOT NULL,
    version         VARCHAR(40) NOT NULL,
    installdir      VARCHAR(255) NOT NULL,    

    appname         VARCHAR(40) NOT NULL,
    apptype         VARCHAR(40),    
    name            VARCHAR(40) NOT NULL,

    ordinal         INT(6) NOT NULL default 0,
    locked          INT(1) NOT NULL default 0,
    paramtype       VARCHAR(40) NOT NULL default '',  
    category        VARCHAR(40) NOT NULL default '',  
    valuetype       VARCHAR(20) NOT NULL default '',  
    argument        VARCHAR(40) NOT NULL default '',  
    value           TEXT,
    discretion      VARCHAR(10) NOT NULL default '',
    format          VARCHAR(40),                      
    description     TEXT, 
    args            TEXT,
    inputParams     TEXT,
    paramFunction   TEXT,

    PRIMARY KEY  (owner, appname, name, paramtype, ordinal)
);
