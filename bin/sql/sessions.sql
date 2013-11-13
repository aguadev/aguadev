CREATE TABLE IF NOT EXISTS sessions
(
    username        VARCHAR(30) NOT NULL,
    sessionid         VARCHAR(255),
    datetime          DATETIME NOT NULL,
    
    PRIMARY KEY (username, sessionid)
)
    