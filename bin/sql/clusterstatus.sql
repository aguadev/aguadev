CREATE TABLE IF NOT EXISTS clusterstatus
(
    username        VARCHAR(30) NOT NULL,
    cluster         VARCHAR(30) NOT NULL,
    minnodes        INT(12),
    maxnodes        INT(12),
    status          VARCHAR(30),
    pid             INT(12),
    started         DATETIME NOT NULL,
    stopped         DATETIME NOT NULL,
    termination     DATETIME NOT NULL,
    polled          DATETIME NOT NULL,
    hours           INT(12),
    
    PRIMARY KEY (username, cluster)
);