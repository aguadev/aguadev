CREATE TABLE IF NOT EXISTS clustervars
(
    username        VARCHAR(30) NOT NULL,
    cluster         VARCHAR(80) NOT NULL,
    qmasterport     INT(12),
    execdport       INT(12),
    root            VARCHAR(60) NOT NULL,
    cell            VARCHAR(60) NOT NULL,
    
    PRIMARY KEY (username, cluster)
);