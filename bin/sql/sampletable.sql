CREATE TABLE IF NOT EXISTS sampletable (
    username        VARCHAR(30) NOT NULL,    
	project			VARCHAR(30) NOT NULL,    
    sampletable     VARCHAR(40) NOT NULL,
    
    PRIMARY KEY  (username, project, sampletable)
);
