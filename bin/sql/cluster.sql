CREATE TABLE IF NOT EXISTS cluster
(
    username        VARCHAR(40) NOT NULL,
    cluster         VARCHAR(80) NOT NULL,
    minnodes        INT(12),
    maxnodes        INT(12),
    instancetype    VARCHAR(40),
	
    amiid           VARCHAR(40),
    availzone       VARCHAR(40),
    description     TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY (username, cluster)
);