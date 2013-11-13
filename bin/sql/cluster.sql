CREATE TABLE IF NOT EXISTS cluster
(
    username        VARCHAR(30) NOT NULL,
    cluster         VARCHAR(30) NOT NULL,
    minnodes        INT(12),
    maxnodes        INT(12),
    instancetype    VARCHAR(20),
    amiid           VARCHAR(20),
    availzone       VARCHAR(20),
    description     TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY (username, cluster)
);